import '../../core/utils/result.dart';
import '../../data/models/movie.dart';

/// Abstract movie repository interface
abstract class MovieRepository {
  /// Set authentication details for user-specific operations
  void setAuthenticationDetails({String? sessionId, int? accountId});
  
  /// Search for movies by query
  Future<Result<List<Movie>>> searchMovies(String query);
  
  /// Get movie details by ID
  Future<Result<Movie>> getMovieDetails(int movieId);
  
  /// Get movie recommendations based on a movie ID
  Future<Result<List<Movie>>> getRecommendations(int movieId);
  
  /// Get list of available genres
  Future<Result<List<Genre>>> getGenres();
  
  /// Rate a movie (requires authentication)
  Future<Result<bool>> rateMovie(int movieId, double rating);
  
  /// Delete a movie rating (requires authentication)
  Future<Result<bool>> deleteRating(int movieId);
  
  /// Get user's rated movies (requires authentication)
  Future<Result<List<Movie>>> getRatedMovies();
  
  /// Get user's watchlist (requires authentication)
  Future<Result<List<Movie>>> getWatchlist();
  
  /// Discover movies with filters
  Future<Result<List<Movie>>> discoverMovies({
    List<int>? genreIds,
    int page = 1,
    String sortBy = 'popularity.desc',
  });
}