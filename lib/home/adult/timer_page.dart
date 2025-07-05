import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pro/widgets/header_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/sos/sos_cubit.dart';
import 'package:pro/cubit/sos/sos_state.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/services/app_timer_service.dart';
import 'dart:developer';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  int _seconds = 0;
  bool _isRunning = false;
  String _formattedTime = "00:00:00";

  Timer? _autoSosTimer; // Timer for automatic SOS
  bool _dialogShown = false; // Flag to track if dialog is currently shown
  int _autoSosCountdown = 10; // Countdown for automatic SOS
  Timer? _countdownTimer; // Timer for updating countdown display

  AppTimerService? _timerService;

  @override
  void initState() {
    super.initState();
    _initializeNotification();
    // Add a small delay to ensure GetIt is fully initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeTimerService();
      }
    });
  }

  void _initializeTimerService() {
    try {
      // Check if GetIt is ready and service is registered
      if (!getIt.isRegistered<AppTimerService>()) {
        log("❌ AppTimerService is not registered in GetIt");
        _setDefaultValues();
        return;
      }

      _timerService = getIt<AppTimerService>();

      if (_timerService == null) {
        log("❌ AppTimerService instance is null");
        _setDefaultValues();
        return;
      }

      // Add listener for timer updates
      _timerService?.addTravelerTimerListener(_onTimerUpdate);

      // Add listener for dialog triggers
      _timerService?.addTravelerDialogListener(_onDialogTrigger);

      // Load current state
      final state = _timerService?.getTravelerTimerState();
      if (state != null) {
        setState(() {
          _seconds = state['seconds'] ?? 0;
          _isRunning = state['isRunning'] ?? false;
          _formattedTime = state['formattedTime'] ?? "00:00:00";
        });
      } else {
        _setDefaultValues();
      }

      log("🕐 Timer page initialized with current state: ${_seconds}s");
    } catch (e) {
      log("❌ Error initializing timer service: $e");
      _setDefaultValues();
    }
  }

  void _setDefaultValues() {
    setState(() {
      _seconds = 0;
      _isRunning = false;
      _formattedTime = "00:00:00";
    });
  }

  void _onTimerUpdate(int seconds, bool isRunning, String formattedTime) {
    if (mounted) {
      setState(() {
        _seconds = seconds;
        _isRunning = isRunning;
        _formattedTime = formattedTime;
      });
    }
  }

  void _onDialogTrigger() {
    if (mounted && !_dialogShown) {
      _showAlertDialog();
    }
  }

  // تهيئة النوتوفيكيشن
  void _initializeNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // إظهار النوتوفيكيشن
  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'safety_channel',
      'Safety Notifications',
      channelDescription: 'Notify user every minute to check safety mode',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Safety Mode',
      'انتهت الدقيقة، افتح التطبيق لاختيار Yes أو No',
      platformChannelSpecifics,
    );
  }

  void _startTimer() {
    try {
      if (_timerService != null) {
        _timerService!.startTravelerTimer();
        log("🕐 Traveler timer started via service");
      } else {
        log("❌ Timer service not initialized");
      }
    } catch (e) {
      log("❌ Error starting traveler timer: $e");
    }
  }

  void _stopTimer() {
    try {
      if (_timerService != null) {
        _timerService!.stopTravelerTimer();
        log("🕐 Traveler timer stopped via service");
      } else {
        log("❌ Timer service not initialized");
      }
    } catch (e) {
      log("❌ Error stopping traveler timer: $e");
    }
  }

  void _resumeTimer() {
    try {
      if (_timerService != null) {
        _timerService!.startTravelerTimer();
        log("🕐 Traveler timer resumed via service");
      } else {
        log("❌ Timer service not initialized");
      }
    } catch (e) {
      log("❌ Error resuming traveler timer: $e");
    }
  }

  // Reset timer to start from beginning
  void _resetTimer() {
    try {
      if (_timerService != null) {
        _timerService!.resetTravelerTimer();
        log("🕐 Traveler timer reset via service");
      } else {
        log("❌ Timer service not initialized");
      }
    } catch (e) {
      log("❌ Error resetting traveler timer: $e");
    }
  }

  // Send SOS notification
  void _sendSosNotification(BuildContext context) {
    context.read<SosCubit>().sendSosNotification(
          message: "Timer expired - SOS! I need help!",
        );
  }

  // Start automatic SOS timer (10 seconds)
  void _startAutoSosTimer(BuildContext context) {
    _autoSosTimer?.cancel(); // Cancel any existing timer
    _countdownTimer?.cancel(); // Cancel any existing countdown timer

    setState(() {
      _autoSosCountdown = 10; // Reset countdown
    });

    // Start countdown timer (updates every second)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_dialogShown && mounted) {
        setState(() {
          _autoSosCountdown--;
        });

        if (_autoSosCountdown <= 0) {
          timer.cancel();
          // Send automatic SOS
          Navigator.of(context).pop(); // Close the dialog
          _sendSosNotification(context);
          _dialogShown = false;

          // Show automatic SOS message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No response detected - Automatic SOS sent!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        timer.cancel();
      }
    });
  }

  // Cancel automatic SOS timer
  void _cancelAutoSosTimer() {
    _autoSosTimer?.cancel();
    _countdownTimer?.cancel();
    _autoSosTimer = null;
    _countdownTimer = null;
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showAlertDialog() {
    setState(() {
      _dialogShown = true;
    });

    // Start the automatic SOS timer
    _startAutoSosTimer(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.blue,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                "Hey Ayman, Are You ok?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              // Countdown display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  'Auto SOS in: $_autoSosCountdown seconds',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      _cancelAutoSosTimer(); // Cancel automatic SOS
                      setState(() {
                        _dialogShown = false;
                      });
                      Navigator.of(context).pop();
                      _resetTimer(); // Reset timer and start from beginning
                    },
                    child: const Text(
                      "Yes",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _cancelAutoSosTimer(); // Cancel automatic SOS
                      setState(() {
                        _dialogShown = false;
                      });
                      Navigator.of(context).pop();
                      _sendSosNotification(context); // Send SOS notification
                    },
                    child: const Text(
                      "No",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Remove listeners from timer service
    _timerService?.removeTravelerTimerListener(_onTimerUpdate);
    _timerService?.removeTravelerDialogListener(_onDialogTrigger);

    _autoSosTimer?.cancel(); // Cancel automatic SOS timer
    _countdownTimer?.cancel(); // Cancel countdown timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SosCubit>(),
      child: BlocListener<SosCubit, SosState>(
        listener: (context, state) {
          if (state is SosSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SOS notification sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is SosFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send SOS: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              const HeaderProfile(),
              const SizedBox(height: 50),
              const Text(
                "Activate Safety Mode ",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
              const SizedBox(height: 60),
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(250, 250),
                    painter: CirclePainter(color: Colors.grey),
                  ),
                  CustomPaint(
                    size: const Size(250, 250),
                    painter: ArcPainter(
                      progress: (_seconds % 360) / 360,
                      color: const Color(0xff193869),
                    ),
                  ),
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xff193869),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isRunning ? Colors.grey : const Color(0xff193869),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(170, 25),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _stopTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isRunning ? const Color(0xff193869) : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(170, 25),
                    ),
                    child: const Text(
                      'Stop',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final Color color;
  CirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final startAngle = -3.14 / 2;
    final sweepAngle = 2 * 3.14 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
