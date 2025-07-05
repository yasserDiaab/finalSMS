import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pro/repo/SupporterRepository.dart';
import 'add_supporter_state.dart';

class AddSupporterCubit extends Cubit<AddSupporterState> {
  final SupporterRepository repository;

  AddSupporterCubit(this.repository) : super(AddSupporterInitial());

  void addSupporter(String emailOrUsername) async {
    emit(AddSupporterLoading());

    try {
      final result = await repository.addSupporter(emailOrUsername);
      emit(AddSupporterSuccess(result.message));
    } catch (e) {
      emit(AddSupporterError(e.toString()));
    }
  }
}
