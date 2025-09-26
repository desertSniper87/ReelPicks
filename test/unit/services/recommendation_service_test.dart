import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/error/failures.dart';
import '../../../lib/core/utils/result.dart';
import '../../../lib/data/models/movie.dart';
import '../../../lib/data/models/user_profile.dart';
import '../../../lib/data/models/recommendation_result.dart';
import '../../../lib/data/services/recommendation_service_impl.dart';
import '../../../lib/domain/repositories/movie_repository.dart';

// Simple test implementation of MovieRepository
class TestMovieRepository implements MovieRepository {
  final List<Movie> _testMovies;
  final List<Genre> _testGenres;
  final bool _shouldFail;

  TestMovieRepository({
    required List<Movie> testMovies,
    required List<Genre> testGenres,
    bool shouldFail = false,
  }) : _testMovies = testMovies, _testGenres = testGenres, _shouldFail = shouldFail;

  @override
  Future<Result<List<Movie>>> searchMovies(String query) async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    return Success(_testMovies.where((m) => m.title.contains(query)).toList());
  }

  @override
  Future<Result<Movie>> getMovieDetails(int movieId) async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    final movie = _testMovies.firstWhere((m) => m.id == movieId);
    return Success(movie);
  }

  @override
  Future<Result<List<Movie>>> getRecommendations(int movieId) async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    return Success(_testMovies.where((m) => m.id != movieId).toList());
  }

  @override
  Future<Result<List<Genre>>> getGenres() async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    return Success(_testGenres);
  }

  @override
  Future<Result<bool>> rateMovie(int movieId, double rating) async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    return const Success(true);
  }

  @override
  Future<Result<bool>> deleteRating(int movieId) async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    return const Success(true);
  }

  @override
  Future<Result<List<Movie>>> getRatedMovies() async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    return Success(_testMovies.where((m) => m.userRating != null).toList());
  }

  @override
  Future<Result<List<Movie>>> getWatchlist() async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    return Success(_testMovies.where((m) => m.isWatched).toList());
  }

  @override
  Future<Result<List<Movie>>> discoverMovies({
    List<int>? genreIds,
    int page = 1,
    String sortBy = 'popularity.desc',
  }) async {
    if (_shouldFail) return const ResultFailure(ApiFailure('Test error'));
    
    var movies = _testMovies;
    
    if (genreIds != null && genreIds.isNotEmpty) {
      movies = movies.where((movie) => 
        movie.genres.any((genre) => genreIds.contains(genre.id))
      ).toList();
    }
    
    // Simple sorting by vote average for testing
    if (sortBy == 'popularity.desc') {
      movies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }
    
    return Success(movies);
  }
}

void main() {
  group('RecommendationService', () {
    final testGenres = [
      const Genre(id: 28, name: 'Action'),
      const Genre(id: 35, name: 'Comedy'),
      const Genre(id: 18, name: 'Drama'),
    ];

    final testMovies = [
      Movie(
        id: 1,
        title: 'Action Movie',
        overview: 'Action overview',
        genres: [testGenres[0]], // Action
        voteAverage: 8.0,
        releaseDate: '2023-01-01',
      ),
      Movie(
        id: 2,
        title: 'Comedy Movie',
        overview: 'Comedy overview',
        genres: [testGenres[1]], // Comedy
        voteAverage: 7.5,
        releaseDate: '2023-02-01',
      ),
      Movie(
        id: 3,
        title: 'Drama Movie',
        overview: 'Drama overview',
        genres: [testGenres[2]], // Drama
        voteAverage: 9.0,
        releaseDate: '2023-03-01',
      ),
      Movie(
        id: 4,
        title: 'Rated Action Movie',
        overview: 'Rated action overview',
        genres: [testGenres[0]], // Action
        voteAverage: 8.5,
        releaseDate: '2022-01-01',
        userRating: 9.0,
        isWatched: true,
      ),
    ];

    late RecommendationServiceImpl service;
    late TestMovieRepository repository;

    setUp(() {
      repository = TestMovieRepository(
        testMovies: testMovies,
        testGenres: testGenres,
      );
      service = RecommendationServiceImpl(movieRepository: repository);
    });

    test('should return popular movies when user is not authenticated', () async {
      // Arrange
      final profile = const UserProfile(
        preferredGenres: ['Action'],
        isAuthenticated: false,
      );

      // Act
      final result = await service.getPersonalizedRecommendations(profile);

      // Assert
      expect(result, isA<Success<RecommendationResult>>());
      final successResult = result as Success<RecommendationResult>;
      expect(successResult.data.source, equals('popular'));
      expect(successResult.data.movies.isNotEmpty, isTrue);
      expect(successResult.data.metadata['fallback'], isTrue);
    });

    test('should return genre-based recommendations for valid genres', () async {
      // Act
      final result = await service.getGenreBasedRecommendations(['Action']);

      // Assert
      expect(result, isA<Success<RecommendationResult>>());
      final successResult = result as Success<RecommendationResult>;
      expect(successResult.data.source, equals('genre_based'));
      expect(successResult.data.metadata['genres'], equals(['Action']));
      expect(successResult.data.metadata['genre_ids'], equals([28]));
    });

    test('should return popular movies successfully', () async {
      // Act
      final result = await service.getPopularMovies();

      // Assert
      expect(result, isA<Success<RecommendationResult>>());
      final successResult = result as Success<RecommendationResult>;
      expect(successResult.data.source, equals('popular'));
      expect(successResult.data.movies.isNotEmpty, isTrue);
      expect(successResult.data.metadata['sort_by'], equals('popularity.desc'));
      expect(successResult.data.metadata['fallback'], isTrue);
    });

    test('should return similar movies successfully', () async {
      // Act
      final result = await service.getSimilarMovies(1);

      // Assert
      expect(result, isA<Success<List<Movie>>>());
      final successResult = result as Success<List<Movie>>;
      expect(successResult.data.every((m) => m.id != 1), isTrue);
    });

    test('should filter out watched movies correctly', () async {
      // Arrange
      final watchedIds = [1, 3];

      // Act
      final result = service.filterWatchedMovies(testMovies, watchedIds);

      // Assert
      expect(result.length, equals(2));
      expect(result.every((m) => ![1, 3].contains(m.id)), isTrue);
    });

    test('should exclude specified movie IDs from recommendations', () async {
      // Act
      final result = await service.getPopularMovies(excludeMovieIds: [1, 3]);

      // Assert
      expect(result, isA<Success<RecommendationResult>>());
      final successResult = result as Success<RecommendationResult>;
      expect(successResult.data.movies.every((m) => ![1, 3].contains(m.id)), isTrue);
    });

    test('should handle repository failures gracefully', () async {
      // Arrange
      final failingRepository = TestMovieRepository(
        testMovies: testMovies,
        testGenres: testGenres,
        shouldFail: true,
      );
      final failingService = RecommendationServiceImpl(movieRepository: failingRepository);

      // Act
      final result = await failingService.getPopularMovies();

      // Assert
      expect(result, isA<ResultFailure>());
      final failureResult = result as ResultFailure;
      expect(failureResult.failure, isA<ApiFailure>());
    });
  });
}