abstract class AddSupporterState {}

class AddSupporterInitial extends AddSupporterState {}

class AddSupporterLoading extends AddSupporterState {}

class AddSupporterSuccess extends AddSupporterState {
  final String message;

  AddSupporterSuccess(this.message);
}

class AddSupporterError extends AddSupporterState {
  final String error;

  AddSupporterError(this.error);
}
