import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/paginated_jobs.dart';
import '../../domain/repositories/jobs_repository.dart';
import '../datasources/jobs_local_data_source.dart';
import '../datasources/jobs_remote_data_source.dart';
import '../models/job_model.dart';

class JobsRepositoryImpl implements JobsRepository {
  final JobsRemoteDataSource remoteDataSource;
  final JobsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  JobsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Stream<bool> get onConnectivityChanged => networkInfo.onConnectivityChanged;

  @override
  Future<bool> get isConnected => networkInfo.isConnected;

  @override
  Future<Set<String>> getAppliedJobIds() => localDataSource.getAppliedJobIds();

  @override
  Future<PaginatedJobs> getJobMatches({
    required String country,
    required int page,
    bool forceRefresh = false,
  }) async {
    final connected = await networkInfo.isConnected;
    final appliedIds = await localDataSource.getAppliedJobIds();

    if (connected) {
      try {
        final result = await remoteDataSource.getJobMatches(
          country: country,
          page: page,
        );

        // Map jobs and merge local applied states (persisted across restart)
        final List<Job> updatedJobs = result.jobs.map((jobModel) {
          final isApplied = jobModel.isApplied || appliedIds.contains(jobModel.id);
          return jobModel.toModelWithApplied(isApplied);
        }).toList();

        // Sort by match_score descending (highest first as per requirements)
        updatedJobs.sort((a, b) => b.matchScore.compareTo(a.matchScore));

        // Cache page 1 locally for offline viewing
        if (page == 1) {
          final modelList = updatedJobs.map((j) => j as JobModel).toList();
          await localDataSource.cacheJobs(
            country: country,
            jobs: modelList,
            pagination: result.pagination,
          );
        }

        return PaginatedJobs(
          jobs: updatedJobs,
          page: result.pagination.page,
          pageSize: result.pagination.pageSize,
          totalItems: result.pagination.totalItems,
          totalPages: result.pagination.totalPages,
          hasNextPage: result.pagination.hasNextPage,
          isFromCache: false,
        );
      } on ServerException catch (e) {
        // If server 500 error occurs and we have cache, we can fall back to cache on page 1
        if (page == 1) {
          final cached = await localDataSource.getCachedJobs(country: country);
          if (cached != null && cached.jobs.isNotEmpty) {
            final cachedList = cached.jobs.map((j) {
              final isApplied = j.isApplied || appliedIds.contains(j.id);
              return j.toModelWithApplied(isApplied);
            }).toList();
            cachedList.sort((a, b) => b.matchScore.compareTo(a.matchScore));

            return PaginatedJobs(
              jobs: cachedList,
              page: cached.pagination.page,
              pageSize: cached.pagination.pageSize,
              totalItems: cached.pagination.totalItems,
              totalPages: cached.pagination.totalPages,
              hasNextPage: false,
              isFromCache: true,
            );
          }
        }
        throw ServerFailure(e.message, statusCode: e.statusCode);
      } on NetworkException catch (e) {
        // Fall back to cache
        final cached = await localDataSource.getCachedJobs(country: country);
        if (cached != null && cached.jobs.isNotEmpty) {
          final cachedList = cached.jobs.map((j) {
            final isApplied = j.isApplied || appliedIds.contains(j.id);
            return j.toModelWithApplied(isApplied);
          }).toList();
          cachedList.sort((a, b) => b.matchScore.compareTo(a.matchScore));

          return PaginatedJobs(
            jobs: cachedList,
            page: cached.pagination.page,
            pageSize: cached.pagination.pageSize,
            totalItems: cached.pagination.totalItems,
            totalPages: cached.pagination.totalPages,
            hasNextPage: false,
            isFromCache: true,
          );
        }
        throw NetworkFailure(e.message);
      }
    } else {
      // Offline mode: load from cache
      final cached = await localDataSource.getCachedJobs(country: country);
      if (cached != null && cached.jobs.isNotEmpty) {
        final cachedList = cached.jobs.map((j) {
          final isApplied = j.isApplied || appliedIds.contains(j.id);
          return j.toModelWithApplied(isApplied);
        }).toList();
        cachedList.sort((a, b) => b.matchScore.compareTo(a.matchScore));

        return PaginatedJobs(
          jobs: cachedList,
          page: 1,
          pageSize: cachedList.length,
          totalItems: cachedList.length,
          totalPages: 1,
          hasNextPage: false,
          isFromCache: true,
        );
      }
      throw const NetworkFailure(
        "You are offline and no saved jobs were found. Please connect to the internet to load jobs.",
      );
    }
  }

  @override
  Future<Job> getJobDetail(String id) async {
    final connected = await networkInfo.isConnected;
    final appliedIds = await localDataSource.getAppliedJobIds();

    if (connected) {
      try {
        final jobModel = await remoteDataSource.getJobDetail(id);
        final isApplied = jobModel.isApplied || appliedIds.contains(id);
        final updated = jobModel.toModelWithApplied(isApplied);
        await localDataSource.cacheJobDetail(updated);
        return updated;
      } on ServerException catch (e) {
        final cached = await localDataSource.getCachedJobDetail(id);
        if (cached != null) {
          return cached.toModelWithApplied(cached.isApplied || appliedIds.contains(id));
        }
        throw ServerFailure(e.message, statusCode: e.statusCode);
      } catch (e) {
        final cached = await localDataSource.getCachedJobDetail(id);
        if (cached != null) {
          return cached.toModelWithApplied(cached.isApplied || appliedIds.contains(id));
        }
        throw NetworkFailure(e.toString());
      }
    } else {
      final cached = await localDataSource.getCachedJobDetail(id);
      if (cached != null) {
        return cached.toModelWithApplied(cached.isApplied || appliedIds.contains(id));
      }
      throw const NetworkFailure("You're offline and job details are not cached.");
    }
  }

  @override
  Future<bool> applyToJob(String id) async {
    final connected = await networkInfo.isConnected;
    if (!connected) {
      throw const NetworkFailure('Apply is disabled while offline. Please connect to internet.');
    }

    try {
      final success = await remoteDataSource.applyToJob(id);
      if (success) {
        await localDataSource.saveAppliedJobId(id);
      }
      return success;
    } on ServerException catch (e) {
      // Roll back
      await localDataSource.removeAppliedJobId(id);
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      await localDataSource.removeAppliedJobId(id);
      throw NetworkFailure(e.toString());
    }
  }
}

