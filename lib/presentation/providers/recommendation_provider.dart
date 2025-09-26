import 'package:flutter/foundation.dart';
import '../../data/models/movie.dart';
import '../../data/models/user_profile.dart';
import '../../domain/services/recommendation_service.dart';
import '../../domain/repositories/movie_repository.dart';

/// Provider for managing movie recommendation state
class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _recommendationService;
  final MovieRepository _movieRepository;

  List<Movie> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  int _currentIndex = 0;
  List<String> _selectedGenres = [];
  String _currentSource = 'popular'; // 'personalized', 'genre', 'popular'
  int _currentPage = 1;
  bool _hasMorePages = true;
  final List<int> _excludedMovieIds = [];

  RecommendationProvider({
    required RecommendationService recommendationService,
    required MovieRepository movieRepository,
  }) : _recommendationService = recommendationService,
       _movieRepository = movieRepository;

  // Getters
  List<Movie> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  List<String> get selectedGenres => _selectedGenres;
  String get currentSource => _currentSource;
  bool get hasMorePages => _hasMorePages;
  Movie? get currentMovie => 
      _recommendations.isNotEmpty && _currentIndex < _recommendations.length
          ? _recommendations[_currentIndex]
          : null;

  // Loading state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error state management
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Recommendation management
  void _setRecommendations(List<Movie> recommendations, {bool append = false}) {
    if (append) {
      _recommendations.addAll(recommendations);
    } else {
      _recommendations = recommendations;
      _currentIndex = 0;
    }
    notifyListeners();
  }

  /// Load personalized recommendations based on user profile
  Future<void> loadPersonalizedRecommendations(UserProfile userProfile, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _excludedMovieIds.clear();
    }

    _setLoading(true);
    _setError(null);
    _currentSource = 'personalized';

    try {
      final result = await _recommendationService.getPersonalizedRecommendations(
        userProfile,
        page: _currentPage,
        excludeMovieIds: _excludedMovieIds,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (recommendationResult) {
          _setRecommendations(recommendationResult.movies, append: !refresh && _currentPage > 1);
          _hasMorePages = recommendationResult.movies.length >= 20; // Assuming 20 per page
          if (!refresh) _currentPage++;
        },
      );
    } catch (e) {
      _setError('Failed to load personalized recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load genre-based recommendations
  Future<void> loadGenreRecommendations(List<String> genres, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _excludedMovieIds.clear();
    }

    _setLoading(true);
    _setError(null);
    _currentSource = 'genre';
    _selectedGenres = List.from(genres);

    try {
      final result = await _recommendationService.getGenreBasedRecommendations(
        genres,
        page: _currentPage,
        excludeMovieIds: _excludedMovieIds,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (recommendationResult) {
          _setRecommendations(recommendationResult.movies, append: !refresh && _currentPage > 1);
          _hasMorePages = recommendationResult.movies.length >= 20;
          if (!refresh) _currentPage++;
        },
      );
    } catch (e) {
      _setError('Failed to load genre recommendations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load popular movies as fallback
  Future<void> loadPopularMovies({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _excludedMovieIds.clear();
    }

    _setLoading(true);
    _setError(null);
    _currentSource = 'popular';

    try {
      final result = await _recommendationService.getPopularMovies(
        page: _currentPage,
        excludeMovieIds: _excludedMovieIds,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (recommendationResult) {
          _setRecommendations(recommendationResult.movies, append: !refresh && _currentPage > 1);
          _hasMorePages = recommendationResult.movies.length >= 20;
          if (!refresh) _currentPage++;
        },
      );
    } catch (e) {
      _setError('Failed to load popular movies: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load more recommendations (pagination)
  Future<void> loadMoreRecommendations(UserProfile? userProfile) async {
    if (_isLoading || !_hasMorePages) return;

    switch (_currentSource) {
      case 'personalized':
        if (userProfile != null) {
          await loadPersonalizedRecommendations(userProfile);
        }
        break;
      case 'genre':
        await loadGenreRecommendations(_selectedGenres);
        break;
      case 'popular':
        await loadPopularMovies();
        break;
    }
  }

  /// Refresh current recommendations
  Future<void> refreshRecommendations(UserProfile? userProfile) async {
    switch (_currentSource) {
      case 'personalized':
        if (userProfile != null) {
          await loadPersonalizedRecommendations(userProfile, refresh: true);
        } else {
          await loadPopularMovies(refresh: true);
        }
        break;
      case 'genre':
        await loadGenreRecommendations(_selectedGenres, refresh: true);
        break;
      case 'popular':
        await loadPopularMovies(refresh: true);
        break;
    }
  }

  /// Rate a movie and exclude it from future recommendations
  Future<bool> rateMovie(int movieId, double rating) async {
    try {
      final result = await _movieRepository.rateMovie(movieId, rating);
      return result.fold(
        (failure) {
          _setError('Failed to rate movie: ${failure.message}');
          return false;
        },
        (success) {
          if (success) {
            _excludedMovieIds.add(movieId);
            // Remove the movie from current recommendations if it exists
            _recommendations.removeWhere((movie) => movie.id == movieId);
            // Adjust current index if necessary
            if (_currentIndex >= _recommendations.length && _recommendations.isNotEmpty) {
              _currentIndex = _recommendations.length - 1;
            }
            notifyListeners();
          }
          return success;
        },
      );
    } catch (e) {
      _setError('Failed to rate movie: ${e.toString()}');
      return false;
    }
  }

  // Navigation
  void nextMovie() {
    if (_currentIndex < _recommendations.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousMovie() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _recommendations.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Genre filtering
  void setSelectedGenres(List<String> genres) {
    _selectedGenres = List.from(genres);
    notifyListeners();
  }

  void addGenre(String genre) {
    if (!_selectedGenres.contains(genre)) {
      _selectedGenres.add(genre);
      notifyListeners();
    }
  }

  void removeGenre(String genre) {
    _selectedGenres.remove(genre);
    notifyListeners();
  }

  void clearGenres() {
    _selectedGenres.clear();
    notifyListeners();
  }

  /// Apply genre filter to current recommendations
  Future<void> applyGenreFilter(List<String> genres, UserProfile? userProfile) async {
    if (genres.isEmpty) {
      // If no genres selected, load appropriate recommendations
      if (userProfile?.isAuthenticated == true) {
        await loadPersonalizedRecommendations(userProfile!, refresh: true);
      } else {
        await loadPopularMovies(refresh: true);
      }
    } else {
      await loadGenreRecommendations(genres, refresh: true);
    }
  }

  // Clear all data
  void clear() {
    _recommendations.clear();
    _currentIndex = 0;
    _error = null;
    _isLoading = false;
    _selectedGenres.clear();
    _currentSource = 'popular';
    _currentPage = 1;
    _hasMorePages = true;
    _excludedMovieIds.clear();
    notifyListeners();
  }

  /// Check if we need to load more recommendations (for infinite scroll)
  bool shouldLoadMore(int index) {
    return index >= _recommendations.length - 5 && _hasMorePages && !_isLoading;
  }
}