import 'dart:io';
import 'package:http/http.dart' as http;
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  static Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on SocketException {
      throw NetworkFailure('No internet connection');
    } on HttpException {
      throw NetworkFailure('Network error occurred');
    } on FormatException {
      throw DataFailure('Invalid data format received');
    } on ApiException catch (e) {
      throw ApiFailure(e.message);
    } on AuthenticationException catch (e) {
      throw AuthenticationFailure(e.message);
    } catch (e) {
      throw UnknownFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  static Future<T> handleApiCallWithRetry<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await handleApiCall(apiCall);
      } on NetworkFailure catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts); // Exponential backoff
      } catch (e) {
        rethrow; // Don't retry non-network errors
      }
    }
    
    throw NetworkFailure('Max retry attempts exceeded');
  }

  static String getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'Please check your internet connection and try again';
      case AuthenticationFailure:
        return 'Authentication failed. Please log in again';
      case ApiFailure:
        return 'Unable to fetch data. Please try again later';
      case DataFailure:
        return 'Invalid data received. Please try again';
      case CacheFailure:
        return 'Unable to load cached data';
      default:
        return 'Something went wrong. Please try again';
    }
  }

  static bool isRetryableError(Failure failure) {
    return failure is NetworkFailure || failure is ApiFailure;
  }
}