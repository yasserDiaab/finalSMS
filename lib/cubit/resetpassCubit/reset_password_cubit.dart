import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pro/models/reset_password_model.dart';
import 'package:pro/repo/reset_password_repo.dart';
import 'package:dartz/dartz.dart';

part 'reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final ResetPasswordRepository resetPasswordRepository;

  ResetPasswordCubit(this.resetPasswordRepository)
      : super(ResetPasswordInitial());

  Future<void> resetPassword({
    required String userId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    emit(ResetPasswordLoading());

    final result = await resetPasswordRepository.resetPassword(
      userId: userId,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (error) => emit(ResetPasswordError(error)),
      (model) => emit(ResetPasswordSuccess(model.message)),
    );
  }
}
