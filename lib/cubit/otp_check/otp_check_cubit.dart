import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:pro/repo/otp_check_repo.dart';

part 'otp_check_state.dart';

class OtpCheckCubit extends Cubit<OtpCheckState> {
  final OtpCheckRepository otpCheckRepository;

  OtpCheckCubit(this.otpCheckRepository) : super(OtpCheckInitial());

  Future<void> checkOtp(String code, String userId) async {
    emit(OtpCheckLoading());

    final Either<String, void> result = await otpCheckRepository.checkOtp(
      code: code,
      userId: userId,
    );

    result.fold(
      (failure) => emit(OtpCheckError(error: failure)),
      (_) => emit(OtpCheckSuccess()),
    );
  }
}
