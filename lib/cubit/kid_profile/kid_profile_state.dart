import 'package:equatable/equatable.dart';
import 'package:pro/models/kid_profile_model.dart';

abstract class KidProfileState extends Equatable {
  const KidProfileState();

  @override
  List<Object?> get props => [];
}

class KidProfileInitial extends KidProfileState {}

class KidProfileLoading extends KidProfileState {}

class KidProfileLoaded extends KidProfileState {
  final KidProfileModel profile;

  const KidProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class KidProfileError extends KidProfileState {
  final String message;

  const KidProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
