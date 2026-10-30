import 'package:equatable/equatable.dart';
import '../../../domain/entities/job.dart';

enum JobMatchesStatus { initial, loading, success, failure }

class JobMatchesState extends Equatable {
  final JobMatchesStatus status;
  final List<Job> jobs;
  final String selectedCountry;
  final int page;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isOffline;
  final bool isFromCache;
  final String? errorMessage;
  final Set<String> appliedJobIds;

  const JobMatchesState({
    this.status = JobMatchesStatus.initial,
    this.jobs = const [],
    this.selectedCountry = 'All',
    this.page = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isOffline = false,
    this.isFromCache = false,
    this.errorMessage,
    this.appliedJobIds = const {},
  });

  JobMatchesState copyWith({
    JobMatchesStatus? status,
    List<Job>? jobs,
    String? selectedCountry,
    int? page,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isOffline,
    bool? isFromCache,
    String? errorMessage,
    Set<String>? appliedJobIds,
  }) {
    return JobMatchesState(
      status: status ?? this.status,
      jobs: jobs ?? this.jobs,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOffline: isOffline ?? this.isOffline,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: errorMessage,
      appliedJobIds: appliedJobIds ?? this.appliedJobIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        jobs,
        selectedCountry,
        page,
        hasReachedMax,
        isLoadingMore,
        isOffline,
        isFromCache,
        errorMessage,
        appliedJobIds,
      ];
}

