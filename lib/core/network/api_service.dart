import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  Future<Response> get(String url) async {
    try {
      final response = await dio.get(url);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String url, Map<String, dynamic> data) async {
    try {
      final response = await dio.post(url, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
