import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/resetpassCubit/reset_password_cubit.dart';
import 'package:pro/login/forgot.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/repo/reset_password_repo.dart';

class ResetPasswordWrapper extends StatelessWidget {
  const ResetPasswordWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordCubit>(
      create: (_) => ResetPasswordCubit(getIt<ResetPasswordRepository>()),
      child: ForgotPassword(),
    );
  }
}
