import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/movie_repository.dart';
import '../../domain/services/recommendation_service.dart';
import '../models/movie.dart';
import '../models/user_profile.dart';
import '../models/recommendation_result.dart';

/// Concrete implementation of RecommendationService
class RecommendationServiceImpl implements RecommendationService {
  final MovieRepository _movieRepository;
  
  // Cache for genre mappings
  final Map<String, int> _genreNameToIdMap = {};
  bool _genresLoaded = false;

  RecommendationServiceImpl({
    required MovieRepository movieRepository,
  }) : _movieRepository = movieRepository;

  @override
  Future<Result<RecommendationResult>> getPersonalizedRecommendations(
    UserProfile profile, {
    int page = 1,
    List<int>? excludeMovieIds,
  }) async {
    try {
      // If user is not authenticated or has no preferences, fall back to popular movies
      if (!profile.isAuthenticated || profile.preferredGenres.isEmpty) {
        return await getPopularMovies(page: page, excludeMovieIds: excludeMovieIds);
      }

      // Get user's rated movies to understand preferences better
      List<Movie> ratedMovies = [];
      if (profile.tmdbSessionId != null && profile.tmdbAccountId != null) {
        final ratedResult = await _movieRepository.getRatedMovies();
        if (ratedResult is Success<List<Movie>>) {
          ratedMovies = ratedResult.data;
        }
      }

      // Generate recommendations based on user preferences and ratings
      final recommendations = await _generatePersonalizedRecommendations(
        profile,
        ratedMovies,
        page: page,
        excludeMovieIds: excludeMovieIds,
      );

      if (recommendations is Success<List<Movie>>) {
        final filteredMovies = _filterExcludedMovies(
          recommendations.data,
          excludeMovieIds ?? [],
        );

        return Success(RecommendationResult(
          movies: filteredMovies,
          source: 'personalized',
          metadata: {
            'user_genres': profile.preferredGenres,
            'rated_movies_count': ratedMovies.length,
            'page': page,
            'algorithm': 'hybrid_preference_based',
          },
          timestamp: DateTime.now(),
        ));
      } else {
        // Fall back to popular movies if personalized recommendations fail
        return await getPopularMovies(page: page, excludeMovieIds: excludeMovieIds);
      }
    } catch (e) {
      return ResultFailure(ApiFailure('Failed to generate personalized recommendations: ${e.toString()}'));
    }
  }

  @override
  Future<Result<RecommendationResult>> getGenreBasedRecommendations(
    List<String> genres, {
    int page = 1,
    List<int>? excludeMovieIds,
  }) async {
    try {
      if (genres.isEmpty) {
        return await getPopularMovies(page: page, excludeMovieIds: excludeMovieIds);
      }

      // Convert genre names to IDs
      final genreIds = await _convertGenreNamesToIds(genres);
      if (genreIds.isEmpty) {
        return await getPopularMovies(page: page, excludeMovieIds: excludeMovieIds);
      }

      // Discover movies by genres
      final result = await _movieRepository.discoverMovies(
        genreIds: genreIds,
        page: page,
        sortBy: 'popularity.desc',
      );

      if (result is Success<List<Movie>>) {
        final filteredMovies = _filterExcludedMovies(
          result.data,
          excludeMovieIds ?? [],
        );

        return Success(RecommendationResult(
          movies: filteredMovies,
          source: 'genre_based',
          metadata: {
            'genres': genres,
            'genre_ids': genreIds,
            'page': page,
            'sort_by': 'popularity.desc',
          },
          timestamp: DateTime.now(),
        ));
      } else {
        final failure = (result as ResultFailure<List<Movie>>).failure;
        return ResultFailure(failure);
      }
    } catch (e) {
      return ResultFailure(ApiFailure('Failed to generate genre-based recommendations: ${e.toString()}'));
    }
  }

  @override
  Future<Result<RecommendationResult>> getPopularMovies({
    int page = 1,
    List<int>? excludeMovieIds,
  }) async {
    try {
      // Get popular movies using discover endpoint
      final result = await _movieRepository.discoverMovies(
        page: page,
        sortBy: 'popularity.desc',
      );

      if (result is Success<List<Movie>>) {
        final filteredMovies = _filterExcludedMovies(
          result.data,
          excludeMovieIds ?? [],
        );

        return Success(RecommendationResult(
          movies: filteredMovies,
          source: 'popular',
          metadata: {
            'page': page,
            'sort_by': 'popularity.desc',
            'fallback': true,
          },
          timestamp: DateTime.now(),
        ));
      } else {
        final failure = (result as ResultFailure<List<Movie>>).failure;
        return ResultFailure(failure);
      }
    } catch (e) {
      return ResultFailure(ApiFailure('Failed to get popular movies: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Movie>>> getSimilarMovies(
    int movieId, {
    List<int>? excludeMovieIds,
  }) async {
    try {
      final result = await _movieRepository.getRecommendations(movieId);
      
      if (result is Success<List<Movie>>) {
        final filteredMovies = _filterExcludedMovies(
          result.data,
          excludeMovieIds ?? [],
        );
        return Success(filteredMovies);
      } else {
        final failure = (result as ResultFailure<List<Movie>>).failure;
        return ResultFailure(failure);
      }
    } catch (e) {
      return ResultFailure(ApiFailure('Failed to get similar movies: ${e.toString()}'));
    }
  }

  @override
  List<Movie> filterWatchedMovies(
    List<Movie> movies,
    List<int> watchedMovieIds,
  ) {
    return _filterExcludedMovies(movies, watchedMovieIds);
  }

  /// Generate personalized recommendations using hybrid approach
  Future<Result<List<Movie>>> _generatePersonalizedRecommendations(
    UserProfile profile,
    List<Movie> ratedMovies, {
    int page = 1,
    List<int>? excludeMovieIds,
  }) async {
    final allRecommendations = <Movie>[];
    final seenMovieIds = <int>{};

    // Strategy 1: Use highly rated movies to find similar ones
    if (ratedMovies.isNotEmpty) {
      final highlyRatedMovies = ratedMovies
          .where((movie) => (movie.userRating ?? 0) >= 7.0)
          .take(3) // Limit to top 3 to avoid too many API calls
          .toList();

      for (final movie in highlyRatedMovies) {
        final similarResult = await getSimilarMovies(
          movie.id,
          excludeMovieIds: excludeMovieIds,
        );
        
        if (similarResult is Success<List<Movie>>) {
          for (final similarMovie in similarResult.data.take(5)) {
            if (!seenMovieIds.contains(similarMovie.id)) {
              allRecommendations.add(similarMovie);
              seenMovieIds.add(similarMovie.id);
            }
          }
        }
      }
    }

    // Strategy 2: Genre-based recommendations from user preferences
    if (profile.preferredGenres.isNotEmpty) {
      final genreResult = await getGenreBasedRecommendations(
        profile.preferredGenres,
        page: page,
        excludeMovieIds: excludeMovieIds,
      );
      
      if (genreResult is Success<RecommendationResult>) {
        for (final movie in genreResult.data.movies.take(10)) {
          if (!seenMovieIds.contains(movie.id)) {
            allRecommendations.add(movie);
            seenMovieIds.add(movie.id);
          }
        }
      }
    }

    // Strategy 3: Fill remaining slots with popular movies if needed
    if (allRecommendations.length < 20) {
      final popularResult = await getPopularMovies(
        page: page,
        excludeMovieIds: excludeMovieIds,
      );
      
      if (popularResult is Success<RecommendationResult>) {
        for (final movie in popularResult.data.movies) {
          if (!seenMovieIds.contains(movie.id) && allRecommendations.length < 20) {
            allRecommendations.add(movie);
            seenMovieIds.add(movie.id);
          }
        }
      }
    }

    // Score and sort recommendations based on user preferences
    final scoredRecommendations = _scoreRecommendations(
      allRecommendations,
      profile,
      ratedMovies,
    );

    return Success(scoredRecommendations);
  }

  /// Score recommendations based on user preferences and viewing history
  List<Movie> _scoreRecommendations(
    List<Movie> movies,
    UserProfile profile,
    List<Movie> ratedMovies,
  ) {
    final movieScores = <Movie, double>{};
    
    // Calculate genre preferences from rated movies
    final genreScores = _calculateGenrePreferences(ratedMovies);
    
    for (final movie in movies) {
      double score = movie.voteAverage; // Base score from TMDb rating
      
      // Boost score based on preferred genres
      for (final genre in movie.genres) {
        if (profile.preferredGenres.contains(genre.name)) {
          score += 2.0; // Significant boost for preferred genres
        }
        
        // Additional boost based on learned preferences from rated movies
        final genreScore = genreScores[genre.name] ?? 0.0;
        score += genreScore * 0.5;
      }
      
      // Boost newer movies slightly
      final releaseYear = _extractYear(movie.releaseDate);
      if (releaseYear != null && releaseYear >= DateTime.now().year - 3) {
        score += 0.5;
      }
      
      movieScores[movie] = score;
    }
    
    // Sort by score descending
    final sortedMovies = movieScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMovies.map((entry) => entry.key).toList();
  }

  /// Calculate genre preferences based on user's rated movies
  Map<String, double> _calculateGenrePreferences(List<Movie> ratedMovies) {
    final genreScores = <String, double>{};
    final genreCounts = <String, int>{};
    
    for (final movie in ratedMovies) {
      final rating = movie.userRating ?? 0.0;
      
      for (final genre in movie.genres) {
        genreScores[genre.name] = (genreScores[genre.name] ?? 0.0) + rating;
        genreCounts[genre.name] = (genreCounts[genre.name] ?? 0) + 1;
      }
    }
    
    // Calculate average scores for each genre
    final averageScores = <String, double>{};
    for (final genre in genreScores.keys) {
      final totalScore = genreScores[genre]!;
      final count = genreCounts[genre]!;
      averageScores[genre] = totalScore / count;
    }
    
    return averageScores;
  }

  /// Convert genre names to TMDb genre IDs
  Future<List<int>> _convertGenreNamesToIds(List<String> genreNames) async {
    // Load genres if not already loaded
    if (!_genresLoaded) {
      await _loadGenres();
    }
    
    final genreIds = <int>[];
    for (final genreName in genreNames) {
      final genreId = _genreNameToIdMap[genreName.toLowerCase()];
      if (genreId != null) {
        genreIds.add(genreId);
      }
    }
    
    return genreIds;
  }

  /// Load and cache genre mappings
  Future<void> _loadGenres() async {
    try {
      final result = await _movieRepository.getGenres();
      if (result is Success<List<Genre>>) {
        _genreNameToIdMap.clear();
        for (final genre in result.data) {
          _genreNameToIdMap[genre.name.toLowerCase()] = genre.id;
        }
        _genresLoaded = true;
      }
    } catch (e) {
      // Silently fail - will use empty genre map
    }
  }

  /// Filter out excluded movies
  List<Movie> _filterExcludedMovies(List<Movie> movies, List<int> excludeIds) {
    if (excludeIds.isEmpty) return movies;
    
    return movies.where((movie) => !excludeIds.contains(movie.id)).toList();
  }

  /// Extract year from release date string
  int? _extractYear(String releaseDate) {
    try {
      if (releaseDate.isNotEmpty) {
        return DateTime.parse(releaseDate).year;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }
}