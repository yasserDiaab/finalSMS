import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/user_cubit.dart';
import 'package:pro/cubit/user_state.dart';
import 'package:pro/services/offline_sync_service.dart';
import 'package:pro/core/di/di.dart';

import 'otp1.dart';

class SignUpListener extends StatelessWidget {
  const SignUpListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is SignUpLoading) {
          _showLoading(context);
        } else if (state is SignUpSuccess) {
          _hideLoading(context);
          _showMessage(context, "Sign-up successful 🎉",
              Colors.green); // ✅ Success message

          final userId = state.signUpModel.userId;
          log("========================================userId:$userId!");

          // جلب أرقام الهواتف للمؤيدين بعد التسجيل
          _syncSupporterPhonesAfterSignUp();

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return OTP(
                id: userId,
              );
            }));
          });
        } else if (state is SignUpFailure) {
          _hideLoading(context);
          _showMessage(context, state.errMessage, Colors.red);
        }
      },
      child:
          const SizedBox.shrink(), // Empty child since this is a listener only
    );
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // جلب أرقام الهواتف للمؤيدين بعد التسجيل
  void _syncSupporterPhonesAfterSignUp() async {
    try {
      log("🔄 Syncing supporter phones after sign up...");

      final offlineSyncService = getIt<OfflineSyncService>();
      final success =
          await offlineSyncService.syncTravelerSupporterPhones(forceSync: true);

      if (success) {
        log("✅ Supporter phones synced successfully after sign up");

        // طباعة محتويات قاعدة البيانات المحلية
        await _printLocalDatabaseContents();
      } else {
        log("⚠️ Failed to sync supporter phones after sign up");
      }
    } catch (e) {
      log("❌ Error syncing supporter phones after sign up: $e");
    }
  }

  // طباعة محتويات قاعدة البيانات المحلية
  Future<void> _printLocalDatabaseContents() async {
    try {
      log("📊 ===== LOCAL DATABASE CONTENTS (SIGN UP) =====");

      final offlineSyncService = getIt<OfflineSyncService>();
      final phones = await offlineSyncService.getTravelerSupporterPhones();
      final stats = await offlineSyncService.getDatabaseStats();

      log("📱 Total phones in database: ${phones.length}");
      log("📊 Database stats: $stats");

      if (phones.isNotEmpty) {
        log("📋 Phone numbers list:");
        for (int i = 0; i < phones.length; i++) {
          final phone = phones[i];
          log("  ${i + 1}. ${phone.supporterName} - ${phone.phoneNumber}");
          if (phone.email != null && phone.email!.isNotEmpty) {
            log("     Email: ${phone.email}");
          }
          log("     Last Updated: ${phone.lastUpdated}");
          log("     Active: ${phone.isActive}");
          log("");
        }
      } else {
        log("❌ No phone numbers found in local database");
      }

      log("📊 ===== END LOCAL DATABASE CONTENTS (SIGN UP) =====");
    } catch (e) {
      log("❌ Error printing local database contents: $e");
    }
  }
}
