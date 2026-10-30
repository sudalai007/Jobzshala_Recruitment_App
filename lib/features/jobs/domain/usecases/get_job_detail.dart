import '../entities/job.dart';
import '../repositories/jobs_repository.dart';

class GetJobDetail {
  final JobsRepository repository;

  GetJobDetail(this.repository);

  Future<Job> call(String id) {
    return repository.getJobDetail(id);
  }
}

