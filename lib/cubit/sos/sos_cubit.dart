import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';
import 'package:pro/cubit/sos/sos_state.dart';
import 'package:pro/models/SosNotificationModel.dart';
import 'package:pro/repo/SosRepository.dart';
import 'package:pro/services/notification_service.dart';
import 'package:pro/services/offline_sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SosCubit extends Cubit<SosState> {
  final SosRepository sosRepository;
  StreamSubscription? _sosNotificationSubscription;
  final Location _location = Location();
  final NotificationService _notificationService = NotificationService();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  BuildContext? _context;

  SosCubit({required this.sosRepository}) : super(SosInitial()) {
    // Listen for incoming SOS notifications
    _sosNotificationSubscription =
        sosRepository.signalRService.sosNotifications.listen((notification) {
      // Check if this notification should be shown to this user
      if (shouldShowNotification(notification)) {
        // Emit state
        emit(SosNotificationReceived(notification));

        // Show notification
        _notificationService.showSosNotification(notification);

        // Show dialog if context is available
        if (_context != null) {
          _notificationService.showSosDialog(_context!, notification);
        }

        log('Received SOS notification from ${notification.travelerName}');
      } else {
        log('Ignoring SOS notification: User is not a supporter or the traveler');
      }
    }, onError: (error) {
      log('Error in SOS notification stream: $error');
    });
  }

  // Set context for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  // Check if this notification should be shown to this user
  bool shouldShowNotification(SosNotificationModel notification) {
    // Get the current user ID
    final currentUserId =
        CacheHelper.getData(key: ApiKey.userId)?.toString() ?? '';
    if (currentUserId.isEmpty) {
      log('WARNING: Current user ID not found in cache');
      return false;
    }

    // Always show notification to the traveler who sent it
    if (notification.travelerId == currentUserId) {
      log('Showing notification to traveler (self)');
      return true;
    }

    // Check if this user is in the supporters list
    final List<String> supporterIds = notification.supporterIds ?? [];
    final bool isSupporter = supporterIds.contains(currentUserId);

    if (isSupporter) {
      log('Showing notification to supporter: $currentUserId');
      return true;
    }

    log('Not showing notification to user: $currentUserId (not traveler or supporter)');
    return false;
  }

  // Initialize location service and SignalR connection
  Future<void> initialize() async {
    try {
      // Connect to SignalR hub
      await sosRepository.connectToSignalR();
      emit(const SosConnectionState(true));
    } catch (e) {
      log('Error initializing SOS service: $e');
      emit(const SosConnectionState(false));
    }
  }

  // Check internet connectivity
  Future<bool> _isConnected() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      log('❌ Error checking connectivity: $e');
      return false;
    }
  }

  // Send SMS to supporters
  Future<void> _sendSMSToSupporters() async {
    try {
      log('📱 Sending SMS to supporters...');

      // Get supporter phones from local database
      final supporterPhones =
          await _offlineSyncService.getTravelerSupporterPhones();

      if (supporterPhones.isEmpty) {
        log('⚠️ No supporter phones found in local database');
        emit(const SosFailure('No supporter phones found locally'));
        return;
      }

      int successCount = 0;
      // Get last known location from cache
      final lastLat = CacheHelper.getData(key: 'last_latitude');
      final lastLng = CacheHelper.getData(key: 'last_longitude');

      String locationText = '';
      if (lastLat != null && lastLng != null) {
        locationText =
            '\nLocation: https://www.google.com/maps/search/?api=1&query=$lastLat,$lastLng';
      }
      final String dangerMessage =
          "I am in danger!\nSOS: أنا في خطر وأحتاج مساعدة عاجلة$locationText";

      // Show confirmation dialog for SMS
      if (_context != null) {
        final bool shouldSend =
            await _showSMSConfirmationDialog(supporterPhones.length);
        if (!shouldSend) {
          emit(const SosFailure('SMS sending cancelled by user'));
          return;
        }
      }

      for (var supporter in supporterPhones) {
        try {
          // Create SMS URI - SMS only, no WhatsApp
          final Uri smsUri = Uri(
            scheme: 'sms',
            path: supporter.phoneNumber,
            queryParameters: {'body': dangerMessage},
          );

          // Launch SMS app directly - no WhatsApp suggestions
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri, mode: LaunchMode.platformDefault);
            successCount++;
            log('✅ SMS sent to ${supporter.supporterName}: ${supporter.phoneNumber}');
          } else {
            log('❌ Could not launch SMS for ${supporter.supporterName}');
          }
        } catch (e) {
          log('❌ Error sending SMS to ${supporter.supporterName}: $e');
        }
      }

      log('📱 SMS sent to $successCount out of ${supporterPhones.length} supporters');

      if (successCount > 0) {
        emit(SosSuccess(SosResponse(
          success: true,
          message: 'تم إرسال SMS إلى $successCount مؤيد',
        )));
      } else {
        emit(const SosFailure('فشل في إرسال SMS إلى أي مؤيد'));
      }
    } catch (e) {
      log('❌ Error in _sendSMSToSupporters: $e');
      emit(SosFailure('خطأ في إرسال SMS: $e'));
    }
  }

  // Show SMS confirmation dialog
  Future<bool> _showSMSConfirmationDialog(int supporterCount) async {
    if (_context == null) return true;

    return await showDialog<bool>(
          context: _context!,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('إرسال رسالة SMS عاجلة'),
              content: Text(
                'سيتم إرسال رسالة "SOS: أنا في خطر وأحتاج مساعدة عاجلة" إلى $supporterCount مؤيد.\n\n'
                'هذا الإجراء سيستخدم SMS فقط (وليس الواتساب).\n\n'
                'هل تريد المتابعة؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('إرسال SMS'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Send SOS notification with current location
  Future<void> sendSosNotification(
      {String message = "SOS! I need help!"}) async {
    emit(SosLoading());

    try {
      // Check internet connectivity first
      final bool isConnected = await _isConnected();

      if (!isConnected) {
        log('🌐 No internet connection, sending SMS to supporters...');
        await _sendSMSToSupporters();
        return;
      }

      log('🌐 Internet connection available, sending SOS via API...');

      // Check and request location permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          emit(const SosFailure('Location services are disabled'));
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          emit(const SosFailure('Location permission denied'));
          return;
        }
      }

      // Get current location
      final locationData = await _location.getLocation();

      if (locationData.latitude == null || locationData.longitude == null) {
        emit(const SosFailure('Could not get current location'));
        return;
      }

      // Send SOS notification via API
      final result = await sosRepository.sendSosNotification(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        message: message,
      );

      result.fold(
        (error) {
          log('❌ API SOS failed, trying SMS fallback...');
          // If API fails, try SMS as fallback
          _sendSMSToSupporters();
        },
        (response) {
          // Create a notification for the traveler who sent the SOS
          final sosNotification = SosNotificationModel(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!,
            message: message,
            travelerId: sosRepository.getUserId() ?? '',
            travelerName: sosRepository.getUserName() ?? 'You',
            timestamp: DateTime.now(),
            // Include the same supporter IDs that were sent to the server
            supporterIds: result
                .getOrElse(() => SosResponse(success: false, message: ''))
                .supporterIds,
          );

          // Add notification to the traveler's notification list
          _notificationService.addInAppNotification(sosNotification);

          // Emit success state
          emit(SosSuccess(response));
        },
      );
    } catch (e) {
      log('❌ Error sending SOS notification: $e');
      // Try SMS as fallback
      await _sendSMSToSupporters();
    }
  }

  @override
  Future<void> close() {
    _sosNotificationSubscription?.cancel();
    sosRepository.dispose();
    return super.close();
  }
}
