import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String _buildTimeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  // Configurable base URL
  static String? _customBaseUrl;

  static void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    if (_buildTimeBaseUrl.isNotEmpty) {
      return _buildTimeBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    // Android emulator connects to host machine via 10.0.2.2
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }

    // iOS simulator & desktop machines
    return 'http://localhost:3000';
  }

  static String matchesUrl({String country = 'All', int page = 1}) {
    return '$baseUrl/jobs/matches?country=${Uri.encodeComponent(country)}&page=$page';
  }

  static String jobDetailUrl(String id) {
    return '$baseUrl/jobs/$id';
  }

  static String applyJobUrl(String id) {
    return '$baseUrl/jobs/$id/apply';
  }

  static String healthUrl() {
    return '$baseUrl/health';
  }

  static Uri matches({String country = 'All', int page = 1}) {
    return Uri.parse(matchesUrl(country: country, page: page));
  }

  static Uri jobDetail(String id) {
    return Uri.parse(jobDetailUrl(id));
  }

  static Uri applyJob(String id) {
    return Uri.parse(applyJobUrl(id));
  }

  static Uri health() {
    return Uri.parse(healthUrl());
  }
}
