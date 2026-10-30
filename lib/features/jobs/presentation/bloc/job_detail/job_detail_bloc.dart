import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jobzshala_assignment/core/error/failures.dart';
import 'package:jobzshala_assignment/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:jobzshala_assignment/features/jobs/domain/usecases/apply_to_job.dart';
import 'package:jobzshala_assignment/features/jobs/domain/usecases/get_job_detail.dart';
import 'job_detail_event.dart';
import 'job_detail_state.dart';

class JobDetailBloc extends Bloc<JobDetailEvent, JobDetailState> {
  final GetJobDetail getJobDetailUseCase;
  final ApplyToJob applyToJobUseCase;
  final JobsRepository repository;

  JobDetailBloc({
    required this.getJobDetailUseCase,
    required this.applyToJobUseCase,
    required this.repository,
  }) : super(const JobDetailState()) {
    on<LoadJobDetailEvent>(_onLoadJobDetail);
    on<ApplyJobDetailEvent>(_onApplyJobDetail);
  }

  Future<void> _onLoadJobDetail(
    LoadJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    emit(state.copyWith(status: JobDetailStatus.loading, applyStatus: ApplyStatus.idle));

    final isOffline = await repository.isConnected == false;

    try {
      final job = await getJobDetailUseCase(event.jobId);
      emit(state.copyWith(
        status: JobDetailStatus.success,
        job: job,
        isOffline: isOffline,
        errorMessage: null,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: JobDetailStatus.failure,
        errorMessage: f.message,
        isOffline: f is NetworkFailure,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JobDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onApplyJobDetail(
    ApplyJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    final currentJob = state.job;
    if (currentJob == null || currentJob.isApplied) return;

    final isConnected = await repository.isConnected;
    if (!isConnected) {
      emit(state.copyWith(
        applyStatus: ApplyStatus.failed,
        applyErrorMessage: 'Offline — application requires an active internet connection.',
      ));
      return;
    }

    // 1. Optimistic Update: immediately mark as applied in UI
    emit(state.copyWith(
      applyStatus: ApplyStatus.optimisticApplied,
      job: currentJob.copyWith(isApplied: true),
      applyErrorMessage: null,
    ));

    try {
      // 2. Network call to API
      final success = await applyToJobUseCase(event.jobId);
      if (success) {
        emit(state.copyWith(
          applyStatus: ApplyStatus.confirmed,
          job: currentJob.copyWith(isApplied: true),
        ));
      } else {
        // Rollback
        emit(state.copyWith(
          applyStatus: ApplyStatus.failed,
          job: currentJob.copyWith(isApplied: false),
          applyErrorMessage: 'Server rejected application. Reverting state.',
        ));
      }
    } catch (e) {
      // Rollback on any error (such as HTTP 500 error simulated by mock server)
      emit(state.copyWith(
        applyStatus: ApplyStatus.failed,
        job: currentJob.copyWith(isApplied: false),
        applyErrorMessage: e is Failure ? e.message : 'Application failed. Rolled back state.',
      ));
    }
  }
}
