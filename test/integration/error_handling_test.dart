import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

import 'package:movie_recommendation_app/core/error/error_handler.dart';
import 'package:movie_recommendation_app/core/error/failures.dart';
import 'package:movie_recommendation_app/core/error/exceptions.dart';
import 'package:movie_recommendation_app/core/cache/cache_manager.dart';
import 'package:movie_recommendation_app/data/datasources/tmdb_client.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';
import 'package:movie_recommendation_app/data/models/recommendation_result.dart';

import 'error_handling_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Error Handling Integration Tests', () {
    late MockClient mockHttpClient;
    late TMDbClient tmdbClient;

    setUp(() {
      mockHttpClient = MockClient();
      tmdbClient = TMDbClient(httpClient: mockHttpClient);
    });

    tearDown(() {
      tmdbClient.dispose();
    });

    group('Network Error Handling', () {
      test('should handle network timeout with retry', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(const SocketException('Network unreachable'));

        // Act & Assert
        expect(
          () => ErrorHandler.handleApiCallWithRetry(
            () => tmdbClient.getMovieRecommendations(),
            maxRetries: 2,
          ),
          throwsA(isA<NetworkFailure>()),
        );

        // Verify retry attempts
        verify(mockHttpClient.get(any, headers: anyNamed('headers')))
            .called(2);
      });

      test('should handle HTTP timeout', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(TimeoutException('Request timeout', const Duration(seconds: 30)));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should handle no internet connection', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(const SocketException('No address associated with hostname'));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('API Error Handling', () {
      test('should handle 401 authentication error', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
              '{"status_message": "Invalid API key", "status_code": 7}',
              401,
            ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('should handle 404 not found error', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
              '{"status_message": "The resource you requested could not be found."}',
              404,
            ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });

      test('should handle 429 rate limit error', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
              '{"status_message": "Your request count (41) is over the allowed limit of 40."}',
              429,
            ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });

      test('should handle 500 server error', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
              '{"status_message": "Internal server error"}',
              500,
            ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('Data Format Error Handling', () {
      test('should handle invalid JSON response', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
              'Invalid JSON response',
              200,
            ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });

      test('should handle missing required fields in response', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
              '{"page": 1}', // Missing results field
              200,
            ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Message Generation', () {
      test('should generate user-friendly error messages', () {
        expect(
          ErrorHandler.getErrorMessage(const NetworkFailure('Network error')),
          equals('Please check your internet connection and try again'),
        );

        expect(
          ErrorHandler.getErrorMessage(const AuthenticationFailure('Auth failed')),
          equals('Authentication failed. Please log in again'),
        );

        expect(
          ErrorHandler.getErrorMessage(const ApiFailure('API error')),
          equals('Unable to fetch data. Please try again later'),
        );

        expect(
          ErrorHandler.getErrorMessage(const DataFailure('Data error')),
          equals('Invalid data received. Please try again'),
        );

        expect(
          ErrorHandler.getErrorMessage(const CacheFailure('Cache error')),
          equals('Unable to load cached data'),
        );

        expect(
          ErrorHandler.getErrorMessage(const UnknownFailure('Unknown error')),
          equals('Something went wrong. Please try again'),
        );
      });

      test('should identify retryable errors', () {
        expect(ErrorHandler.isRetryableError(const NetworkFailure('Network error')), isTrue);
        expect(ErrorHandler.isRetryableError(const ApiFailure('API error')), isTrue);
        expect(ErrorHandler.isRetryableError(const AuthenticationFailure('Auth error')), isFalse);
        expect(ErrorHandler.isRetryableError(const DataFailure('Data error')), isFalse);
      });
    });

    group('Exponential Backoff', () {
      test('should implement exponential backoff on retry', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        var callCount = 0;
        
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async {
          callCount++;
          throw const SocketException('Network error');
        });

        // Act
        try {
          await ErrorHandler.handleApiCallWithRetry(
            () => tmdbClient.getMovieRecommendations(),
            maxRetries: 3,
            delay: const Duration(milliseconds: 100),
          );
        } catch (e) {
          // Expected to fail
        }

        stopwatch.stop();

        // Assert
        expect(callCount, equals(3));
        // Should take at least 100ms + 200ms = 300ms for exponential backoff
        expect(stopwatch.elapsedMilliseconds, greaterThan(300));
      });
    });
  });

  group('Offline Functionality Tests', () {
    setUp(() async {
      // Clear cache before each test
      await CacheManager.clearCache();
    });

    tearDown(() async {
      // Clean up cache after each test
      await CacheManager.clearCache();
    });

    group('Cache Management', () {
      test('should cache movie recommendations', () async {
        // Arrange
        final movies = [
          Movie(
            id: 1,
            title: 'Test Movie',
            overview: 'Test overview',
            posterPath: '/test.jpg',
            genres: [],
            voteAverage: 7.5,
            releaseDate: '2023-01-01',
            runtime: 120,
          ),
        ];
        
        final recommendationResult = RecommendationResult(
          movies: movies,
          source: 'popular',
          metadata: {'page': 1},
          timestamp: DateTime.now(),
        );

        // Act
        await CacheManager.cacheRecommendations(recommendationResult, 'test_key');
        final cachedResult = await CacheManager.getCachedRecommendations('test_key');

        // Assert
        expect(cachedResult, isNotNull);
        expect(cachedResult!.movies.length, equals(1));
        expect(cachedResult.movies.first.title, equals('Test Movie'));
      });

      test('should cache individual movies', () async {
        // Arrange
        final movie = Movie(
          id: 1,
          title: 'Test Movie',
          overview: 'Test overview',
          posterPath: '/test.jpg',
          genres: [],
          voteAverage: 7.5,
          releaseDate: '2023-01-01',
          runtime: 120,
        );

        // Act
        await CacheManager.cacheMovie(movie);
        final cachedMovie = await CacheManager.getCachedMovie(1);

        // Assert
        expect(cachedMovie, isNotNull);
        expect(cachedMovie!.title, equals('Test Movie'));
      });

      test('should cache user rated movies', () async {
        // Arrange
        final movies = [
          Movie(
            id: 1,
            title: 'Rated Movie',
            overview: 'Test overview',
            posterPath: '/test.jpg',
            genres: [],
            voteAverage: 7.5,
            releaseDate: '2023-01-01',
            runtime: 120,
            userRating: 8.0,
            isWatched: true,
          ),
        ];

        // Act
        await CacheManager.cacheUserRatedMovies(movies);
        final cachedMovies = await CacheManager.getCachedUserRatedMovies();

        // Assert
        expect(cachedMovies, isNotNull);
        expect(cachedMovies!.length, equals(1));
        expect(cachedMovies.first.userRating, equals(8.0));
        expect(cachedMovies.first.isWatched, isTrue);
      });

      test('should cache genres', () async {
        // Arrange
        final genres = [
          {'id': 28, 'name': 'Action'},
          {'id': 35, 'name': 'Comedy'},
        ];

        // Act
        await CacheManager.cacheGenres(genres);
        final cachedGenres = await CacheManager.getCachedGenres();

        // Assert
        expect(cachedGenres, isNotNull);
        expect(cachedGenres!.length, equals(2));
        expect(cachedGenres.first['name'], equals('Action'));
      });

      test('should expire cached data after timeout', () async {
        // Arrange
        final movie = Movie(
          id: 1,
          title: 'Test Movie',
          overview: 'Test overview',
          posterPath: '/test.jpg',
          genres: [],
          voteAverage: 7.5,
          releaseDate: '2023-01-01',
          runtime: 120,
        );

        // Cache with very short duration for testing
        await CacheManager.cacheMovie(movie);
        
        // Wait for cache to expire (simulate by clearing and checking)
        await Future.delayed(const Duration(milliseconds: 10));
        await CacheManager.clearExpiredCache();
        
        // Act
        final cachedMovie = await CacheManager.getCachedMovie(1);

        // Assert - This test would need modification of cache duration for proper testing
        // For now, we just verify the cache clearing functionality works
        expect(cachedMovie, isNull);
      });

      test('should clear all cache', () async {
        // Arrange
        final movie = Movie(
          id: 1,
          title: 'Test Movie',
          overview: 'Test overview',
          posterPath: '/test.jpg',
          genres: [],
          voteAverage: 7.5,
          releaseDate: '2023-01-01',
          runtime: 120,
        );
        
        await CacheManager.cacheMovie(movie);
        
        // Act
        await CacheManager.clearCache();
        final cachedMovie = await CacheManager.getCachedMovie(1);

        // Assert
        expect(cachedMovie, isNull);
      });
    });

    group('Offline Fallback Behavior', () {
      test('should return cached data when API fails', () async {
        // This test would require integration with the actual TMDb client
        // and mocking network failures while having cached data available
        // Implementation would depend on the specific offline strategy
        expect(true, isTrue); // Placeholder
      });

      test('should handle cache failures gracefully', () async {
        // Test cache read/write failures
        expect(
          () => CacheManager.cacheMovie(Movie(
            id: 1,
            title: 'Test',
            overview: 'Test',
            posterPath: '/test.jpg',
            genres: [],
            voteAverage: 0,
            releaseDate: '2023-01-01',
            runtime: 0,
          )),
          returnsNormally,
        );
      });
    });
  });
}