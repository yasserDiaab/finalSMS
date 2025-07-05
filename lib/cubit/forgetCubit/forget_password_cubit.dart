import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pro/models/forget_password_model.dart';
import 'package:pro/repo/forgetrepo.dart';

part 'forget_password_state.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  ForgetPasswordCubit(this.forgetRepo) : super(ForgetPasswordInitial());
  final ForgetRepo forgetRepo;

  // ✅ Forget Password
  Future<void> forgetPassword(String email) async {
    emit(ForgetPasswordLoading());
    final response = await forgetRepo.forgetPassword(email: email);

    response.fold(
      (errMessage) => emit(ForgetPasswordFailure(errMessage: errMessage)),
      (forget) => emit(ForgetPasswordSuccess(
          message: 'Sign-up successful 🎉',
          forgetPasswordModel: forget)), // Emit success state
    );
  }
}
