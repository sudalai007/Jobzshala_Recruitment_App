import 'package:equatable/equatable.dart';

abstract class JobMatchesEvent extends Equatable {
  const JobMatchesEvent();

  @override
  List<Object?> get props => [];
}

class LoadJobMatchesEvent extends JobMatchesEvent {
  final String? country;
  final bool forceRefresh;

  const LoadJobMatchesEvent({this.country, this.forceRefresh = false});

  @override
  List<Object?> get props => [country, forceRefresh];
}

class LoadMoreJobMatchesEvent extends JobMatchesEvent {}

class FilterCountryChangedEvent extends JobMatchesEvent {
  final String country;

  const FilterCountryChangedEvent(this.country);

  @override
  List<Object?> get props => [country];
}

class ApplyJobOptimisticEvent extends JobMatchesEvent {
  final String jobId;

  const ApplyJobOptimisticEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class ApplyJobRollbackEvent extends JobMatchesEvent {
  final String jobId;

  const ApplyJobRollbackEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class ConnectivityChangedEvent extends JobMatchesEvent {
  final bool isConnected;

  const ConnectivityChangedEvent(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}

