import 'package:equatable/equatable.dart';
import 'package:pro/models/SosNotificationModel.dart';

abstract class SosState extends Equatable {
  const SosState();

  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {}

class SosLoading extends SosState {}

class SosSuccess extends SosState {
  final SosResponse response;

  const SosSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class SosFailure extends SosState {
  final String error;

  const SosFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class SosNotificationReceived extends SosState {
  final SosNotificationModel notification;

  const SosNotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class SosConnectionState extends SosState {
  final bool isConnected;

  const SosConnectionState(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}
