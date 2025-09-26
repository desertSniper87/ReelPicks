import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/tmdb_client.dart';
import '../models/movie.dart';

/// Concrete implementation of MovieRepository using TMDb API
class MovieRepositoryImpl implements MovieRepository {
  final TMDbClient _tmdbClient;
  String? _sessionId;
  int? _accountId;

  MovieRepositoryImpl({
    required TMDbClient tmdbClient,
  }) : _tmdbClient = tmdbClient;

  /// Set authentication details for user-specific operations
  void setAuthenticationDetails({String? sessionId, int? accountId}) {
    _sessionId = sessionId;
    _accountId = accountId;
  }

  @override
  Future<Result<List<Movie>>> searchMovies(String query) async {
    try {
      final movies = await _tmdbClient.searchMovies(query);
      return Success(movies);
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Movie>> getMovieDetails(int movieId) async {
    try {
      final movie = await _tmdbClient.getMovieDetails(movieId);
      return Success(movie);
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Movie>>> getRecommendations(int movieId) async {
    try {
      final movies = await _tmdbClient.getMovieBasedRecommendations(movieId);
      return Success(movies);
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Genre>>> getGenres() async {
    try {
      final genres = await _tmdbClient.getGenres();
      return Success(genres);
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> rateMovie(int movieId, double rating) async {
    if (_sessionId == null) {
      return const ResultFailure(AuthenticationFailure('User not authenticated'));
    }

    try {
      final success = await _tmdbClient.rateMovie(movieId, rating, _sessionId!);
      return Success(success);
    } on ValidationException catch (e) {
      return ResultFailure(ValidationFailure(e.message, e.code));
    } on AuthenticationException catch (e) {
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> deleteRating(int movieId) async {
    if (_sessionId == null) {
      return const ResultFailure(AuthenticationFailure('User not authenticated'));
    }

    try {
      final success = await _tmdbClient.deleteMovieRating(movieId, _sessionId!);
      return Success(success);
    } on AuthenticationException catch (e) {
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Movie>>> getRatedMovies() async {
    if (_sessionId == null || _accountId == null) {
      return const ResultFailure(AuthenticationFailure('User not authenticated'));
    }

    try {
      final movies = await _tmdbClient.getRatedMovies(_accountId!, _sessionId!);
      return Success(movies);
    } on AuthenticationException catch (e) {
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Movie>>> getWatchlist() async {
    if (_sessionId == null || _accountId == null) {
      return const ResultFailure(AuthenticationFailure('User not authenticated'));
    }

    try {
      final movies = await _tmdbClient.getWatchlistMovies(_accountId!, _sessionId!);
      return Success(movies);
    } on AuthenticationException catch (e) {
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Movie>>> discoverMovies({
    List<int>? genreIds,
    int page = 1,
    String sortBy = 'popularity.desc',
  }) async {
    try {
      final genres = genreIds?.map((id) => id.toString()).toList();
      final movies = await _tmdbClient.getMovieRecommendations(
        genres: genres,
        page: page,
        sortBy: sortBy,
      );
      return Success(movies);
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }
}