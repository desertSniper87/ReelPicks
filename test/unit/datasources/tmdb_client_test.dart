import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:movie_recommendation_app/data/datasources/tmdb_client.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';
import 'package:movie_recommendation_app/core/error/exceptions.dart';

import 'tmdb_client_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late TMDbClient tmdbClient;
  late MockClient mockHttpClient;

  setUpAll(() async {
    // Initialize dotenv with test values
    dotenv.testLoad(fileInput: '''
TMDB_API_KEY=test_api_key
TMDB_BASE_URL=https://api.themoviedb.org/3
TMDB_IMAGE_BASE_URL=https://image.tmdb.org/t/p/w500
''');
  });

  setUp(() {
    mockHttpClient = MockClient();
    tmdbClient = TMDbClient(httpClient: mockHttpClient);
  });

  tearDown(() {
    tmdbClient.dispose();
  });

  group('TMDbClient', () {
    group('getMovieRecommendations', () {
      test('should return list of movies when API call is successful', () async {
        // Arrange
        final mockResponse = {
          'results': [
            {
              'id': 1,
              'title': 'Test Movie',
              'overview': 'Test overview',
              'poster_path': '/test.jpg',
              'backdrop_path': '/test_backdrop.jpg',
              'genres': [
                {'id': 28, 'name': 'Action'}
              ],
              'vote_average': 7.5,
              'release_date': '2023-01-01',
              'runtime': 120,
            }
          ]
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act
        final result = await tmdbClient.getMovieRecommendations();

        // Assert
        expect(result, isA<List<Movie>>());
        expect(result.length, 1);
        expect(result.first.title, 'Test Movie');
        expect(result.first.id, 1);
        expect(result.first.genres.first.name, 'Action');
      });

      test('should include genre filter in request when genres provided', () async {
        // Arrange
        final mockResponse = {'results': []};
        
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act
        await tmdbClient.getMovieRecommendations(genres: ['28', '35']);

        // Assert
        final captured = verify(mockHttpClient.get(
          captureAny,
          headers: anyNamed('headers'),
        )).captured;
        
        final uri = captured.first as Uri;
        expect(uri.queryParameters['with_genres'], '28,35');
      });

      test('should throw NetworkException when no internet connection', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('No internet connection'));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should throw ApiException when API returns error', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'status_message': 'API Error'}),
          400,
          headers: {'content-type': 'application/json'},
        ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getMovieBasedRecommendations', () {
      test('should return recommendations based on movie ID', () async {
        // Arrange
        const movieId = 123;
        final mockResponse = {
          'results': [
            {
              'id': 456,
              'title': 'Similar Movie',
              'overview': 'Similar overview',
              'poster_path': '/similar.jpg',
              'genres': [
                {'id': 28, 'name': 'Action'}
              ],
              'vote_average': 8.0,
              'release_date': '2023-02-01',
            }
          ]
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act
        final result = await tmdbClient.getMovieBasedRecommendations(movieId);

        // Assert
        expect(result, isA<List<Movie>>());
        expect(result.length, 1);
        expect(result.first.title, 'Similar Movie');
        expect(result.first.id, 456);

        // Verify correct endpoint was called
        final captured = verify(mockHttpClient.get(
          captureAny,
          headers: anyNamed('headers'),
        )).captured;
        
        final uri = captured.first as Uri;
        expect(uri.path, contains('/movie/$movieId/recommendations'));
      });
    });

    group('getGenres', () {
      test('should return list of genres when API call is successful', () async {
        // Arrange
        final mockResponse = {
          'genres': [
            {'id': 28, 'name': 'Action'},
            {'id': 35, 'name': 'Comedy'},
          ]
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act
        final result = await tmdbClient.getGenres();

        // Assert
        expect(result, isA<List<Genre>>());
        expect(result.length, 2);
        expect(result.first.name, 'Action');
        expect(result.first.id, 28);
        expect(result.last.name, 'Comedy');
        expect(result.last.id, 35);
      });
    });

    group('getMovieDetails', () {
      test('should return movie details when API call is successful', () async {
        // Arrange
        const movieId = 123;
        final mockResponse = {
          'id': movieId,
          'title': 'Detailed Movie',
          'overview': 'Detailed overview',
          'poster_path': '/detailed.jpg',
          'genres': [
            {'id': 28, 'name': 'Action'},
            {'id': 35, 'name': 'Comedy'},
          ],
          'vote_average': 8.5,
          'release_date': '2023-03-01',
          'runtime': 150,
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act
        final result = await tmdbClient.getMovieDetails(movieId);

        // Assert
        expect(result, isA<Movie>());
        expect(result.title, 'Detailed Movie');
        expect(result.id, movieId);
        expect(result.runtime, 150);
        expect(result.genres.length, 2);
      });
    });

    group('searchMovies', () {
      test('should return search results when API call is successful', () async {
        // Arrange
        const query = 'test movie';
        final mockResponse = {
          'results': [
            {
              'id': 789,
              'title': 'Test Movie Result',
              'overview': 'Search result overview',
              'poster_path': '/search.jpg',
              'genres': [
                {'id': 18, 'name': 'Drama'}
              ],
              'vote_average': 7.0,
              'release_date': '2023-04-01',
            }
          ]
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act
        final result = await tmdbClient.searchMovies(query);

        // Assert
        expect(result, isA<List<Movie>>());
        expect(result.length, 1);
        expect(result.first.title, 'Test Movie Result');

        // Verify query parameter was included
        final captured = verify(mockHttpClient.get(
          captureAny,
          headers: anyNamed('headers'),
        )).captured;
        
        final uri = captured.first as Uri;
        expect(uri.queryParameters['query'], query);
      });
    });

    group('Authentication', () {
      group('createRequestToken', () {
        test('should return request token when API call is successful', () async {
          // Arrange
          const expectedToken = 'test_request_token';
          final mockResponse = {
            'success': true,
            'expires_at': '2023-12-31 23:59:59 UTC',
            'request_token': expectedToken,
          };

          when(mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.createRequestToken();

          // Assert
          expect(result, expectedToken);
        });

        test('should throw AuthenticationException when token creation fails', () async {
          // Arrange
          final mockResponse = {
            'success': false,
            'status_message': 'Failed to create token',
          };

          when(mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act & Assert
          expect(
            () => tmdbClient.createRequestToken(),
            throwsA(isA<AuthenticationException>()),
          );
        });
      });

      group('createSession', () {
        test('should return session ID when API call is successful', () async {
          // Arrange
          const approvedToken = 'approved_token';
          const expectedSessionId = 'test_session_id';
          final mockResponse = {
            'success': true,
            'session_id': expectedSessionId,
          };

          when(mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.createSession(approvedToken);

          // Assert
          expect(result, expectedSessionId);

          // Verify request body contains the token
          final captured = verify(mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
          )).captured;
          
          final body = jsonDecode(captured.first as String);
          expect(body['request_token'], approvedToken);
        });
      });
    });

    group('Movie Rating', () {
      group('rateMovie', () {
        test('should return true when rating is successful', () async {
          // Arrange
          const movieId = 123;
          const rating = 8.5;
          const sessionId = 'test_session';
          final mockResponse = {
            'success': true,
            'status_code': 1,
            'status_message': 'Success',
          };

          when(mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.rateMovie(movieId, rating, sessionId);

          // Assert
          expect(result, true);

          // Verify request parameters
          final captured = verify(mockHttpClient.post(
            captureAny,
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
          )).captured;
          
          final uri = captured.first as Uri;
          expect(uri.path, contains('/movie/$movieId/rating'));
          expect(uri.queryParameters['session_id'], sessionId);
          
          final body = jsonDecode(captured.last as String);
          expect(body['value'], rating);
        });

        test('should throw ValidationException for invalid rating', () async {
          // Arrange
          const movieId = 123;
          const invalidRating = 15.0; // Above maximum
          const sessionId = 'test_session';

          // Act & Assert
          expect(
            () => tmdbClient.rateMovie(movieId, invalidRating, sessionId),
            throwsA(isA<ValidationException>()),
          );
        });

        test('should return false when rating fails', () async {
          // Arrange
          const movieId = 123;
          const rating = 8.5;
          const sessionId = 'test_session';
          final mockResponse = {
            'success': false,
            'status_message': 'Rating failed',
          };

          when(mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.rateMovie(movieId, rating, sessionId);

          // Assert
          expect(result, false);
        });
      });

      group('deleteMovieRating', () {
        test('should return true when deletion is successful', () async {
          // Arrange
          const movieId = 123;
          const sessionId = 'test_session';
          final mockResponse = {
            'success': true,
            'status_code': 13,
            'status_message': 'The item/record was deleted successfully.',
          };

          when(mockHttpClient.delete(
            any,
            headers: anyNamed('headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.deleteMovieRating(movieId, sessionId);

          // Assert
          expect(result, true);

          // Verify request parameters
          final captured = verify(mockHttpClient.delete(
            captureAny,
            headers: anyNamed('headers'),
          )).captured;
          
          final uri = captured.first as Uri;
          expect(uri.path, contains('/movie/$movieId/rating'));
          expect(uri.queryParameters['session_id'], sessionId);
        });
      });
    });

    group('User Data', () {
      group('getRatedMovies', () {
        test('should return list of rated movies with user ratings', () async {
          // Arrange
          const accountId = 123;
          const sessionId = 'test_session';
          final mockResponse = {
            'results': [
              {
                'id': 456,
                'title': 'Rated Movie',
                'overview': 'User rated this movie',
                'poster_path': '/rated.jpg',
                'genres': [
                  {'id': 28, 'name': 'Action'}
                ],
                'vote_average': 7.5,
                'release_date': '2023-01-01',
                'rating': 9.0, // User's rating
              }
            ]
          };

          when(mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.getRatedMovies(accountId, sessionId);

          // Assert
          expect(result, isA<List<Movie>>());
          expect(result.length, 1);
          expect(result.first.title, 'Rated Movie');
          expect(result.first.userRating, 9.0);
          expect(result.first.isWatched, true);

          // Verify correct endpoint was called
          final captured = verify(mockHttpClient.get(
            captureAny,
            headers: anyNamed('headers'),
          )).captured;
          
          final uri = captured.first as Uri;
          expect(uri.path, contains('/account/$accountId/rated/movies'));
          expect(uri.queryParameters['session_id'], sessionId);
        });
      });

      group('getWatchlistMovies', () {
        test('should return list of watchlist movies', () async {
          // Arrange
          const accountId = 123;
          const sessionId = 'test_session';
          final mockResponse = {
            'results': [
              {
                'id': 789,
                'title': 'Watchlist Movie',
                'overview': 'Movie in watchlist',
                'poster_path': '/watchlist.jpg',
                'genres': [
                  {'id': 35, 'name': 'Comedy'}
                ],
                'vote_average': 6.5,
                'release_date': '2023-05-01',
              }
            ]
          };

          when(mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.getWatchlistMovies(accountId, sessionId);

          // Assert
          expect(result, isA<List<Movie>>());
          expect(result.length, 1);
          expect(result.first.title, 'Watchlist Movie');
          expect(result.first.isWatched, true);

          // Verify correct endpoint was called
          final captured = verify(mockHttpClient.get(
            captureAny,
            headers: anyNamed('headers'),
          )).captured;
          
          final uri = captured.first as Uri;
          expect(uri.path, contains('/account/$accountId/watchlist/movies'));
        });
      });

      group('getAccountDetails', () {
        test('should return account details when API call is successful', () async {
          // Arrange
          const sessionId = 'test_session';
          final mockResponse = {
            'avatar': {
              'gravatar': {
                'hash': 'test_hash'
              }
            },
            'id': 123,
            'iso_639_1': 'en',
            'iso_3166_1': 'US',
            'name': 'Test User',
            'include_adult': false,
            'username': 'testuser'
          };

          when(mockHttpClient.get(
            any,
            headers: anyNamed('headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

          // Act
          final result = await tmdbClient.getAccountDetails(sessionId);

          // Assert
          expect(result, isA<Map<String, dynamic>>());
          expect(result['id'], 123);
          expect(result['username'], 'testuser');
          expect(result['name'], 'Test User');
        });
      });
    });

    group('Error Handling', () {
      test('should throw AuthenticationException for 401 status', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'status_message': 'Invalid API key'}),
          401,
          headers: {'content-type': 'application/json'},
        ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('should throw ApiException for 404 status', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'status_message': 'Resource not found'}),
          404,
          headers: {'content-type': 'application/json'},
        ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });

      test('should throw ApiException for 429 status (rate limit)', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'status_message': 'Rate limit exceeded'}),
          429,
          headers: {'content-type': 'application/json'},
        ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });

      test('should throw ApiException for server errors (5xx)', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'status_message': 'Internal server error'}),
          500,
          headers: {'content-type': 'application/json'},
        ));

        // Act & Assert
        expect(
          () => tmdbClient.getMovieRecommendations(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('Caching', () {
      test('should use cached data when available and not expired', () async {
        // Arrange
        final mockResponse = {
          'results': [
            {
              'id': 1,
              'title': 'Cached Movie',
              'overview': 'This should come from cache',
              'poster_path': '/cached.jpg',
              'genres': [
                {'id': 28, 'name': 'Action'}
              ],
              'vote_average': 7.5,
              'release_date': '2023-01-01',
            }
          ]
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act - First call should hit the API
        final result1 = await tmdbClient.getMovieRecommendations();
        
        // Act - Second call should use cache
        final result2 = await tmdbClient.getMovieRecommendations();

        // Assert
        expect(result1.first.title, 'Cached Movie');
        expect(result2.first.title, 'Cached Movie');
        
        // Verify API was called only once
        verify(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should clear cache when clearCache is called', () async {
        // Arrange
        final mockResponse = {'results': []};
        
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode(mockResponse),
          200,
          headers: {'content-type': 'application/json'},
        ));

        // Act
        await tmdbClient.getMovieRecommendations(); // First call
        tmdbClient.clearCache(); // Clear cache
        await tmdbClient.getMovieRecommendations(); // Second call

        // Assert - API should be called twice since cache was cleared
        verify(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).called(2);
      });
    });
  });
}