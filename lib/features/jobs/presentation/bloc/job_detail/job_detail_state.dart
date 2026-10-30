import 'package:equatable/equatable.dart';
import '../../../domain/entities/job.dart';

enum JobDetailStatus { initial, loading, success, failure }
enum ApplyStatus { idle, optimisticApplied, confirmed, failed }

class JobDetailState extends Equatable {
  final JobDetailStatus status;
  final ApplyStatus applyStatus;
  final Job? job;
  final bool isOffline;
  final String? errorMessage;
  final String? applyErrorMessage;

  const JobDetailState({
    this.status = JobDetailStatus.initial,
    this.applyStatus = ApplyStatus.idle,
    this.job,
    this.isOffline = false,
    this.errorMessage,
    this.applyErrorMessage,
  });

  JobDetailState copyWith({
    JobDetailStatus? status,
    ApplyStatus? applyStatus,
    Job? job,
    bool? isOffline,
    String? errorMessage,
    String? applyErrorMessage,
  }) {
    return JobDetailState(
      status: status ?? this.status,
      applyStatus: applyStatus ?? this.applyStatus,
      job: job ?? this.job,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
      applyErrorMessage: applyErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        applyStatus,
        job,
        isOffline,
        errorMessage,
        applyErrorMessage,
      ];
}

