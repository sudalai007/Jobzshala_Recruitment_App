import 'package:equatable/equatable.dart';

abstract class JobDetailEvent extends Equatable {
  const JobDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadJobDetailEvent extends JobDetailEvent {
  final String jobId;

  const LoadJobDetailEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class ApplyJobDetailEvent extends JobDetailEvent {
  final String jobId;

  const ApplyJobDetailEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

