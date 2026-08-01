import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.fromDioError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = "Connection timeout. Please check your internet.";
        break;
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        switch (code) {
          case 400: message = "Invalid request. Please check your input."; break;
          case 401: message = "Session expired. Please log in again."; break;
          case 403: message = "Access denied. Insufficient permissions."; break;
          case 404: message = "Resource not found on server."; break;
          case 415: message = "Server rejected data format. (Missing JSON header)"; break;
          case 429: message = "Too many requests. Please slow down."; break;
          case 500: message = "Server error. Please try again later."; break;
          default: message = "Unexpected error occurred ($code).";
        }
        break;
      case DioExceptionType.cancel:
        message = "Request was cancelled.";
        break;
      case DioExceptionType.connectionError:
        message = "No internet connection detected.";
        break;
      default:
        message = "Something went wrong. Please try again.";
    }
    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      data: error.response?.data,
    );
  }

  @override
  String toString() => message;
}
