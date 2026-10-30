import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:jobzshala_assignment/core/network/api_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/job_model.dart';
import '../models/pagination_model.dart';

abstract class JobsRemoteDataSource {
  Future<({List<JobModel> jobs, PaginationModel pagination})> getJobMatches({
    required String country,
    required int page,
  });

  Future<JobModel> getJobDetail(String id);

  Future<bool> applyToJob(String id);
}

class JobsRemoteDataSourceImpl implements JobsRemoteDataSource {
  final ApiClient apiClient;

  JobsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<({List<JobModel> jobs, PaginationModel pagination})> getJobMatches({
    required String country,
    required int page,
  }) async {
    final url = ApiEndpoints.matchesUrl(country: country, page: page);

    try {
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : (response.data is String
                  ? json.decode(response.data as String) as Map<String, dynamic>
                  : <String, dynamic>{});
        final List<dynamic> rawList = data['data'] as List<dynamic>? ?? [];

        print("********RawList: $rawList");
        final jobs = rawList
            .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
            .toList();
        final pagination = PaginationModel.fromJson(
          data['pagination'] as Map<String, dynamic>? ?? {},
        );
        return (jobs: jobs, pagination: pagination);
      } else {
        throw ServerException(
          message: 'Server responded with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: 'Server error: ${e.response?.statusMessage ?? e.message}',
          statusCode: e.response?.statusCode,
        );
      } else {
        throw NetworkException(
          message:
              'Network error: ${e.message ?? 'Failed to communicate with API'}',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<JobModel> getJobDetail(String id) async {
    final url = ApiEndpoints.jobDetailUrl(id);

    try {
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : (response.data is String
                  ? json.decode(response.data as String) as Map<String, dynamic>
                  : <String, dynamic>{});
        final jobData = data['data'] as Map<String, dynamic>;
        return JobModel.fromJson(jobData);
      } else if (response.statusCode == 404) {
        throw ServerException(message: 'Job not found', statusCode: 404);
      } else {
        throw ServerException(
          message: 'Failed to fetch job detail (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.statusCode == 404
              ? 'Job not found'
              : 'Server error (${e.response?.statusCode}): ${e.response?.statusMessage}',
          statusCode: e.response?.statusCode,
        );
      } else {
        throw NetworkException(
          message: 'Network error fetching job detail: ${e.message}',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(message: 'Network error fetching job detail: $e');
    }
  }

  @override
  Future<bool> applyToJob(String id) async {
    final url = ApiEndpoints.applyJobUrl(id);

    try {
      final response = await apiClient.post(url, {});

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : (response.data is String
                  ? json.decode(response.data as String) as Map<String, dynamic>
                  : <String, dynamic>{});
        return data['status'] == 'APPLIED';
      } else {
        throw ServerException(
          message: 'Apply call failed on server (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: 'Apply failed on server (${e.response?.statusCode})',
          statusCode: e.response?.statusCode,
        );
      } else {
        throw NetworkException(
          message: 'Network error submitting application: ${e.message}',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Network error submitting application: $e',
      );
    }
  }
}
