import '../../core/utils/result.dart';
import '../../data/models/movie.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/recommendation_result.dart';

/// Abstract recommendation service interface
abstract class RecommendationService {
  /// Get personalized movie recommendations based on user profile
  Future<Result<RecommendationResult>> getPersonalizedRecommendations(
    UserProfile profile, {
    int page = 1,
    List<int>? excludeMovieIds,
  });
  
  /// Get genre-based movie recommendations
  Future<Result<RecommendationResult>> getGenreBasedRecommendations(
    List<String> genres, {
    int page = 1,
    List<int>? excludeMovieIds,
  });
  
  /// Get popular movie recommendations as fallback
  Future<Result<RecommendationResult>> getPopularMovies({
    int page = 1,
    List<int>? excludeMovieIds,
  });
  
  /// Get recommendations based on a specific movie
  Future<Result<List<Movie>>> getSimilarMovies(
    int movieId, {
    List<int>? excludeMovieIds,
  });
  
  /// Filter out already rated/watched movies from recommendations
  List<Movie> filterWatchedMovies(
    List<Movie> movies,
    List<int> watchedMovieIds,
  );
}