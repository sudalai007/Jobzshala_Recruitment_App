import '../entities/job.dart';
import '../entities/paginated_jobs.dart';

abstract class JobsRepository {
  Future<PaginatedJobs> getJobMatches({
    required String country,
    required int page,
    bool forceRefresh = false,
  });

  Future<Job> getJobDetail(String id);

  Future<bool> applyToJob(String id);

  Future<Set<String>> getAppliedJobIds();

  Stream<bool> get onConnectivityChanged;

  Future<bool> get isConnected;
}

