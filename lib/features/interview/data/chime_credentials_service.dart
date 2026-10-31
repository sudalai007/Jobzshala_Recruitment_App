import 'package:dio/dio.dart';
import 'chime_credentials.dart';
import 'chime_endpoint_config.dart';

class ChimeCredentialsService {
  ChimeCredentialsService({Dio? dio, String? endpoint, String? accessCode})
    : _dio = dio ?? Dio(),
      _endpoint = endpoint ?? ChimeEndpointConfig.endpoint,
      _accessCode = accessCode ?? ChimeEndpointConfig.accessCode;

  final Dio _dio;
  final String _endpoint;
  final String _accessCode;

  Future<ChimeCredentials> requestJoinInfo({
    required String meetingCode,
    required String name,
  }) async {
    final endpoint = _endpoint.trim();
    if (endpoint.isEmpty) {
      throw StateError(
        'Configure the Jobzshala test endpoint with '
        '--dart-define=CHIME_TEST_ENDPOINT=<base-url> before joining.',
      );
    }
    if (meetingCode.trim().isEmpty) {
      throw StateError(
        'Configure the supplied meeting code with --dart-define=CHIME_MEETING_CODE=<code>.',
      );
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Enter your name before joining.',
      );
    }
    final base = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;
    final headers = <String, String>{'Accept': Headers.jsonContentType};
    if (_accessCode.trim().isNotEmpty) {
      headers['X-Access-Code'] = _accessCode.trim();
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$base/join',
        data: {'meeting_code': meetingCode.trim(), 'name': name.trim()},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: headers,
        ),
      );
      final data = response.data;
      if (data == null) throw const FormatException('Empty join response.');
      return ChimeCredentials.fromJson(data);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw StateError(
        status == null
            ? 'Could not reach the interview endpoint. Check the URL and network connection.'
            : 'Interview endpoint returned HTTP $status.',
      );
    }
  }
}
