import 'package:equatable/equatable.dart';
import 'job.dart';

class PaginatedJobs extends Equatable {
  final List<Job> jobs;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool isFromCache;

  const PaginatedJobs({
    required this.jobs,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    this.isFromCache = false,
  });

  PaginatedJobs copyWith({
    List<Job>? jobs,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    bool? hasNextPage,
    bool? isFromCache,
  }) {
    return PaginatedJobs(
      jobs: jobs ?? this.jobs,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
        jobs,
        page,
        pageSize,
        totalItems,
        totalPages,
        hasNextPage,
        isFromCache,
      ];
}

