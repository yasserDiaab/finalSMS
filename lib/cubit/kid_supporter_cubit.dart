import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/kid_supporter_state.dart';
import 'package:pro/repo/KidSupporterRepository.dart';

class KidSupporterCubit extends Cubit<KidSupporterState> {
  final KidSupporterRepository repository;

  KidSupporterCubit(this.repository) : super(KidSupporterInitial());

  Future<void> addSupporterToKid(String emailOrUsername) async {
    try {
      log("KidSupporterCubit: Starting add supporter process for: $emailOrUsername");
      
      emit(KidSupporterAddLoading());

      final result = await repository.addSupporterToKid(emailOrUsername);
      
      log("KidSupporterCubit: Add supporter successful - ${result.message}");
      emit(KidSupporterAddSuccess(result));
      
    } catch (e) {
      log("KidSupporterCubit: Add supporter failed - $e");
      
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      emit(KidSupporterAddFailure(errorMessage));
    }
  }

  Future<void> getKidSupporters() async {
    try {
      log("KidSupporterCubit: Getting kid supporters");
      
      emit(KidSupporterGetLoading());

      final supporters = await repository.getKidSupporters();
      
      log("KidSupporterCubit: Get supporters successful - ${supporters.length} supporters found");
      emit(KidSupporterGetSuccess(supporters));
      
    } catch (e) {
      log("KidSupporterCubit: Get supporters failed - $e");
      
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      emit(KidSupporterGetFailure(errorMessage));
    }
  }

  Future<void> removeSupporterFromKid(String supporterId) async {
    try {
      log("KidSupporterCubit: Removing supporter: $supporterId");
      
      emit(KidSupporterRemoveLoading());

      final success = await repository.removeSupporterFromKid(supporterId);
      
      if (success) {
        log("KidSupporterCubit: Remove supporter successful");
        emit(KidSupporterRemoveSuccess(supporterId));
      } else {
        log("KidSupporterCubit: Remove supporter failed");
        emit(const KidSupporterRemoveFailure("Failed to remove supporter"));
      }
      
    } catch (e) {
      log("KidSupporterCubit: Remove supporter failed - $e");
      
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      emit(KidSupporterRemoveFailure(errorMessage));
    }
  }

  void resetState() {
    log("KidSupporterCubit: Resetting state");
    emit(KidSupporterInitial());
  }
}
