import 'package:equatable/equatable.dart';
import 'package:pro/models/KidAddSupporterModel.dart';

abstract class KidSupporterState extends Equatable {
  const KidSupporterState();

  @override
  List<Object?> get props => [];
}

class KidSupporterInitial extends KidSupporterState {}

// Add Supporter States
class KidSupporterAddLoading extends KidSupporterState {}

class KidSupporterAddSuccess extends KidSupporterState {
  final KidAddSupporterModel result;

  const KidSupporterAddSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class KidSupporterAddFailure extends KidSupporterState {
  final String error;

  const KidSupporterAddFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Get Supporters States
class KidSupporterGetLoading extends KidSupporterState {}

class KidSupporterGetSuccess extends KidSupporterState {
  final List<Map<String, dynamic>> supporters;

  const KidSupporterGetSuccess(this.supporters);

  @override
  List<Object?> get props => [supporters];
}

class KidSupporterGetFailure extends KidSupporterState {
  final String error;

  const KidSupporterGetFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Remove Supporter States
class KidSupporterRemoveLoading extends KidSupporterState {}

class KidSupporterRemoveSuccess extends KidSupporterState {
  final String supporterId;

  const KidSupporterRemoveSuccess(this.supporterId);

  @override
  List<Object?> get props => [supporterId];
}

class KidSupporterRemoveFailure extends KidSupporterState {
  final String error;

  const KidSupporterRemoveFailure(this.error);

  @override
  List<Object?> get props => [error];
}
