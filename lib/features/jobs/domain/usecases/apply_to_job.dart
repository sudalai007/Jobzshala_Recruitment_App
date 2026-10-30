import '../repositories/jobs_repository.dart';

class ApplyToJob {
  final JobsRepository repository;

  ApplyToJob(this.repository);

  Future<bool> call(String id) {
    return repository.applyToJob(id);
  }
}

