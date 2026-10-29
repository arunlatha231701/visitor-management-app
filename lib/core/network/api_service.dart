import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:visitor_management_app/core/config/app_config.dart';
import 'package:visitor_management_app/core/errors/app_exception.dart';

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  void _ensureConfigured() {
    if (AppConfig.apiBaseUrl.trim().isEmpty) {
      throw const AppException(
        'API base URL is missing. Please configure AppConfig.',
      );
    }
  }

  Future<dynamic> get(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
      }) async {
    _ensureConfigured();

    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> post(
      String endpoint, {
        Object? data,
      }) async {
    _ensureConfigured();

    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: data,
      );

      return response.data;
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> put(
      String endpoint, {
        Object? data,
      }) async {
    _ensureConfigured();

    try {
      final response = await _dio.put<dynamic>(
        endpoint,
        data: data,
      );

      return response.data;
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> patch(
      String endpoint, {
        Object? data,
      }) async {
    _ensureConfigured();

    try {
      final response = await _dio.patch<dynamic>(
        endpoint,
        data: data,
      );

      return response.data;
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> delete(
      String endpoint, {
        Object? data,
      }) async {
    _ensureConfigured();

    try {
      final response = await _dio.delete<dynamic>(
        endpoint,
        data: data,
      );

      return response.data;
    } catch (error) {
      throw _mapError(error);
    }
  }
}

AppException _mapError(Object error) {
  if (error is AppException) {
    return error;
  }

  if (error is DioException) {
    if (kDebugMode) {
      debugPrint('API error type: ${error.type}');
      debugPrint(
        'Request: ${error.requestOptions.method} '
            '${error.requestOptions.uri}',
      );
      debugPrint('HTTP status: ${error.response?.statusCode}');
    }

    final statusCode = error.response?.statusCode;

    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return const AppException(
            'Invalid request. Please check the entered details.',
          );
        case 401:
          return const AppException(
            'Authentication is required for this request.',
          );
        case 403:
          return const AppException(
            'Access denied by the server.',
          );
        case 404:
          return const AppException(
            'The requested record or endpoint was not found.',
          );
        case 408:
          return const AppException(
            'The request timed out. Please try again.',
          );
        case 429:
          return const AppException(
            'Too many requests. Please wait and try again.',
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return AppException(
            'Server error ($statusCode). Please try again later.',
          );
        default:
          return AppException(
            'Request failed (HTTP $statusCode).',
          );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const AppException(
          'Connection timed out. Check your connection and try again.',
        );

      case DioExceptionType.sendTimeout:
        return const AppException(
          'Sending the request timed out.',
        );

      case DioExceptionType.receiveTimeout:
        return const AppException(
          'The server took too long to respond.',
        );

      case DioExceptionType.connectionError:
        return const AppException(
          'Cannot connect to the server. Check your internet '
              'connection and API URL.',
        );

      case DioExceptionType.badCertificate:
        return const AppException(
          'A secure connection could not be established.',
        );

      case DioExceptionType.cancel:
        return const AppException(
          'The request was cancelled.',
        );

      case DioExceptionType.badResponse:
        return const AppException(
          'The server returned an invalid response.',
        );

      case DioExceptionType.transformTimeout:
        return const AppException(
          'The response took too long to process. Please try again.',
        );

      case DioExceptionType.unknown:
        if (kDebugMode) {
          debugPrint('Underlying API error: ${error.error}');
        }

        return const AppException(
          'A network error occurred. Please check your connection '
              'and try again.',
        );
    }
  }

  if (kDebugMode) {
    debugPrint('Unexpected API error: $error');
  }

  return const AppException(
    'Something went wrong. Please try again.',
  );
}