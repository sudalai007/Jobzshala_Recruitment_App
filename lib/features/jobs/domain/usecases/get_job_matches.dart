import '../entities/paginated_jobs.dart';
import '../repositories/jobs_repository.dart';

class GetJobMatches {
  final JobsRepository repository;

  GetJobMatches(this.repository);

  Future<PaginatedJobs> call({
    required String country,
    required int page,
    bool forceRefresh = false,
  }) {
    return repository.getJobMatches(
      country: country,
      page: page,
      forceRefresh: forceRefresh,
    );
  }
}

