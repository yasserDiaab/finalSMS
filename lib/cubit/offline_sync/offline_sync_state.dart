import 'package:equatable/equatable.dart';
import 'package:pro/models/supporter_phone_model.dart';

abstract class OfflineSyncState extends Equatable {
  const OfflineSyncState();

  @override
  List<Object?> get props => [];
}

class OfflineSyncInitial extends OfflineSyncState {}

class OfflineSyncLoading extends OfflineSyncState {}

class OfflineSyncSuccess extends OfflineSyncState {
  final List<SupporterPhoneModel> supporterPhones;
  final String message;
  final DateTime lastSyncTime;

  const OfflineSyncSuccess({
    required this.supporterPhones,
    required this.message,
    required this.lastSyncTime,
  });

  @override
  List<Object?> get props => [supporterPhones, message, lastSyncTime];
}

class OfflineSyncFailure extends OfflineSyncState {
  final String error;

  const OfflineSyncFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class OfflineSyncNoConnection extends OfflineSyncState {
  final List<SupporterPhoneModel> cachedPhones;
  final String message;

  const OfflineSyncNoConnection({
    required this.cachedPhones,
    required this.message,
  });

  @override
  List<Object?> get props => [cachedPhones, message];
}

class OfflineSyncSearchResult extends OfflineSyncState {
  final List<SupporterPhoneModel> searchResults;
  final String query;

  const OfflineSyncSearchResult({
    required this.searchResults,
    required this.query,
  });

  @override
  List<Object?> get props => [searchResults, query];
}
