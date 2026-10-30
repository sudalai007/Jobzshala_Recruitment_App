import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzshala_assignment/core/error/failures.dart';
import 'package:jobzshala_assignment/features/jobs/domain/entities/benefits.dart';
import 'package:jobzshala_assignment/features/jobs/domain/entities/job.dart';
import 'package:jobzshala_assignment/features/jobs/domain/entities/paginated_jobs.dart';
import 'package:jobzshala_assignment/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:jobzshala_assignment/features/jobs/domain/usecases/apply_to_job.dart';
import 'package:jobzshala_assignment/features/jobs/domain/usecases/get_job_detail.dart';
import 'package:jobzshala_assignment/features/jobs/domain/usecases/get_job_matches.dart';
import 'package:jobzshala_assignment/features/jobs/presentation/bloc/job_detail/job_detail_bloc.dart';
import 'package:jobzshala_assignment/features/jobs/presentation/bloc/job_detail/job_detail_event.dart';
import 'package:jobzshala_assignment/features/jobs/presentation/bloc/job_detail/job_detail_state.dart';
import 'package:jobzshala_assignment/features/jobs/presentation/bloc/job_matches/job_matches_bloc.dart';
import 'package:jobzshala_assignment/features/jobs/presentation/bloc/job_matches/job_matches_event.dart';
import 'package:jobzshala_assignment/features/jobs/presentation/bloc/job_matches/job_matches_state.dart';

class MockJobsRepository implements JobsRepository {
  bool shouldApplyFail = false;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  final testJob = Job(
    id: 'job_1001',
    title: 'Heavy Truck Driver',
    employerDisplay: 'Logistics company, UAE',
    country: 'UAE',
    city: 'Dubai',
    salaryMinAed: 2800,
    salaryMaxAed: 3500,
    matchScore: 92.5,
    matchReason: 'Valid GCC Licence',
    skills: const ['Driving', 'GPS'],
    benefits: const Benefits(accommodation: true, food: true, visa: true),
    description: 'Inter-emirates heavy transport',
    requirements: const ['GCC Heavy License'],
    postedAt: DateTime(2026, 9, 20),
    isApplied: false,
  );

  @override
  Future<bool> applyToJob(String id) async {
    if (shouldApplyFail) {
      throw const ServerFailure('Simulated 500 error from mock API', statusCode: 500);
    }
    return true;
  }

  @override
  Future<Set<String>> getAppliedJobIds() async => {};

  @override
  Future<Job> getJobDetail(String id) async => testJob;

  @override
  Future<PaginatedJobs> getJobMatches({
    required String country,
    required int page,
    bool forceRefresh = false,
  }) async {
    return PaginatedJobs(
      jobs: [testJob],
      page: 1,
      pageSize: 20,
      totalItems: 1,
      totalPages: 1,
      hasNextPage: false,
    );
  }

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
}

void main() {
  late MockJobsRepository mockRepository;
  late GetJobMatches getJobMatches;
  late GetJobDetail getJobDetail;
  late ApplyToJob applyToJob;

  setUp(() {
    mockRepository = MockJobsRepository();
    getJobMatches = GetJobMatches(mockRepository);
    getJobDetail = GetJobDetail(mockRepository);
    applyToJob = ApplyToJob(mockRepository);
  });

  group('JobMatchesBloc Optimistic Apply & Rollback', () {
    test('Optimistic apply marks job as applied immediately in state', () async {
      final bloc = JobMatchesBloc(
        getJobMatchesUseCase: getJobMatches,
        repository: mockRepository,
      );

      // Seed with initial job
      bloc.emit(JobMatchesState(
        status: JobMatchesStatus.success,
        jobs: [mockRepository.testJob],
      ));

      expect(bloc.state.jobs.first.isApplied, isFalse);

      // Dispatch optimistic apply
      bloc.add(const ApplyJobOptimisticEvent('job_1001'));
      await pumpEventQueue();

      expect(bloc.state.jobs.first.isApplied, isTrue);
      expect(bloc.state.appliedJobIds.contains('job_1001'), isTrue);
      await bloc.close();
    });

    test('Rollback reverts job applied state back to false', () async {
      final bloc = JobMatchesBloc(
        getJobMatchesUseCase: getJobMatches,
        repository: mockRepository,
      );

      // Seed with already optimistically applied job
      bloc.emit(JobMatchesState(
        status: JobMatchesStatus.success,
        jobs: [mockRepository.testJob.copyWith(isApplied: true)],
        appliedJobIds: const {'job_1001'},
      ));

      expect(bloc.state.jobs.first.isApplied, isTrue);

      // Dispatch rollback
      bloc.add(const ApplyJobRollbackEvent('job_1001'));
      await pumpEventQueue();

      expect(bloc.state.jobs.first.isApplied, isFalse);
      expect(bloc.state.appliedJobIds.contains('job_1001'), isFalse);
      await bloc.close();
    });
  });

  group('JobDetailBloc Apply Flow (Success & Rollback)', () {
    test('Successful apply transitions from optimisticApplied to confirmed', () async {
      final bloc = JobDetailBloc(
        getJobDetailUseCase: getJobDetail,
        applyToJobUseCase: applyToJob,
        repository: mockRepository,
      );

      bloc.emit(JobDetailState(
        status: JobDetailStatus.success,
        job: mockRepository.testJob,
      ));

      mockRepository.shouldApplyFail = false;

      bloc.add(const ApplyJobDetailEvent('job_1001'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          // 1. Optimistic apply state
          predicate<JobDetailState>((s) =>
              s.applyStatus == ApplyStatus.optimisticApplied &&
              s.job?.isApplied == true),
          // 2. Confirmed state
          predicate<JobDetailState>((s) =>
              s.applyStatus == ApplyStatus.confirmed &&
              s.job?.isApplied == true),
        ]),
      );
      await bloc.close();
    });

    test('Server 500 error causes rollback to failed status and isApplied=false', () async {
      final bloc = JobDetailBloc(
        getJobDetailUseCase: getJobDetail,
        applyToJobUseCase: applyToJob,
        repository: mockRepository,
      );

      bloc.emit(JobDetailState(
        status: JobDetailStatus.success,
        job: mockRepository.testJob,
      ));

      // Simulate API 500 error
      mockRepository.shouldApplyFail = true;

      bloc.add(const ApplyJobDetailEvent('job_1001'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          // 1. Optimistic apply state
          predicate<JobDetailState>((s) =>
              s.applyStatus == ApplyStatus.optimisticApplied &&
              s.job?.isApplied == true),
          // 2. Rolled back state
          predicate<JobDetailState>((s) =>
              s.applyStatus == ApplyStatus.failed &&
              s.job?.isApplied == false &&
              s.applyErrorMessage != null),
        ]),
      );
      await bloc.close();
    });
  });
}
