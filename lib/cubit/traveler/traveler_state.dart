import 'package:equatable/equatable.dart';
import 'package:pro/models/AddTravelerModel.dart';

abstract class TravelerState extends Equatable {
  const TravelerState();

  @override
  List<Object?> get props => [];
}

class TravelerInitial extends TravelerState {}

class AddTravelerLoading extends TravelerState {}

class AddTravelerSuccess extends TravelerState {
  final AddTravelerModel travelerModel;

  const AddTravelerSuccess(this.travelerModel);

  @override
  List<Object?> get props => [travelerModel];
}

class AddTravelerError extends TravelerState {
  final String error;

  const AddTravelerError(this.error);

  @override
  List<Object?> get props => [error];
}
