import 'package:equatable/equatable.dart';
import 'package:pro/models/updatelocationModel.dart';

abstract class UpdateLocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateLocationInitial extends UpdateLocationState {}

class UpdateLocationLoading extends UpdateLocationState {}

class UpdateLocationSuccess extends UpdateLocationState {
  final UpdateLocationResponseModel response;

  UpdateLocationSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UpdateLocationError extends UpdateLocationState {
  final String message;

  UpdateLocationError(this.message);

  @override
  List<Object?> get props => [message];
}
