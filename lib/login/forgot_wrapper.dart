import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/forgetCubit/forget_password_cubit.dart';
import 'package:pro/login/forgot.dart';
import 'package:pro/core/di/di.dart';
import 'package:pro/repo/forgetrepo.dart';

class ForgotWrapper extends StatelessWidget {
  const ForgotWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgetPasswordCubit>(
      create: (_) => ForgetPasswordCubit(getIt<ForgetRepo>()),
      child: ForgotPassword(),
    );
  }
}
