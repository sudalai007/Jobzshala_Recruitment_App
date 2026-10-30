import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jobzshala_assignment/core/error/failures.dart';
import 'package:jobzshala_assignment/features/jobs/domain/entities/job.dart';
import 'package:jobzshala_assignment/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:jobzshala_assignment/features/jobs/domain/usecases/get_job_matches.dart';
import 'job_matches_event.dart';
import 'job_matches_state.dart';

class JobMatchesBloc extends Bloc<JobMatchesEvent, JobMatchesState> {
  final GetJobMatches getJobMatchesUseCase;
  final JobsRepository repository;
  StreamSubscription<bool>? _connectivitySubscription;

  JobMatchesBloc({required this.getJobMatchesUseCase, required this.repository})
    : super(const JobMatchesState()) {
    on<LoadJobMatchesEvent>(_onLoadJobMatches);
    on<LoadMoreJobMatchesEvent>(_onLoadMoreJobMatches);
    on<FilterCountryChangedEvent>(_onFilterCountryChanged);
    on<ApplyJobOptimisticEvent>(_onApplyJobOptimistic);
    on<ApplyJobRollbackEvent>(_onApplyJobRollback);
    on<ConnectivityChangedEvent>(_onConnectivityChanged);

    // Listen to network changes
    _connectivitySubscription = repository.onConnectivityChanged.listen((
      isConnected,
    ) {
      add(ConnectivityChangedEvent(isConnected));
    });

    // Check initial connectivity
    repository.isConnected.then((connected) {
      add(ConnectivityChangedEvent(connected));
    });
  }

  Future<void> _onLoadJobMatches(
    LoadJobMatchesEvent event,
    Emitter<JobMatchesState> emit,
  ) async {
    final country = event.country ?? state.selectedCountry;
    final isRefresh = event.forceRefresh;

    if (!isRefresh && state.status != JobMatchesStatus.success) {
      emit(
        state.copyWith(
          status: JobMatchesStatus.loading,
          selectedCountry: country,
        ),
      );
    }

    try {
      final appliedIds = await repository.getAppliedJobIds();
      final result = await getJobMatchesUseCase(
        country: country,
        page: 1,
        forceRefresh: isRefresh,
      );

      print("*******Result: $result");

      final isOffline =
          await repository.isConnected == false || result.isFromCache;

      emit(
        state.copyWith(
          status: JobMatchesStatus.success,
          jobs: result.jobs,
          selectedCountry: country,
          page: 1,
          hasReachedMax: !result.hasNextPage,
          isLoadingMore: false,
          isOffline: isOffline,
          isFromCache: result.isFromCache,
          appliedJobIds: appliedIds,
          errorMessage: null,
        ),
      );
    } on Failure catch (failure) {
      print("**********Failure: $failure");
      emit(
        state.copyWith(
          status: state.jobs.isEmpty
              ? JobMatchesStatus.failure
              : JobMatchesStatus.success,
          errorMessage: failure.message,
          isOffline: failure is NetworkFailure,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: state.jobs.isEmpty
              ? JobMatchesStatus.failure
              : JobMatchesStatus.success,
          errorMessage: e.toString(),
          isLoadingMore: false,
        ),
      );
    }
  }

  Future<void> _onLoadMoreJobMatches(
    LoadMoreJobMatchesEvent event,
    Emitter<JobMatchesState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedMax || state.isOffline) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.page + 1;
      final result = await getJobMatchesUseCase(
        country: state.selectedCountry,
        page: nextPage,
      );

      final existingIds = state.jobs.map((j) => j.id).toSet();
      final newUniqueJobs = result.jobs
          .where((j) => !existingIds.contains(j.id))
          .toList();
      final combined = List<Job>.from(state.jobs)..addAll(newUniqueJobs);

      // Maintain sort order by match score
      combined.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      emit(
        state.copyWith(
          jobs: combined,
          page: nextPage,
          hasReachedMax: !result.hasNextPage,
          isLoadingMore: false,
          isFromCache: result.isFromCache,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onFilterCountryChanged(
    FilterCountryChangedEvent event,
    Emitter<JobMatchesState> emit,
  ) {
    if (state.selectedCountry == event.country) return;
    emit(
      state.copyWith(
        selectedCountry: event.country,
        jobs: [],
        status: JobMatchesStatus.loading,
      ),
    );
    add(LoadJobMatchesEvent(country: event.country));
  }

  void _onApplyJobOptimistic(
    ApplyJobOptimisticEvent event,
    Emitter<JobMatchesState> emit,
  ) {
    final updatedAppliedIds = Set<String>.from(state.appliedJobIds)
      ..add(event.jobId);
    final updatedJobs = state.jobs.map((job) {
      if (job.id == event.jobId) {
        return job.copyWith(isApplied: true);
      }
      return job;
    }).toList();

    emit(state.copyWith(jobs: updatedJobs, appliedJobIds: updatedAppliedIds));
  }

  void _onApplyJobRollback(
    ApplyJobRollbackEvent event,
    Emitter<JobMatchesState> emit,
  ) {
    final updatedAppliedIds = Set<String>.from(state.appliedJobIds)
      ..remove(event.jobId);
    final updatedJobs = state.jobs.map((job) {
      if (job.id == event.jobId) {
        return job.copyWith(isApplied: false);
      }
      return job;
    }).toList();

    emit(state.copyWith(jobs: updatedJobs, appliedJobIds: updatedAppliedIds));
  }

  void _onConnectivityChanged(
    ConnectivityChangedEvent event,
    Emitter<JobMatchesState> emit,
  ) {
    final wasOffline = state.isOffline;
    final isNowOffline = !event.isConnected;

    emit(state.copyWith(isOffline: isNowOffline));

    // If returning online and list was empty or failed, reload automatically
    if (wasOffline &&
        !isNowOffline &&
        (state.jobs.isEmpty || state.status == JobMatchesStatus.failure)) {
      add(const LoadJobMatchesEvent(forceRefresh: true));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
