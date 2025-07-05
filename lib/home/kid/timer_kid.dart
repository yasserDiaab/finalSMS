import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/sos/sos_cubit.dart';
import 'package:pro/cubit/sos/sos_state.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/services/app_timer_service.dart';
import 'dart:developer';
import 'package:pro/cache/CacheHelper.dart';
import 'package:pro/core/API/ApiKey.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class TimerWidgetKid extends StatefulWidget {
  const TimerWidgetKid({super.key});

  @override
  _TimerWidgetKidState createState() => _TimerWidgetKidState();
}

class _TimerWidgetKidState extends State<TimerWidgetKid> {
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
        log("❌ AppTimerService is not registered in GetIt for kid timer");
        _setDefaultValues();
        return;
      }

      _timerService = getIt<AppTimerService>();

      if (_timerService == null) {
        log("❌ AppTimerService instance is null for kid timer");
        _setDefaultValues();
        return;
      }

      // Add listener for timer updates
      _timerService?.addKidTimerListener(_onTimerUpdate);

      // Add listener for dialog triggers
      _timerService?.addKidDialogListener(_onDialogTrigger);

      // Load current state
      final state = _timerService?.getKidTimerState();
      if (state != null) {
        setState(() {
          _seconds = state['seconds'] ?? 0;
          _isRunning = state['isRunning'] ?? false;
          _formattedTime = state['formattedTime'] ?? "00:00:00";
        });
      } else {
        _setDefaultValues();
      }

      log("🕐 Kid timer page initialized with current state: ${_seconds}s");
    } catch (e) {
      log("❌ Error initializing kid timer service: $e");
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

  // Initialize notification
  void _initializeNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show notification
  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'kid_safety_channel',
      'Kid Safety Notifications',
      channelDescription: 'Notify kid every 10 seconds to check safety mode',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Safety Check',
      'Are you okay? Please respond.',
      platformChannelSpecifics,
    );
  }

  void _startTimer() {
    try {
      // تحقق من وجود بيانات المستخدم في الكاش
      final userId = CacheHelper.getData(key: ApiKey.userId)?.toString() ??
                    CacheHelper.getData(key: ApiKey.id)?.toString() ??
                    CacheHelper.getData(key: "userId")?.toString() ??
                    CacheHelper.getData(key: "UserId")?.toString() ??
                    CacheHelper.getData(key: "sub")?.toString() ??
                    CacheHelper.getData(key: "current_user_id")?.toString();
      
      final userName = CacheHelper.getData(key: ApiKey.name)?.toString() ??
                      CacheHelper.getData(key: "userName")?.toString() ??
                      CacheHelper.getData(key: "fullName")?.toString() ??
                      CacheHelper.getData(key: "user_name_from_token")?.toString() ??
                      "Kid"; // fallback name
      
      if (userId == null || userId.isEmpty) {
        log("❌ لا يمكن بدء التايمر: userId غير متوفر في الكاش");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('بيانات المستخدم غير متوفرة. يرجى إعادة تسجيل الدخول.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      log("✅ بيانات المستخدم متوفرة - userId: $userId, userName: $userName");
      log("➡️ سيتم استدعاء startKidTimer الآن...");
      if (_timerService != null) {
        _timerService!.startKidTimer();
        log("✅ تم استدعاء startKidTimer بنجاح");
      } else {
        log("❌ Kid timer service not initialized");
      }
    } catch (e) {
      log("❌ Error starting kid timer: $e");
    }
  }

  void _stopTimer() {
    try {
      log("➡️ سيتم استدعاء stopKidTimer الآن...");
      if (_timerService != null) {
        _timerService!.stopKidTimer();
        log("✅ تم استدعاء stopKidTimer بنجاح");
      } else {
        log("❌ Kid timer service not initialized");
      }
    } catch (e) {
      log("❌ Error stopping kid timer: $e");
    }
  }

  // Reset timer to start from beginning
  void _resetTimer() {
    try {
      if (_timerService != null) {
        _timerService!.resetKidTimer();
        log("🕐 Kid timer reset via service");
      } else {
        log("❌ Kid timer service not initialized");
      }
    } catch (e) {
      log("❌ Error resetting kid timer: $e");
    }
  }

  // Send SOS notification using SosCubit
  void _sendSosNotification(BuildContext context) {
    log("🚨 KID TIMER: Sending SOS alert using SosCubit");
    context.read<SosCubit>().sendSosNotification(
          message: "Kid timer expired - Emergency! Kid needs help!",
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
        return StatefulBuilder(
          builder: (context, setState) {
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
                    "Hey Kid, Are You ok?",
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
                          _sendSosNotification(
                              context); // Send SOS notification
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
      },
    );
  }

  @override
  void dispose() {
    // Remove listeners from timer service
    _timerService?.removeKidTimerListener(_onTimerUpdate);
    _timerService?.removeKidDialogListener(_onDialogTrigger);

    _autoSosTimer?.cancel(); // Cancel automatic SOS timer
    _countdownTimer?.cancel(); // Cancel countdown timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SosCubit>()..initialize(),
      child: BlocListener<SosCubit, SosState>(
        listener: (context, state) {
          if (state is SosLoading) {
            // Show loading message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sending SOS...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is SosSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚨 SOS sent to all supporters!'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            log("✅ KID TIMER: SOS sent successfully");
          } else if (state is SosFailure) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Failed to send SOS: ${state.error}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            log("❌ KID TIMER: SOS failed: ${state.error}");
          }
        },
        child: Scaffold(
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  // تعديل ارتفاع الـ Container الأبيض العلوي
                  Container(
                    height: 120, // تم تقليل الارتفاع من 180 إلى 120
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(
                          width: 80,
                        ),
                        const Text(
                          'Safety Mode',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff00ff88), Color(0xff00d2ff)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Spacer(flex: 1), // مساحة علوية
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(300, 300), // زيادة حجم الدائرة
                                painter: CirclePainter(color: Colors.white),
                              ),
                              CustomPaint(
                                size: const Size(
                                    300, 300), // زيادة حجم القطاع الدائري
                                painter: ArcPainter(
                                  progress: (_seconds % 3600) / 3600,
                                  color: const Color(0xff193869),
                                ),
                              ),
                              Text(
                                _formatTime(_seconds),
                                style: const TextStyle(
                                  fontSize: 24, // زيادة حجم النص
                                  color: Color(0xff193869),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _isRunning ? null : _startTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isRunning ? Colors.grey : Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  fixedSize:
                                      const Size(140, 40), // زيادة حجم الأزرار
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Activate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: _isRunning ? _stopTimer : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isRunning ? Colors.red : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  fixedSize:
                                      const Size(140, 40), // زيادة حجم الأزرار
                                  side: BorderSide(
                                      color: _isRunning
                                          ? Colors.red
                                          : Colors.grey),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'Stop',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _isRunning
                                        ? Colors.white
                                        : Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 2), // مساحة سفلية
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // إضافة مسافة من الأعلى للصورة
              Positioned(
                top: 80, // تم تعديل المسافة من الأعلى من 140 إلى 80
                left: 0,
                right: 0,
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/girl.png",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
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

    final startAngle = -3.14 / 2;
    final sweepAngle = 2 * 3.14 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
