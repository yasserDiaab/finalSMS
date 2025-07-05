import 'dart:async';
import 'dart:developer';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/models/TripNotificationModel.dart';
import 'package:pro/services/notification_service.dart';
import 'package:pro/models/LocationNotificationModel.dart';

class SignalRService {
  // Singleton instance
  static SignalRService? _instance;
  static SignalRService get instance => _instance ??= SignalRService._internal();
  
  SignalRService._internal();

  // Notification Hub for SOS
  static const String notificationHubUrl =
      'https://followsafe.runasp.net/notificationHub';
  static const String sosMethodName = 'ReceiveSosNotification';

  // Tracking Hub for trip tracking
  static const String trackingHubUrl =
      'https://followsafe.runasp.net/trackingHub';

  // Notification hub connection
  HubConnection? _notificationHubConnection;

  // Tracking hub connection
  HubConnection? _trackingHubConnection;

  final StreamController<SosNotificationModel> _sosNotificationController =
      StreamController<SosNotificationModel>.broadcast();

  final StreamController<Map<String, dynamic>> _tripEventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Stream to listen for SOS notifications
  Stream<SosNotificationModel> get sosNotifications =>
      _sosNotificationController.stream;

  // Stream to listen for trip events (TripStarted, TripEnded)
  Stream<Map<String, dynamic>> get tripEventsStream =>
      _tripEventsController.stream;

  // Notification service instance
  final NotificationService _notificationService = NotificationService();

  // StreamController جديد لتحديثات الموقع
  final StreamController<LocationNotificationModel> _locationController =
      StreamController<LocationNotificationModel>.broadcast();

  // Stream عام يمكن الاستماع له في أي مكان
  Stream<LocationNotificationModel> get locationStream => _locationController.stream;

  bool _isNotificationConnected = false;
  bool _isTrackingConnected = false;
  bool _isStartingConnection = false; // Prevent concurrent connection attempts

  bool get isConnected => _isNotificationConnected && _isTrackingConnected;
  bool get isNotificationConnected => _isNotificationConnected;
  bool get isTrackingConnected => _isTrackingConnected;

  // Initialize and start both connections
  Future<void> startConnection() async {
    // Prevent concurrent connection attempts
    if (_isStartingConnection) {
      log('⚠️ Connection already being started, skipping...');
      return;
    }
    
    // If already connected, don't start again
    if (_isNotificationConnected && _isTrackingConnected) {
      log('✅ SignalR connections already established, skipping...');
      return;
    }

    _isStartingConnection = true;
    
    try {
      // Start notification hub connection
      await _startNotificationConnection();

      // Start tracking hub connection
      await _startTrackingConnection();

      log('✅ Both SignalR connections started successfully');
    } catch (e) {
      log('❌ Error starting SignalR connections: $e');
      rethrow;
    } finally {
      _isStartingConnection = false;
    }
  }

  // Start notification hub connection
  Future<void> _startNotificationConnection() async {
    if (_notificationHubConnection != null && _isNotificationConnected) {
      log('Notification hub connection already exists and is connected');
      return;
    }

    try {
      final token = CacheHelper.getData(key: ApiKey.token);

      if (token == null || token.toString().isEmpty) {
        log('WARNING: No token found for SignalR connection');
        return;
      }

      // Create the notification hub connection
      _notificationHubConnection = HubConnectionBuilder()
          .withUrl('$notificationHubUrl?access_token=$token')
          .withAutomaticReconnect()
          .build();

      // Register the SOS notification handler
      _notificationHubConnection!.on(sosMethodName, _handleSosNotification);

      // Start the connection
      await _notificationHubConnection!.start();
      _isNotificationConnected = true;
      log('✅ Notification hub connection started successfully');

      // Wait a bit to ensure connection is stable
      await Future.delayed(const Duration(seconds: 1));

      // Log connection details for debugging
      log('Notification Hub Connection Details:');
      log('- Hub URL: $notificationHubUrl');
      log('- Connection ID: ${_notificationHubConnection!.connectionId}');
      log('- State: ${_notificationHubConnection!.state}');
    } catch (e) {
      _isNotificationConnected = false;
      log('❌ Error starting notification hub connection: $e');
      rethrow;
    }
  }

  // Start tracking hub connection with event listeners for trip events
  Future<void> _startTrackingConnection() async {
    if (_trackingHubConnection != null && _isTrackingConnected) {
      log('Tracking hub connection already exists and is connected');
      return;
    }

    try {
      final token = CacheHelper.getData(key: ApiKey.token);

      if (token == null || token.toString().isEmpty) {
        log('WARNING: No token found for SignalR connection');
        return;
      }

      _trackingHubConnection = HubConnectionBuilder()
          .withUrl('$trackingHubUrl?access_token=$token')
          .withAutomaticReconnect()
          .build();

      // Listen for TripStarted event
      _trackingHubConnection!.on('TripStarted', (args) {
        log('Received TripStarted event: $args');
        if (args != null && args.isNotEmpty) {
          // Handle both cases: direct Map or List containing Map
          Map<String, dynamic> data;
          if (args[0] is Map<String, dynamic>) {
            data = args[0] as Map<String, dynamic>;
          } else if (args[0] is List && (args[0] as List).isNotEmpty) {
            data = (args[0] as List)[0] as Map<String, dynamic>;
          } else {
            log('❌ Unexpected data format in TripStarted event');
            return;
          }
          
          _tripEventsController.add({'event': 'TripStarted', 'data': data});
          
          // Log detailed data for debugging
          log('🔍 TripStarted data details:');
          log('  - Raw data: $data');
          log('  - Available keys: ${data.keys.toList()}');
          log('  - TripId: ${data['TripId']}');
          log('  - tripId: ${data['tripId']}');
          log('  - TravelerId: ${data['TravelerId']}');
          log('  - travelerId: ${data['travelerId']}');
          log('  - TravelerName: ${data['TravelerName']}');
          log('  - travelerName: ${data['travelerName']}');
          log('  - name: ${data['name']}');
          log('  - userName: ${data['userName']}');
          log('  - fullName: ${data['fullName']}');
          
          // Handle trip start notification for supporters
          try {
            final tripNotification = TripNotificationModel.fromJson(data);
            log('✅ TripNotificationModel created successfully:');
            log('  - TripId: ${tripNotification.tripId}');
            log('  - TravelerId: ${tripNotification.travelerId}');
            log('  - TravelerName: ${tripNotification.travelerName}');
            log('  - StartTime: ${tripNotification.startTime}');
            
            // Check if data is valid before sending to notification service
            if (tripNotification.travelerName.isEmpty) {
              log('⚠️ Warning: TravelerName is empty in SignalR!');
            }
            if (tripNotification.tripId.isEmpty) {
              log('⚠️ Warning: TripId is empty in SignalR!');
            }
            if (tripNotification.startTime.isEmpty) {
              log('⚠️ Warning: StartTime is empty in SignalR!');
            }
            
            _notificationService.handleTripStartNotification(tripNotification);
            log('Trip start notification processed for ${tripNotification.travelerName}');
          } catch (e) {
            log('❌ Error processing trip start notification: $e');
            log('❌ Error details: ${e.toString()}');
            
            // Try to create notification with fallback data
            try {
              final fallbackData = {
                'TripId': data['TripId'] ?? data['tripId'] ?? '',
                'TravelerId': data['TravelerId'] ?? data['travelerId'] ?? '',
                'TravelerName': data['TravelerName'] ?? data['travelerName'] ?? data['name'] ?? data['userName'] ?? data['fullName'] ?? 'Unknown Traveler',
                'TravelerPhone': data['TravelerPhone'] ?? data['travelerPhone'] ?? data['phone'] ?? '',
                'StartTime': data['StartTime'] ?? data['startTime'] ?? DateTime.now().toIso8601String(),
                'Status': data['Status'] ?? data['status'] ?? 'Active',
                'Action': data['Action'] ?? data['action'] ?? 'Started',
              };
              
              log('🔄 Trying fallback data: $fallbackData');
              final fallbackNotification = TripNotificationModel.fromJson(fallbackData);
              _notificationService.handleTripStartNotification(fallbackNotification);
              log('✅ Fallback trip notification processed for ${fallbackNotification.travelerName}');
            } catch (fallbackError) {
              log('❌ Fallback notification also failed: $fallbackError');
            }
          }
        }
      });

      // Listen for TripEnded event
      _trackingHubConnection!.on('TripEnded', (args) {
        log('Received TripEnded event: $args');
        if (args != null && args.isNotEmpty) {
          // Handle both cases: direct Map or List containing Map
          Map<String, dynamic> data;
          if (args[0] is Map<String, dynamic>) {
            data = args[0] as Map<String, dynamic>;
          } else if (args[0] is List && (args[0] as List).isNotEmpty) {
            data = (args[0] as List)[0] as Map<String, dynamic>;
          } else {
            log('❌ Unexpected data format in TripEnded event');
            return;
          }
          
          _tripEventsController.add({'event': 'TripEnded', 'data': data});
        }
      });

      // Listen for LocationUpdate event (جديد)
      _trackingHubConnection!.on('LocationUpdate', (args) {
        log('Received LocationUpdate event: $args');
        if (args != null && args.isNotEmpty) {
          Map<String, dynamic> data;
          if (args[0] is Map<String, dynamic>) {
            data = args[0] as Map<String, dynamic>;
          } else if (args[0] is List && (args[0] as List).isNotEmpty) {
            data = (args[0] as List)[0] as Map<String, dynamic>;
          } else {
            log('❌ Unexpected data format in LocationUpdate event');
            return;
          }
          try {
            final location = LocationNotificationModel.fromJson(data);
            log('✅ LocationNotificationModel created: lat=${location.latitude}, lng=${location.longitude}');
            _locationController.add(location);
          } catch (e) {
            log('❌ Error parsing LocationNotificationModel: $e');
          }
        }
      });

      await _trackingHubConnection!.start();
      _isTrackingConnected = true;
      log('✅ Tracking hub connection started successfully with event listeners');

      // Wait a bit to ensure connection is stable
      await Future.delayed(const Duration(seconds: 1));

      log('Tracking Hub Connection Details:');
      log('- Hub URL: $trackingHubUrl');
      log('- Connection ID: ${_trackingHubConnection!.connectionId}');
      log('- State: ${_trackingHubConnection!.state}');
    } catch (e) {
      _isTrackingConnected = false;
      log('❌ Error starting tracking hub connection: $e');
      rethrow;
    }
  }

  // Handle incoming SOS notifications
  void _handleSosNotification(List<Object?>? parameters) {
    if (parameters != null && parameters.isNotEmpty) {
      try {
        final data = parameters[0] as Map<String, dynamic>;

        // Check if this notification is intended for this user
        final bool isForSupportersOnly = data['sendToSupportersOnly'] == true;
        final String currentUserId =
            CacheHelper.getData(key: ApiKey.userId)?.toString() ?? '';
        final List<String> supporterIds = data['supporterIds'] != null
            ? List<String>.from(data['supporterIds'])
            : [];

        // If notification is for supporters only and this user is not in the supporters list,
        // and this user is not the traveler who sent the SOS, then ignore the notification
        final String travelerId = data['travelerId']?.toString() ?? '';
        if (isForSupportersOnly &&
            !supporterIds.contains(currentUserId) &&
            travelerId != currentUserId) {
          log('Ignoring SOS notification: Not in supporters list');
          return;
        }

        final notification = SosNotificationModel.fromJson(data);
        _sosNotificationController.add(notification);
        log('Received SOS notification: ${notification.message} from ${notification.travelerName}');
      } catch (e) {
        log('Error handling SOS notification: $e');
      }
    }
  }

  // Join traveler tracking group
  Future<void> joinTravelerTrackingGroup(String travelerId) async {
    if (_trackingHubConnection == null || !_isTrackingConnected) {
      log('Tracking hub connection not available');
      return;
    }

    try {
      log('🔗 Joining traveler tracking group for: $travelerId');

      await _trackingHubConnection!
          .invoke('JoinTravelerSupporterGroup', args: [travelerId]);

      log('✅ Successfully joined traveler tracking group: $travelerId');
      log('Tracking Hub Connection Status: ${getTrackingConnectionStatus()}');
      log('Connection ID: ${_trackingHubConnection!.connectionId}');
      log('Connection State: ${_trackingHubConnection!.state}');
    } catch (e) {
      log('❌ Error joining traveler tracking group: $e');
    }
  }

  // Start trip tracking via SignalR
  Future<bool> startTripTracking(String travelerId) async {
    if (_trackingHubConnection == null || !_isTrackingConnected) {
      log('Tracking hub connection not available for start trip');
      return false;
    }

    try {
      log('🚗 Starting trip tracking via SignalR for traveler: $travelerId');
      // Get traveler name from cache
      final travelerName = CacheHelper.getData(key: ApiKey.name)?.toString() ?? 
                          CacheHelper.getData(key: "userName")?.toString() ??
                          CacheHelper.getData(key: "fullName")?.toString() ??
                          "Unknown Traveler";
      log('🚗 SignalR: Traveler details:');
      log('  - TravelerId: $travelerId');
      log('  - TravelerName: $travelerName');
      // Send trip start notification with traveler details
      final tripData = {
        'TravelerId': travelerId,
        'TravelerName': travelerName,
        'StartTime': DateTime.now().toIso8601String(),
        'Status': 'Active',
        'Action': 'Started',
      };
      log('🚗 SignalR: Sending trip data (kid/traveler): $tripData');
      // Log إضافي يوضح نوع المستخدم
      if (travelerName.toLowerCase().contains('kid') || travelerName.toLowerCase().contains('طفل')) {
        log('🟢 [DEBUG] Trip start notification sent for KID: $tripData');
      } else {
        log('🔵 [DEBUG] Trip start notification sent for TRAVELER: $tripData');
      }
      await _trackingHubConnection!.invoke('TripStarted', args: [tripData]);
      log('✅ Trip tracking started successfully via SignalR');
      return true;
    } catch (e) {
      log('❌ Error starting trip tracking via SignalR: $e');
      return false;
    }
  }

  // Update location via SignalR
  Future<bool> updateLocationTracking(
      String tripId, String latitude, String longitude) async {
    if (_trackingHubConnection == null || !_isTrackingConnected) {
      log('Tracking hub connection not available for location update');
      return false;
    }

    try {
      log('📍 Updating location via SignalR for trip: $tripId');

      await _trackingHubConnection!
          .invoke('LocationUpdate', args: [tripId, latitude, longitude]);

      log('✅ Location updated successfully via SignalR');
      return true;
    } catch (e) {
      log('❌ Error updating location via SignalR: $e');
      return false;
    }
  }

  // End trip tracking via SignalR
  Future<bool> endTripTracking(String tripId) async {
    if (_trackingHubConnection == null || !_isTrackingConnected) {
      log('Tracking hub connection not available for end trip');
      return false;
    }

    try {
      log('🏁 Ending trip tracking via SignalR for trip: $tripId');

      await _trackingHubConnection!.invoke('TripEnded', args: [tripId]);

      log('✅ Trip tracking ended successfully via SignalR');
      return true;
    } catch (e) {
      log('❌ Error ending trip tracking via SignalR: $e');
      return false;
    }
  }

  // Test tracking hub connection
  Future<bool> testTrackingConnection() async {
    if (_trackingHubConnection == null || !_isTrackingConnected) {
      log('Tracking hub connection not available for testing');
      return false;
    }

    try {
      log('Tracking Hub Connection Test:');
      log('- Connection ID: ${_trackingHubConnection!.connectionId}');
      log('- Connection State: ${_trackingHubConnection!.state}');
      log('- Is Connected: $_isTrackingConnected');
      log('- Hub URL: $trackingHubUrl');

      await _trackingHubConnection!.invoke('Ping');

      log('✅ Tracking hub connection test successful');
      return true;
    } catch (e) {
      log('❌ Tracking hub connection test failed: $e');
      return false;
    }
  }

  // Verify server recognizes the connection
  Future<bool> verifyServerConnection() async {
    if (_trackingHubConnection == null || !_isTrackingConnected) {
      log('Tracking hub connection not available for verification');
      return false;
    }

    try {
      final travelerId = CacheHelper.getData(key: ApiKey.userId)?.toString();
      if (travelerId == null || travelerId.isEmpty) {
        log('No traveler ID found for connection verification');
        return false;
      }

      log('🔍 Verifying server connection recognition for traveler: $travelerId');

      await _trackingHubConnection!
          .invoke('VerifyConnection', args: [travelerId]);

      log('✅ Server connection verification successful');
      return true;
    } catch (e) {
      log('❌ Server connection verification failed: $e');
      return false;
    }
  }

  // Enhanced connection verification with retry
  Future<bool> ensureServerConnection() async {
    if (_trackingHubConnection == null || !_isTrackingConnected) {
      log('Tracking hub connection not available');
      return false;
    }

    try {
      final basicTest = await testTrackingConnection();
      if (!basicTest) {
        log('❌ Basic connection test failed');
        return false;
      }

      final serverVerification = await verifyServerConnection();
      if (!serverVerification) {
        log('⚠ Server verification failed, trying alternative method...');

        try {
          final travelerId =
              CacheHelper.getData(key: ApiKey.userId)?.toString();
          if (travelerId != null && travelerId.isNotEmpty) {
            await _trackingHubConnection!
                .invoke('RegisterConnection', args: [travelerId]);
            log('✅ Alternative server verification successful');
            return true;
          }
        } catch (altError) {
          log('❌ Alternative server verification failed: $altError');
        }

        return false;
      }

      return true;
    } catch (e) {
      log('❌ Enhanced connection verification failed: $e');
      return false;
    }
  }

  // Stop both connections
  Future<void> stopConnection() async {
    if (_notificationHubConnection != null) {
      try {
        await _notificationHubConnection!.stop();
        _isNotificationConnected = false;
        log('✅ Notification hub connection stopped');
      } catch (e) {
        log('❌ Error stopping notification hub connection: $e');
      }
    }

    if (_trackingHubConnection != null) {
      try {
        await _trackingHubConnection!.stop();
        _isTrackingConnected = false;
        log('✅ Tracking hub connection stopped');
      } catch (e) {
        log('❌ Error stopping tracking hub connection: $e');
      }
    }
  }

  // Get connection status
  String getConnectionStatus() {
    if (_notificationHubConnection == null && _trackingHubConnection == null) {
      return 'Not initialized';
    }
    if (!_isNotificationConnected && !_isTrackingConnected) {
      return 'Disconnected';
    }
    return 'Connected';
  }

  // Get tracking connection status
  String getTrackingConnectionStatus() {
    if (_trackingHubConnection == null) {
      return 'Not initialized';
    }
    if (!_isTrackingConnected) {
      return 'Disconnected';
    }
    return 'Connected';
  }

  // Get detailed connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isNotificationConnected': _isNotificationConnected,
      'isTrackingConnected': _isTrackingConnected,
      'notificationConnectionId': _notificationHubConnection?.connectionId,
      'trackingConnectionId': _trackingHubConnection?.connectionId,
      'notificationConnectionState':
          _notificationHubConnection?.state.toString(),
      'trackingConnectionState': _trackingHubConnection?.state.toString(),
      'notificationHubUrl': notificationHubUrl,
      'trackingHubUrl': trackingHubUrl,
    };
  }

  // Comprehensive connection test and debug info
  Future<Map<String, dynamic>> getComprehensiveConnectionInfo() async {
    final info = getConnectionInfo();

    info['currentUserId'] = CacheHelper.getData(key: ApiKey.userId)?.toString();
    info['hasToken'] = CacheHelper.getData(key: ApiKey.token) != null;
    info['timestamp'] = DateTime.now().toIso8601String();

    try {
      if (_trackingHubConnection != null && _isTrackingConnected) {
        await _trackingHubConnection!.invoke('Ping');
        info['pingTest'] = 'SUCCESS';
      } else {
        info['pingTest'] = 'FAILED - No connection';
      }
    } catch (e) {
      info['pingTest'] = 'FAILED - $e';
    }

    try {
      final travelerId = CacheHelper.getData(key: ApiKey.userId)?.toString();
      if (travelerId != null &&
          travelerId.isNotEmpty &&
          _trackingHubConnection != null &&
          _isTrackingConnected) {
        await _trackingHubConnection!
            .invoke('VerifyConnection', args: [travelerId]);
        info['serverRecognition'] = 'SUCCESS';
      } else {
        info['serverRecognition'] =
            'FAILED - Missing traveler ID or connection';
      }
    } catch (e) {
      info['serverRecognition'] = 'FAILED - $e';
    }

    log('🔍 Comprehensive Connection Info: $info');
    return info;
  }

  // Dispose resources
  void dispose() {
    stopConnection();
    _sosNotificationController.close();
    _tripEventsController.close();
    _locationController.close(); // إغلاق stream الموقع
  }
}
