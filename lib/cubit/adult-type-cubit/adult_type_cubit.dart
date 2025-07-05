import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/repo/adult_type_repository.dart';

part 'adult_type_state.dart';

class AdultTypeCubit extends Cubit<AdultTypeState> {
  final AdultTypeRepository repository;

  AdultTypeCubit(this.repository) : super(AdultTypeInitial());

  Future<void> changeAdultType(String userId, String adultType) async {
    emit(AdultTypeLoading());
    try {
      final result = await repository.changeAdultType(
        userId: userId,
        adultType: adultType,
      );
      emit(AdultTypeSuccess(result.message));
    } catch (e) {
      emit(AdultTypeError(e.toString()));
    }
  }
}
