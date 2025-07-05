import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pro/cubit/startTrip/start_trip_cubit.dart';
import 'package:pro/cubit/startTrip/start_trip.state.dart';
import 'package:pro/cubit/updateLocation/updatelocation_cubit.dart';
import 'package:pro/cubit/updateLocation/updateLocation_state.dart';
import 'package:pro/cubit/end-trip/end_trip_cubit.dart';
import 'package:pro/cubit/end-trip/end_trip_state.dart';
import 'package:pro/services/signalr_service.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';

class AppTimerService {
  static final AppTimerService _instance = AppTimerService._internal();
  factory AppTimerService() => _instance;
  AppTimerService._internal();

  // Separate timers for kid and traveler
  Timer? _kidTimer;
  Timer? _travelerTimer;

  // Location update timers
  Timer? _kidLocationTimer;
  Timer? _travelerLocationTimer;

  // Kid timer state
  int _kidSeconds = 0;
  bool _kidIsRunning = false;

  // Traveler timer state
  int _travelerSeconds = 0;
  bool _travelerIsRunning = false;

  // Trip tracking state
  String? _kidTripId;
  String? _travelerTripId;

  // Cubit instances (will be injected)
  StartTripCubit? _startTripCubit;
  UpdateLocationCubit? _updateLocationCubit;
  EndTripCubit? _endTripCubit;
  SignalRService? _signalRService;

  // Callbacks for UI updates - separated by type
  final List<Function(int seconds, bool isRunning, String formattedTime)>
      _kidListeners = [];
  final List<Function(int seconds, bool isRunning, String formattedTime)>
      _travelerListeners = [];

  // Callbacks for dialog triggers - separated by type
  final List<Function()> _kidDialogListeners = [];
  final List<Function()> _travelerDialogListeners = [];

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the service
  Future<void> initialize() async {
    await _initializeNotifications();
    log("🕐 App Timer Service initialized");
  }

  // Initialize tracking dependencies
  void initializeTracking({
    required StartTripCubit startTripCubit,
    required UpdateLocationCubit updateLocationCubit,
    required EndTripCubit endTripCubit,
    required SignalRService signalRService,
  }) {
    _startTripCubit = startTripCubit;
    _updateLocationCubit = updateLocationCubit;
    _endTripCubit = endTripCubit;
    _signalRService = signalRService;
    log("🕐 Tracking dependencies initialized");
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log("Location services are disabled");
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log("Location permissions are denied");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log("Location permissions are permanently denied");
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      log("Current location: ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      log("Error getting current location: $e");
      return null;
    }
  }

  // Start trip tracking
  Future<String?> _startTrip() async {
    if (_startTripCubit == null) {
      log("StartTripCubit not initialized");
      return null;
    }

    try {
      log("🚗 Starting trip tracking...");
      
      // Use enhanced connection verification
      log("🔍 Performing enhanced connection verification...");
      final isConnectionVerified = await _signalRService!.ensureServerConnection();
      if (!isConnectionVerified) {
        log("⚠️ Enhanced connection verification failed, but continuing with trip start");
      } else {
        log("✅ Enhanced connection verification successful");
        
        // Log detailed connection info
        final connectionInfo = _signalRService!.getConnectionInfo();
        log("🔍 SignalR Connection Info: $connectionInfo");
      }

      // Get traveler ID for tracking hub
      final travelerId = CacheHelper.getData(key: ApiKey.userId)?.toString();
      
      // Start trip via REST API first to get proper trip ID and data
      await _startTripCubit!.startTrip();
      final state = _startTripCubit!.state;

      if (state is StartTripSuccess) {
        log("✅ Trip started successfully via REST API: ${state.response.tripId}");
        
        // Now notify SignalR about the trip start with proper data
        if (travelerId != null && travelerId.isNotEmpty && _signalRService != null) {
          try {
            // Join tracking group first
            await _signalRService!.joinTravelerTrackingGroup(travelerId);
            
            // Notify SignalR about trip start (this will trigger notification to supporters)
            final signalRSuccess = await _signalRService!.startTripTracking(travelerId);
            if (signalRSuccess) {
              log("✅ SignalR notification sent successfully for trip: ${state.response.tripId}");
            } else {
              log("⚠️ SignalR notification failed, but trip is still active");
            }
          } catch (e) {
            log("⚠️ SignalR notification error: $e, but trip is still active");
          }
        }
        
        return state.response.tripId;
      } else if (state is StartTripError) {
        log("❌ Failed to start trip via REST API: ${state.message}");
        
        // If the error is about SignalR connection, try to connect and retry
        if (state.message.contains("TRAVELER_DISCONNECTED") || 
            state.message.contains("must be connected") ||
            state.message.contains("SignalR connection required")) {
          log("🔄 Attempting to connect SignalR tracking hub and retry trip start...");
          try {
            if (_signalRService != null) {
              // Force reconnect with longer delay
              await _signalRService!.stopConnection();
              await Future.delayed(const Duration(seconds: 3));
              await Future.delayed(const Duration(seconds: 8));
              
              // Use enhanced connection verification
              final retryConnected = await _signalRService!.ensureServerConnection();
              if (retryConnected) {
                log("✅ Enhanced connection verification confirmed, retrying trip start...");
                
                // Log detailed connection info before retry
                final connectionInfo = _signalRService!.getConnectionInfo();
                log("🔍 SignalR Connection Info before retry: $connectionInfo");
                
                // Retry the REST API trip start
                await _startTripCubit!.startTrip();
                final retryState = _startTripCubit!.state;
                
                if (retryState is StartTripSuccess) {
                  log("✅ Trip started successfully via REST API on retry: ${retryState.response.tripId}");
                  
                  // Notify SignalR after successful retry
                  if (travelerId != null && travelerId.isNotEmpty) {
                    try {
                      await _signalRService!.joinTravelerTrackingGroup(travelerId);
                      final signalRRetrySuccess = await _signalRService!.startTripTracking(travelerId);
                      if (signalRRetrySuccess) {
                        log("✅ SignalR notification sent successfully on retry");
                      }
                    } catch (e) {
                      log("⚠️ SignalR notification error on retry: $e");
                    }
                  }
                  
                  return retryState.response.tripId;
                } else if (retryState is StartTripError) {
                  log("❌ Trip start retry failed via REST API: ${retryState.message}");
                  
                  // If still failing, try one more time with even longer delay
                  if (retryState.message.contains("TRAVELER_DISCONNECTED") || 
                      retryState.message.contains("must be connected")) {
                    log("🔄 Final attempt with longer delay...");
                    await Future.delayed(const Duration(seconds: 12));
                    
                    try {
                      await _startTripCubit!.startTrip();
                      final finalState = _startTripCubit!.state;
                      
                      if (finalState is StartTripSuccess) {
                        log("✅ Trip started successfully via REST API on final attempt: ${finalState.response.tripId}");
                        
                        // Notify SignalR after final successful attempt
                        if (travelerId != null && travelerId.isNotEmpty) {
                          try {
                            await _signalRService!.joinTravelerTrackingGroup(travelerId);
                            final signalRFinalSuccess = await _signalRService!.startTripTracking(travelerId);
                            if (signalRFinalSuccess) {
                              log("✅ SignalR notification sent successfully on final attempt");
                            }
                          } catch (e) {
                            log("⚠️ SignalR notification error on final attempt: $e");
                          }
                        }
                        
                        return finalState.response.tripId;
                      } else if (finalState is StartTripError) {
                        log("❌ Final trip start attempt failed via REST API: ${finalState.message}");
                        log("💡 The server may require a specific SignalR method call or connection pattern");
                        log("💡 Consider checking with the backend team about SignalR connection requirements");
                        log("💡 Current SignalR tracking hub connection is working perfectly - this is a server-side issue");
                      }
                    } catch (finalError) {
                      log("❌ Final trip start attempt error: $finalError");
                    }
                  }
                }
              }
            }
          } catch (retryError) {
            log("❌ Trip start retry error: $retryError");
          }
        } else {
          // For other errors, just retry once
          await Future.delayed(const Duration(seconds: 3));
          try {
            log("🔄 Retrying trip start via REST API...");
            await _startTripCubit!.startTrip();
            final retryState = _startTripCubit!.state;
            
            if (retryState is StartTripSuccess) {
              log("✅ Trip started successfully via REST API on retry: ${retryState.response.tripId}");
              
              // Notify SignalR after successful retry
              if (travelerId != null && travelerId.isNotEmpty && _signalRService != null) {
                try {
                  await _signalRService!.joinTravelerTrackingGroup(travelerId);
                  final signalRRetrySuccess = await _signalRService!.startTripTracking(travelerId);
                  if (signalRRetrySuccess) {
                    log("✅ SignalR notification sent successfully on retry");
                  }
                } catch (e) {
                  log("⚠️ SignalR notification error on retry: $e");
                }
              }
              
              return retryState.response.tripId;
            } else if (retryState is StartTripError) {
              log("❌ Trip start retry failed via REST API: ${retryState.message}");
            }
          } catch (retryError) {
            log("❌ Trip start retry error: $retryError");
          }
        }
        return null;
      }
    } catch (e) {
      log("❌ Error starting trip: $e");
    }

    return null;
  }

  // Update location during trip
  Future<void> _updateTripLocation(String tripId) async {
    if (_updateLocationCubit == null) {
      log("UpdateLocationCubit not initialized");
      return;
    }

    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        log("📍 Updating location for trip: $tripId at ${position.latitude}, ${position.longitude}");
        
        // Try SignalR tracking hub first
        if (_signalRService != null && _signalRService!.isTrackingConnected) {
          final signalRSuccess = await _signalRService!.updateLocationTracking(
            tripId, 
            position.latitude.toString(), 
            position.longitude.toString()
          );
          
          if (signalRSuccess) {
            log("✅ Location updated successfully via SignalR tracking hub for trip: $tripId");
            return; // Success via SignalR, no need for REST API
          } else {
            log("⚠️ SignalR location update failed, falling back to REST API");
          }
        }
        
        // Fallback to REST API
        await _updateLocationCubit!.updateLocation(
          tripId: tripId,
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
        );

        final state = _updateLocationCubit!.state;
        if (state is UpdateLocationSuccess) {
          log("✅ Location updated successfully via REST API for trip: $tripId");
        } else if (state is UpdateLocationError) {
          log("❌ Failed to update location via REST API: ${state.message}");
          // Retry once after a short delay
          await Future.delayed(const Duration(seconds: 2));
          try {
            await _updateLocationCubit!.updateLocation(
              tripId: tripId,
              latitude: position.latitude.toString(),
              longitude: position.longitude.toString(),
            );
            log("🔄 Location update retry completed via REST API for trip: $tripId");
          } catch (retryError) {
            log("❌ Location update retry failed: $retryError");
          }
        }
      } else {
        log("⚠️ Could not get current location for trip: $tripId");
      }
    } catch (e) {
      log("❌ Error updating location: $e");
    }
  }

  // End trip tracking
  Future<void> _endTrip(String tripId) async {
    if (_endTripCubit == null) {
      log("EndTripCubit not initialized");
      return;
    }

    try {
      log("🏁 Ending trip: $tripId");
      
      // Try SignalR tracking hub first
      if (_signalRService != null && _signalRService!.isTrackingConnected) {
        final signalRSuccess = await _signalRService!.endTripTracking(tripId);
        
        if (signalRSuccess) {
          log("✅ Trip ended successfully via SignalR tracking hub: $tripId");
          return; // Success via SignalR, no need for REST API
        } else {
          log("⚠️ SignalR end trip failed, falling back to REST API");
        }
      }
      
      // Fallback to REST API
      await _endTripCubit!.endTrip(tripId);
      final state = _endTripCubit!.state;

      if (state is EndTripSuccess) {
        log("✅ Trip ended successfully via REST API: $tripId");
      } else if (state is EndTripError) {
        log("❌ Failed to end trip via REST API: ${state.message}");
        // Retry once after a short delay
        await Future.delayed(const Duration(seconds: 2));
        try {
          log("🔄 Retrying trip end via REST API...");
          await _endTripCubit!.endTrip(tripId);
          final retryState = _endTripCubit!.state;
          
          if (retryState is EndTripSuccess) {
            log("✅ Trip ended successfully via REST API on retry: $tripId");
          } else if (retryState is EndTripError) {
            log("❌ Trip end retry failed via REST API: ${retryState.message}");
          }
        } catch (retryError) {
          log("❌ Trip end retry error: $retryError");
        }
      }
    } catch (e) {
      log("❌ Error ending trip: $e");
    }
  }

  // Connect to SignalR and join traveler group
  Future<void> _connectToSignalR() async {
    if (_signalRService == null) {
      log("SignalRService not initialized");
      return;
    }

    try {
      // SignalR connection is already handled by main.dart, just ensure it's ready
      if (!_signalRService!.isConnected) {
        log("⚠️ SignalR not connected, but connection should be handled by main.dart");
        // Don't start connection here as it's already handled by main.dart
        return;
      } else {
        log("✅ SignalR already connected");
      }

      // Get traveler ID from cache and log connection
      final travelerId = CacheHelper.getData(key: ApiKey.userId)?.toString();
      if (travelerId != null && travelerId.isNotEmpty) {
        log("🔗 Establishing tracking connection for traveler: $travelerId");
        await _signalRService!.joinTravelerTrackingGroup(travelerId);
        log("✅ SignalR tracking connection ready for traveler: $travelerId");
      } else {
        log("⚠️ No traveler ID found in cache");
      }
    } catch (e) {
      log("❌ Error connecting to SignalR: $e");
      // Don't throw error - just log it and continue
    }
  }

  // Initialize SignalR connection for traveler (call this when traveler logs in)
  Future<void> initializeTravelerSignalR() async {
    log("🔗 Initializing SignalR connection for traveler...");
    await _connectToSignalR();
  }

  // Add listener for kid timer updates
  void addKidTimerListener(
      Function(int seconds, bool isRunning, String formattedTime) listener) {
    _kidListeners.add(listener);
  }

  // Add listener for traveler timer updates
  void addTravelerTimerListener(
      Function(int seconds, bool isRunning, String formattedTime) listener) {
    _travelerListeners.add(listener);
  }

  // Remove kid timer listener
  void removeKidTimerListener(
      Function(int seconds, bool isRunning, String formattedTime) listener) {
    _kidListeners.remove(listener);
  }

  // Remove traveler timer listener
  void removeTravelerTimerListener(
      Function(int seconds, bool isRunning, String formattedTime) listener) {
    _travelerListeners.remove(listener);
  }

  // Add kid dialog listener
  void addKidDialogListener(Function() listener) {
    _kidDialogListeners.add(listener);
  }

  // Add traveler dialog listener
  void addTravelerDialogListener(Function() listener) {
    _travelerDialogListeners.add(listener);
  }

  // Remove kid dialog listener
  void removeKidDialogListener(Function() listener) {
    _kidDialogListeners.remove(listener);
  }

  // Remove traveler dialog listener
  void removeTravelerDialogListener(Function() listener) {
    _travelerDialogListeners.remove(listener);
  }

  // Notify kid listeners
  void _notifyKidListeners() {
    final formattedTime = _formatTime(_kidSeconds);
    for (var listener in _kidListeners) {
      try {
        listener(_kidSeconds, _kidIsRunning, formattedTime);
      } catch (e) {
        log("Error notifying kid timer listener: $e");
      }
    }
  }

  // Notify traveler listeners
  void _notifyTravelerListeners() {
    final formattedTime = _formatTime(_travelerSeconds);
    for (var listener in _travelerListeners) {
      try {
        listener(_travelerSeconds, _travelerIsRunning, formattedTime);
      } catch (e) {
        log("Error notifying traveler timer listener: $e");
      }
    }
  }

  // Notify kid dialog listeners
  void _notifyKidDialogListeners() {
    for (var listener in _kidDialogListeners) {
      try {
        listener();
      } catch (e) {
        log("Error notifying kid dialog listener: $e");
      }
    }
  }

  // Notify traveler dialog listeners
  void _notifyTravelerDialogListeners() {
    for (var listener in _travelerDialogListeners) {
      try {
        listener();
      } catch (e) {
        log("Error notifying traveler dialog listener: $e");
      }
    }
  }

  // Start kid timer
  Future<void> startKidTimer() async {
    if (_kidIsRunning) return;

    // Connect to SignalR first
    await _connectToSignalR();

    // Start trip tracking
    final tripId = await _startTrip();
    if (tripId != null) {
      _kidTripId = tripId;
      log("🚗 Kid trip started with ID: $tripId");
    }

    _kidIsRunning = true;

    _kidTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _kidSeconds++;
      _notifyKidListeners();

      // Check if we need to show dialog (every 2 minutes = 120 seconds)
      if (_kidSeconds % 120 == 0) {
        _showTimerNotification(isKidMode: true);
        _notifyKidDialogListeners();
      }

      log("🕐 Kid Timer tick: ${_kidSeconds}s");
    });

    // Start location update timer (every 20 seconds)
    if (_kidTripId != null) {
      _kidLocationTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        _updateTripLocation(_kidTripId!);
        log("📍 Kid location update sent");
      });
    }

    _notifyKidListeners();
    log("🕐 Kid Timer started with trip tracking");
  }

  // Start traveler timer
  Future<void> startTravelerTimer() async {
    if (_travelerIsRunning) return;

    // Connect to SignalR first and ensure connection is stable
    log("🔗 Ensuring SignalR connection before starting traveler timer...");
    await _connectToSignalR();
    
    // Wait longer to ensure SignalR connection is stable and server recognizes it
    log("⏳ Waiting for SignalR connection to stabilize...");
    await Future.delayed(const Duration(seconds: 5));
    log("✅ SignalR connection should be stable now");

    // Start trip tracking
    final tripId = await _startTrip();
    if (tripId != null) {
      _travelerTripId = tripId;
      log("🚗 Traveler trip started with ID: $tripId");
    } else {
      log("⚠️ Failed to start trip, but continuing with timer");
    }

    _travelerIsRunning = true;

    _travelerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _travelerSeconds++;
      _notifyTravelerListeners();

      // Check if we need to show dialog (every 2 minutes = 120 seconds)
      if (_travelerSeconds % 120 == 0) {
        _showTimerNotification(isKidMode: false);
        _notifyTravelerDialogListeners();
      }

      log("🕐 Traveler Timer tick: ${_travelerSeconds}s");
    });

    // Start location update timer (every 20 seconds)
    if (_travelerTripId != null) {
      _travelerLocationTimer =
          Timer.periodic(const Duration(seconds: 20), (timer) {
        _updateTripLocation(_travelerTripId!);
        log("📍 Traveler location update sent");
      });
    }

    _notifyTravelerListeners();
    log("🕐 Traveler Timer started with trip tracking");
  }

  // Stop kid timer
  Future<void> stopKidTimer() async {
    _kidIsRunning = false;
    _kidTimer?.cancel();
    _kidTimer = null;

    // Stop location updates
    _kidLocationTimer?.cancel();
    _kidLocationTimer = null;

    // End trip tracking
    if (_kidTripId != null) {
      await _endTrip(_kidTripId!);
      _kidTripId = null;
      log("🏁 Kid trip ended");
    }

    _notifyKidListeners();
    log("🕐 Kid Timer stopped with trip tracking");
  }

  // Stop traveler timer
  Future<void> stopTravelerTimer() async {
    _travelerIsRunning = false;
    _travelerTimer?.cancel();
    _travelerTimer = null;

    // Stop location updates
    _travelerLocationTimer?.cancel();
    _travelerLocationTimer = null;

    // End trip tracking
    if (_travelerTripId != null) {
      await _endTrip(_travelerTripId!);
      _travelerTripId = null;
      log("🏁 Traveler trip ended");
    }

    _notifyTravelerListeners();
    log("🕐 Traveler Timer stopped with trip tracking");
  }

  // Reset kid timer
  Future<void> resetKidTimer() async {
    final wasRunning = _kidIsRunning;
    await stopKidTimer();
    _kidSeconds = 0;
    _notifyKidListeners();

    if (wasRunning) {
      await startKidTimer();
    }

    log("🕐 Kid Timer reset");
  }

  // Reset traveler timer
  Future<void> resetTravelerTimer() async {
    final wasRunning = _travelerIsRunning;
    await stopTravelerTimer();
    _travelerSeconds = 0;
    _notifyTravelerListeners();

    if (wasRunning) {
      await startTravelerTimer();
    }

    log("🕐 Traveler Timer reset");
  }

  // Show timer notification
  Future<void> _showTimerNotification({required bool isKidMode}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'timer_alert_channel',
      'Timer Alerts',
      channelDescription: 'Safety check notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      isKidMode ? 1 : 2, // Different notification IDs
      'Safety Check',
      isKidMode ? 'Hey Kid, Are You ok? (Every 2 minutes)' : 'Hey, Are You ok? (Every 2 minutes)',
      platformChannelSpecifics,
    );

    log("🔔 Timer notification shown (Kid Mode: $isKidMode) - Every 2 minutes");
  }

  // Get kid timer state
  Map<String, dynamic> getKidTimerState() {
    return {
      'seconds': _kidSeconds,
      'isRunning': _kidIsRunning,
      'isKidMode': true,
      'formattedTime': _formatTime(_kidSeconds),
    };
  }

  // Get traveler timer state
  Map<String, dynamic> getTravelerTimerState() {
    return {
      'seconds': _travelerSeconds,
      'isRunning': _travelerIsRunning,
      'isKidMode': false,
      'formattedTime': _formatTime(_travelerSeconds),
    };
  }

  // Format time
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Get kid timer getters
  int get kidSeconds => _kidSeconds;
  bool get kidIsRunning => _kidIsRunning;
  String get kidFormattedTime => _formatTime(_kidSeconds);

  // Get traveler timer getters
  int get travelerSeconds => _travelerSeconds;
  bool get travelerIsRunning => _travelerIsRunning;
  String get travelerFormattedTime => _formatTime(_travelerSeconds);

  // Dispose resources
  void dispose() {
    _kidTimer?.cancel();
    _travelerTimer?.cancel();
    _kidLocationTimer?.cancel();
    _travelerLocationTimer?.cancel();
    _kidListeners.clear();
    _travelerListeners.clear();
    _kidDialogListeners.clear();
    _travelerDialogListeners.clear();
  }

  // Debug method to test connection before starting trip
  Future<void> debugConnectionBeforeTrip() async {
    if (_signalRService == null) {
      log("❌ SignalRService not initialized for debugging");
      return;
    }

    try {
      log("🔍 === DEBUGGING CONNECTION BEFORE TRIP START ===");
      
      // Get comprehensive connection info
      final connectionInfo = await _signalRService!.getComprehensiveConnectionInfo();
      
      // Test enhanced connection verification
      final isVerified = await _signalRService!.ensureServerConnection();
      
      log("🔍 Enhanced connection verification result: $isVerified");
      
      // Get traveler ID
      final travelerId = CacheHelper.getData(key: ApiKey.userId)?.toString();
      log("🔍 Current traveler ID: $travelerId");
      
      // Test joining group
      if (travelerId != null && travelerId.isNotEmpty) {
        try {
          await _signalRService!.joinTravelerTrackingGroup(travelerId);
          log("🔍 Successfully joined traveler tracking group");
        } catch (e) {
          log("🔍 Failed to join traveler tracking group: $e");
        }
      }
      
      log("🔍 === END DEBUGGING ===");
      
    } catch (e) {
      log("❌ Error during connection debugging: $e");
    }
  }
}
