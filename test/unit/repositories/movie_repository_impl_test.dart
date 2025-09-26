import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:movie_recommendation_app/core/error/exceptions.dart';
import 'package:movie_recommendation_app/core/error/failures.dart';
import 'package:movie_recommendation_app/core/utils/result.dart';
import 'package:movie_recommendation_app/data/datasources/tmdb_client.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';
import 'package:movie_recommendation_app/data/repositories/movie_repository_impl.dart';

import 'movie_repository_impl_test.mocks.dart';

@GenerateMocks([TMDbClient])
void main() {
  late MovieRepositoryImpl repository;
  late MockTMDbClient mockTMDbClient;

  setUp(() {
    mockTMDbClient = MockTMDbClient();
    repository = MovieRepositoryImpl(tmdbClient: mockTMDbClient);
  });

  group('MovieRepositoryImpl', () {
    final testMovie = Movie(
      id: 1,
      title: 'Test Movie',
      overview: 'Test overview',
      genres: [const Genre(id: 28, name: 'Action')],
      voteAverage: 7.5,
      releaseDate: '2023-01-01',
    );

    final testGenre = const Genre(id: 28, name: 'Action');

    group('searchMovies', () {
      test('should return Success with movies when TMDb client succeeds', () async {
        // Arrange
        const query = 'test movie';
        final expectedMovies = [testMovie];
        when(mockTMDbClient.searchMovies(query)).thenAnswer((_) async => expectedMovies);

        // Act
        final result = await repository.searchMovies(query);

        // Assert
        expect(result, isA<Success<List<Movie>>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (movies) {
            expect(movies, expectedMovies);
            expect(movies.length, 1);
            expect(movies.first.title, 'Test Movie');
          },
        );
        verify(mockTMDbClient.searchMovies(query)).called(1);
      });

      test('should return NetworkFailure when NetworkException is thrown', () async {
        // Arrange
        const query = 'test movie';
        when(mockTMDbClient.searchMovies(query))
            .thenThrow(const NetworkException('No internet connection'));

        // Act
        final result = await repository.searchMovies(query);

        // Assert
        expect(result, isA<ResultFailure<List<Movie>>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'No internet connection');
          },
          (movies) => fail('Expected failure but got success'),
        );
      });

      test('should return ApiFailure when ApiException is thrown', () async {
        // Arrange
        const query = 'test movie';
        when(mockTMDbClient.searchMovies(query))
            .thenThrow(const ApiException('API error'));

        // Act
        final result = await repository.searchMovies(query);

        // Assert
        expect(result, isA<ResultFailure<List<Movie>>>());
        result.fold(
          (failure) {
            expect(failure, isA<ApiFailure>());
            expect(failure.message, 'API error');
          },
          (movies) => fail('Expected failure but got success'),
        );
      });
    });

    group('getMovieDetails', () {
      test('should return Success with movie when TMDb client succeeds', () async {
        // Arrange
        const movieId = 123;
        when(mockTMDbClient.getMovieDetails(movieId)).thenAnswer((_) async => testMovie);

        // Act
        final result = await repository.getMovieDetails(movieId);

        // Assert
        expect(result, isA<Success<Movie>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (movie) {
            expect(movie, testMovie);
            expect(movie.title, 'Test Movie');
          },
        );
        verify(mockTMDbClient.getMovieDetails(movieId)).called(1);
      });
    });

    group('getRecommendations', () {
      test('should return Success with movies when TMDb client succeeds', () async {
        // Arrange
        const movieId = 123;
        final expectedMovies = [testMovie];
        when(mockTMDbClient.getMovieBasedRecommendations(movieId))
            .thenAnswer((_) async => expectedMovies);

        // Act
        final result = await repository.getRecommendations(movieId);

        // Assert
        expect(result, isA<Success<List<Movie>>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (movies) {
            expect(movies, expectedMovies);
            expect(movies.length, 1);
          },
        );
        verify(mockTMDbClient.getMovieBasedRecommendations(movieId)).called(1);
      });
    });

    group('getGenres', () {
      test('should return Success with genres when TMDb client succeeds', () async {
        // Arrange
        final expectedGenres = [testGenre];
        when(mockTMDbClient.getGenres()).thenAnswer((_) async => expectedGenres);

        // Act
        final result = await repository.getGenres();

        // Assert
        expect(result, isA<Success<List<Genre>>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (genres) {
            expect(genres, expectedGenres);
            expect(genres.length, 1);
            expect(genres.first.name, 'Action');
          },
        );
        verify(mockTMDbClient.getGenres()).called(1);
      });
    });

    group('discoverMovies', () {
      test('should return Success with movies when TMDb client succeeds', () async {
        // Arrange
        final expectedMovies = [testMovie];
        when(mockTMDbClient.getMovieRecommendations(
          genres: anyNamed('genres'),
          page: anyNamed('page'),
          sortBy: anyNamed('sortBy'),
        )).thenAnswer((_) async => expectedMovies);

        // Act
        final result = await repository.discoverMovies(
          genreIds: [28, 35],
          page: 1,
          sortBy: 'popularity.desc',
        );

        // Assert
        expect(result, isA<Success<List<Movie>>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (movies) {
            expect(movies, expectedMovies);
            expect(movies.length, 1);
          },
        );
        verify(mockTMDbClient.getMovieRecommendations(
          genres: ['28', '35'],
          page: 1,
          sortBy: 'popularity.desc',
        )).called(1);
      });

      test('should call TMDb client with correct parameters when no genres provided', () async {
        // Arrange
        final expectedMovies = [testMovie];
        when(mockTMDbClient.getMovieRecommendations(
          genres: anyNamed('genres'),
          page: anyNamed('page'),
          sortBy: anyNamed('sortBy'),
        )).thenAnswer((_) async => expectedMovies);

        // Act
        await repository.discoverMovies(page: 2, sortBy: 'release_date.desc');

        // Assert
        verify(mockTMDbClient.getMovieRecommendations(
          genres: null,
          page: 2,
          sortBy: 'release_date.desc',
        )).called(1);
      });
    });

    group('Authentication Required Methods', () {
      group('rateMovie', () {
        test('should return AuthenticationFailure when not authenticated', () async {
          // Act
          final result = await repository.rateMovie(123, 8.5);

          // Assert
          expect(result, isA<ResultFailure<bool>>());
          result.fold(
            (failure) {
              expect(failure, isA<AuthenticationFailure>());
              expect(failure.message, 'User not authenticated');
            },
            (success) => fail('Expected failure but got success'),
          );
          verifyNever(mockTMDbClient.rateMovie(any, any, any));
        });

        test('should return Success when authenticated and rating succeeds', () async {
          // Arrange
          const movieId = 123;
          const rating = 8.5;
          const sessionId = 'test_session';
          repository.setAuthenticationDetails(sessionId: sessionId, accountId: 456);
          
          when(mockTMDbClient.rateMovie(movieId, rating, sessionId))
              .thenAnswer((_) async => true);

          // Act
          final result = await repository.rateMovie(movieId, rating);

          // Assert
          expect(result, isA<Success<bool>>());
          result.fold(
            (failure) => fail('Expected success but got failure: $failure'),
            (success) => expect(success, true),
          );
          verify(mockTMDbClient.rateMovie(movieId, rating, sessionId)).called(1);
        });

        test('should return ValidationFailure when ValidationException is thrown', () async {
          // Arrange
          const movieId = 123;
          const rating = 15.0; // Invalid rating
          const sessionId = 'test_session';
          repository.setAuthenticationDetails(sessionId: sessionId, accountId: 456);
          
          when(mockTMDbClient.rateMovie(movieId, rating, sessionId))
              .thenThrow(const ValidationException('Rating must be between 0.5 and 10.0'));

          // Act
          final result = await repository.rateMovie(movieId, rating);

          // Assert
          expect(result, isA<ResultFailure<bool>>());
          result.fold(
            (failure) {
              expect(failure, isA<ValidationFailure>());
              expect(failure.message, 'Rating must be between 0.5 and 10.0');
            },
            (success) => fail('Expected failure but got success'),
          );
        });
      });

      group('deleteRating', () {
        test('should return AuthenticationFailure when not authenticated', () async {
          // Act
          final result = await repository.deleteRating(123);

          // Assert
          expect(result, isA<ResultFailure<bool>>());
          result.fold(
            (failure) {
              expect(failure, isA<AuthenticationFailure>());
              expect(failure.message, 'User not authenticated');
            },
            (success) => fail('Expected failure but got success'),
          );
          verifyNever(mockTMDbClient.deleteMovieRating(any, any));
        });

        test('should return Success when authenticated and deletion succeeds', () async {
          // Arrange
          const movieId = 123;
          const sessionId = 'test_session';
          repository.setAuthenticationDetails(sessionId: sessionId, accountId: 456);
          
          when(mockTMDbClient.deleteMovieRating(movieId, sessionId))
              .thenAnswer((_) async => true);

          // Act
          final result = await repository.deleteRating(movieId);

          // Assert
          expect(result, isA<Success<bool>>());
          result.fold(
            (failure) => fail('Expected success but got failure: $failure'),
            (success) => expect(success, true),
          );
          verify(mockTMDbClient.deleteMovieRating(movieId, sessionId)).called(1);
        });
      });

      group('getRatedMovies', () {
        test('should return AuthenticationFailure when not authenticated', () async {
          // Act
          final result = await repository.getRatedMovies();

          // Assert
          expect(result, isA<ResultFailure<List<Movie>>>());
          result.fold(
            (failure) {
              expect(failure, isA<AuthenticationFailure>());
              expect(failure.message, 'User not authenticated');
            },
            (movies) => fail('Expected failure but got success'),
          );
          verifyNever(mockTMDbClient.getRatedMovies(any, any));
        });

        test('should return Success when authenticated and API call succeeds', () async {
          // Arrange
          const sessionId = 'test_session';
          const accountId = 456;
          final expectedMovies = [testMovie];
          repository.setAuthenticationDetails(sessionId: sessionId, accountId: accountId);
          
          when(mockTMDbClient.getRatedMovies(accountId, sessionId))
              .thenAnswer((_) async => expectedMovies);

          // Act
          final result = await repository.getRatedMovies();

          // Assert
          expect(result, isA<Success<List<Movie>>>());
          result.fold(
            (failure) => fail('Expected success but got failure: $failure'),
            (movies) {
              expect(movies, expectedMovies);
              expect(movies.length, 1);
            },
          );
          verify(mockTMDbClient.getRatedMovies(accountId, sessionId)).called(1);
        });

        test('should return AuthenticationFailure when session is null but account is set', () async {
          // Arrange
          repository.setAuthenticationDetails(sessionId: null, accountId: 456);

          // Act
          final result = await repository.getRatedMovies();

          // Assert
          expect(result, isA<ResultFailure<List<Movie>>>());
          result.fold(
            (failure) {
              expect(failure, isA<AuthenticationFailure>());
              expect(failure.message, 'User not authenticated');
            },
            (movies) => fail('Expected failure but got success'),
          );
        });
      });

      group('getWatchlist', () {
        test('should return AuthenticationFailure when not authenticated', () async {
          // Act
          final result = await repository.getWatchlist();

          // Assert
          expect(result, isA<ResultFailure<List<Movie>>>());
          result.fold(
            (failure) {
              expect(failure, isA<AuthenticationFailure>());
              expect(failure.message, 'User not authenticated');
            },
            (movies) => fail('Expected failure but got success'),
          );
          verifyNever(mockTMDbClient.getWatchlistMovies(any, any));
        });

        test('should return Success when authenticated and API call succeeds', () async {
          // Arrange
          const sessionId = 'test_session';
          const accountId = 456;
          final expectedMovies = [testMovie];
          repository.setAuthenticationDetails(sessionId: sessionId, accountId: accountId);
          
          when(mockTMDbClient.getWatchlistMovies(accountId, sessionId))
              .thenAnswer((_) async => expectedMovies);

          // Act
          final result = await repository.getWatchlist();

          // Assert
          expect(result, isA<Success<List<Movie>>>());
          result.fold(
            (failure) => fail('Expected success but got failure: $failure'),
            (movies) {
              expect(movies, expectedMovies);
              expect(movies.length, 1);
            },
          );
          verify(mockTMDbClient.getWatchlistMovies(accountId, sessionId)).called(1);
        });
      });
    });

    group('setAuthenticationDetails', () {
      test('should set session ID and account ID correctly', () async {
        // Arrange
        const sessionId = 'test_session';
        const accountId = 123;
        final expectedMovies = [testMovie];
        
        when(mockTMDbClient.getRatedMovies(accountId, sessionId))
            .thenAnswer((_) async => expectedMovies);

        // Act
        repository.setAuthenticationDetails(sessionId: sessionId, accountId: accountId);
        final result = await repository.getRatedMovies();

        // Assert
        expect(result, isA<Success<List<Movie>>>());
        verify(mockTMDbClient.getRatedMovies(accountId, sessionId)).called(1);
      });
    });
  });
}