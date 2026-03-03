import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_guard.dart';
import 'auth_storage.dart';

/// Base URL for the Serbisyo backend (no trailing slash).
/// Edit mobile/.env and set API_BASE_URL to change it easily.
String get apiBaseUrl {
  var url = dotenv.env['API_BASE_URL']?.trim() ?? 'http://localhost:3000';
  if (url.isEmpty) url = 'http://localhost:3000';
  // On Android emulator, localhost refers to the emulator; use 10.0.2.2 to reach host.
  if (url.contains('localhost') && Platform.isAndroid) {
    url = url.replaceFirst('localhost', '10.0.2.2');
  }
  return url;
}

const String _apiPrefix = '/api';

Dio createApiClient({String? token}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '$apiBaseUrl$_apiPrefix',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final t = token ?? await getToken();
        if (t != null && t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        return handler.next(options);
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              error: 'Cannot reach server at $apiBaseUrl. '
                  'Make sure the backend is running (npm run dev in backend folder) '
                  'and the app is using the correct API URL.',
              type: error.type,
            ),
          );
        }
        if (error.response?.statusCode == 401) {
          await AuthGuard.requireLogin(
            clearSession: true,
            message: 'Session expired. Please log in again.',
          );
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: 'Session expired. Please log in again.',
              type: DioExceptionType.badResponse,
            ),
          );
        }
        return handler.next(error);
      },
    ),
  );
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: false,
      responseHeader: false,
    ),
  );
  return dio;
}
