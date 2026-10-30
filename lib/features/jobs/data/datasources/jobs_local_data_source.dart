import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/job_model.dart';
import '../models/pagination_model.dart';

abstract class JobsLocalDataSource {
  Future<Set<String>> getAppliedJobIds();
  Future<void> saveAppliedJobId(String id);
  Future<void> removeAppliedJobId(String id);

  Future<void> cacheJobs({
    required String country,
    required List<JobModel> jobs,
    required PaginationModel pagination,
  });

  Future<({List<JobModel> jobs, PaginationModel pagination})?> getCachedJobs({
    required String country,
  });

  Future<void> cacheJobDetail(JobModel job);
  Future<JobModel?> getCachedJobDetail(String id);
}

class JobsLocalDataSourceImpl implements JobsLocalDataSource {
  static const String _prefKeyAppliedIds = 'jobzshala_applied_job_ids';
  static const String _prefPrefixCachedJobs = 'jobzshala_cached_jobs_';
  static const String _prefPrefixCachedDetail = 'jobzshala_cached_detail_';

  final SharedPreferences sharedPreferences;

  JobsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<Set<String>> getAppliedJobIds() async {
    try {
      final list = sharedPreferences.getStringList(_prefKeyAppliedIds) ?? [];
      return list.toSet();
    } catch (e) {
      throw CacheException(message: 'Error reading applied jobs: $e');
    }
  }

  @override
  Future<void> saveAppliedJobId(String id) async {
    try {
      final current = sharedPreferences.getStringList(_prefKeyAppliedIds) ?? [];
      if (!current.contains(id)) {
        final updated = List<String>.from(current)..add(id);
        await sharedPreferences.setStringList(_prefKeyAppliedIds, updated);
      }
    } catch (e) {
      throw CacheException(message: 'Error saving applied job ID: $e');
    }
  }

  @override
  Future<void> removeAppliedJobId(String id) async {
    try {
      final current = sharedPreferences.getStringList(_prefKeyAppliedIds) ?? [];
      if (current.contains(id)) {
        final updated = List<String>.from(current)..remove(id);
        await sharedPreferences.setStringList(_prefKeyAppliedIds, updated);
      }
    } catch (e) {
      throw CacheException(message: 'Error removing applied job ID: $e');
    }
  }

  @override
  Future<void> cacheJobs({
    required String country,
    required List<JobModel> jobs,
    required PaginationModel pagination,
  }) async {
    try {
      final key = '$_prefPrefixCachedJobs$country';
      final payload = json.encode({
        'jobs': jobs.map((j) => j.toJson()).toList(),
        'pagination': pagination.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
      });
      await sharedPreferences.setString(key, payload);
    } catch (e) {
      // Local caching failure shouldn't crash app
    }
  }

  @override
  Future<({List<JobModel> jobs, PaginationModel pagination})?> getCachedJobs({
    required String country,
  }) async {
    try {
      final key = '$_prefPrefixCachedJobs$country';
      String? jsonStr = sharedPreferences.getString(key);

      // If specific country not cached, try 'All'
      if (jsonStr == null && country != 'All') {
        final allKey = '${_prefPrefixCachedJobs}All';
        jsonStr = sharedPreferences.getString(allKey);
        if (jsonStr != null) {
          final decoded = json.decode(jsonStr) as Map<String, dynamic>;
          final rawJobs = decoded['jobs'] as List<dynamic>? ?? [];
          final allJobs = rawJobs.map((j) => JobModel.fromJson(j as Map<String, dynamic>)).toList();
          final filtered = allJobs.where((j) => j.country.toLowerCase() == country.toLowerCase()).toList();
          return (
            jobs: filtered,
            pagination: PaginationModel(
              page: 1,
              pageSize: filtered.length,
              totalItems: filtered.length,
              totalPages: 1,
              hasNextPage: false,
            ),
          );
        }
      }

      if (jsonStr == null) return null;

      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final rawJobs = decoded['jobs'] as List<dynamic>? ?? [];
      final jobs = rawJobs.map((j) => JobModel.fromJson(j as Map<String, dynamic>)).toList();
      final pagination = PaginationModel.fromJson(decoded['pagination'] as Map<String, dynamic>? ?? {});

      return (jobs: jobs, pagination: pagination);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheJobDetail(JobModel job) async {
    try {
      final key = '$_prefPrefixCachedDetail${job.id}';
      await sharedPreferences.setString(key, json.encode(job.toJson()));
    } catch (_) {}
  }

  @override
  Future<JobModel?> getCachedJobDetail(String id) async {
    try {
      final key = '$_prefPrefixCachedDetail$id';
      final jsonStr = sharedPreferences.getString(key);
      if (jsonStr == null) return null;
      return JobModel.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

