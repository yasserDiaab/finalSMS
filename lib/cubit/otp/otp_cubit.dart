import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:pro/repo/otp_repo.dart';

part 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  final OtpRepository? otpRepository;

  OtpCubit(this.otpRepository) : super(OtpInitial());

  // ✅ Confirm Email OTP
  Future<void> confirmEmailOtp(String code, String userId) async {
    emit(OtpLoading());
    final Either<String, void> result =
        await otpRepository!.confirmEmailOtp(code: code, userId: userId);

    result.fold(
      (failure) => emit(OtpError(error: failure)),
      (_) => emit(OtpSuccess()),
    );
  }
}
