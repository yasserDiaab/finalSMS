import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/kid_profile/kid_profile_state.dart';
import 'package:pro/repo/kid_profile_repo.dart';

class KidProfileCubit extends Cubit<KidProfileState> {
  final KidProfileRepository repository;

  KidProfileCubit(this.repository) : super(KidProfileInitial());

  Future<void> getProfile(String token) async {
    try {
      emit(KidProfileLoading());

      final profile = await repository.getKidProfile(token);

      emit(KidProfileLoaded(profile));
    } catch (e) {
      log("❌ Failed to get profile: $e");
      emit(KidProfileError(e.toString()));
    }
  }
}
