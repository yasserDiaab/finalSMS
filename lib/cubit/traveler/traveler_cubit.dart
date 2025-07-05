import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/cubit/traveler/traveler_state.dart';
import 'package:pro/repo/TravelerRepository.dart';

class TravelerCubit extends Cubit<TravelerState> {
  final TravelerRepository travelerRepository;

  TravelerCubit({required this.travelerRepository}) : super(TravelerInitial());

  Future<void> addTraveler(String emailOrUsername) async {
    try {
      emit(AddTravelerLoading());
      
      log('TravelerCubit: Adding traveler with email/username: $emailOrUsername');
      
      final travelerModel = await travelerRepository.addTraveler(emailOrUsername);
      
      log('TravelerCubit: Traveler added successfully: ${travelerModel.message}');
      
      emit(AddTravelerSuccess(travelerModel));
    } catch (e) {
      log('TravelerCubit: Error adding traveler: $e');
      
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.split('Exception: ')[1];
      }
      
      emit(AddTravelerError(errorMessage));
    }
  }
}
