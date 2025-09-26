import 'package:flutter/foundation.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/movie.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/movie_repository.dart';

/// Provider for managing user preferences and profile connections
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final MovieRepository _movieRepository;

  UserPreferences? _userPreferences;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserProvider({
    required UserRepository userRepository,
    required MovieRepository movieRepository,
  }) : _userRepository = userRepository,
       _movieRepository = movieRepository;

  // Getters
  UserPreferences? get userPreferences => _userPreferences;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userProfile?.isAuthenticated ?? false;
  bool get isInitialized => _isInitialized;

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

  /// Initialize user data from local storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _setError(null);

    try {
      // Load user preferences
      final preferencesResult = await _userRepository.getUserPreferences();
      preferencesResult.fold(
        (failure) => _setError('Failed to load preferences: ${failure.message}'),
        (preferences) => _userPreferences = preferences,
      );

      // Load user profile
      final profileResult = await _userRepository.getUserProfile();
      profileResult.fold(
        (failure) => _setError('Failed to load profile: ${failure.message}'),
        (profile) => _userProfile = profile,
      );

      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize user data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // User preferences management
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _userRepository.saveUserPreferences(preferences);
      result.fold(
        (failure) => _setError('Failed to save preferences: ${failure.message}'),
        (_) {
          _userPreferences = preferences;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Failed to save preferences: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePreferredGenres(List<String> genres) async {
    if (_userPreferences != null) {
      final updatedPreferences = _userPreferences!.copyWith(preferredGenres: genres);
      await saveUserPreferences(updatedPreferences);
    } else {
      // Create new preferences if none exist
      final newPreferences = UserPreferences(
        preferredGenres: genres,
        enablePersonalization: true,
        defaultViewMode: ViewMode.swipe,
      );
      await saveUserPreferences(newPreferences);
    }
  }

  Future<void> updateImdbProfile(String profileUrl) async {
    if (_userPreferences != null) {
      final updatedPreferences = _userPreferences!.copyWith(imdbProfileUrl: profileUrl);
      await saveUserPreferences(updatedPreferences);
    } else {
      final newPreferences = UserPreferences(
        preferredGenres: const [],
        imdbProfileUrl: profileUrl,
        enablePersonalization: true,
        defaultViewMode: ViewMode.swipe,
      );
      await saveUserPreferences(newPreferences);
    }
  }



  Future<void> updatePersonalizationEnabled(bool enabled) async {
    if (_userPreferences != null) {
      final updatedPreferences = _userPreferences!.copyWith(enablePersonalization: enabled);
      await saveUserPreferences(updatedPreferences);
    } else {
      final newPreferences = UserPreferences(
        preferredGenres: const [],
        enablePersonalization: enabled,
        defaultViewMode: ViewMode.swipe,
      );
      await saveUserPreferences(newPreferences);
    }
  }

  Future<void> updateDefaultViewMode(ViewMode viewMode) async {
    if (_userPreferences != null) {
      final updatedPreferences = _userPreferences!.copyWith(defaultViewMode: viewMode);
      await saveUserPreferences(updatedPreferences);
    } else {
      final newPreferences = UserPreferences(
        preferredGenres: const [],
        enablePersonalization: true,
        defaultViewMode: viewMode,
      );
      await saveUserPreferences(newPreferences);
    }
  }

  // User profile management
  Future<void> saveUserProfile(UserProfile profile) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _userRepository.saveUserProfile(profile);
      result.fold(
        (failure) => _setError('Failed to save profile: ${failure.message}'),
        (_) {
          _userProfile = profile;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Failed to save profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTmdbSession(String sessionId, int accountId) async {
    UserProfile updatedProfile;
    if (_userProfile != null) {
      updatedProfile = _userProfile!.copyWith(
        tmdbSessionId: sessionId,
        tmdbAccountId: accountId,
        isAuthenticated: true,
      );
    } else {
      updatedProfile = UserProfile(
        tmdbSessionId: sessionId,
        tmdbAccountId: accountId,
        preferredGenres: const [],
        isAuthenticated: true,
      );
    }
    await saveUserProfile(updatedProfile);
  }

  Future<void> updateImdbUsername(String username) async {
    UserProfile updatedProfile;
    if (_userProfile != null) {
      updatedProfile = _userProfile!.copyWith(imdbUsername: username);
    } else {
      updatedProfile = UserProfile(
        imdbUsername: username,
        preferredGenres: const [],
      );
    }
    await saveUserProfile(updatedProfile);
  }

  Future<void> updateLetterboxdUsername(String username) async {
    UserProfile updatedProfile;
    if (_userProfile != null) {
      updatedProfile = _userProfile!.copyWith(letterboxdUsername: username);
    } else {
      updatedProfile = UserProfile(
        letterboxdUsername: username,
        preferredGenres: const [],
      );
    }
    await saveUserProfile(updatedProfile);
  }

  // Clear user data
  Future<void> clearUserData() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _userRepository.clearUserData();
      result.fold(
        (failure) => _setError('Failed to clear user data: ${failure.message}'),
        (_) {
          _userPreferences = null;
          _userProfile = null;
          _isInitialized = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Failed to clear user data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(
        tmdbSessionId: null,
        tmdbAccountId: null,
        isAuthenticated: false,
      );
      await saveUserProfile(updatedProfile);
    } else {
      // Create a new profile with logged out state
      final loggedOutProfile = UserProfile(
        preferredGenres: const [],
        isAuthenticated: false,
      );
      await saveUserProfile(loggedOutProfile);
    }
  }

  /// Refresh user data from storage
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  // Movie rating operations
  Future<void> rateMovie(int movieId, double rating) async {
    _setLoading(true);
    _setError(null);

    try {
      // Ensure authentication details are set
      if (_userProfile?.tmdbSessionId != null && _userProfile?.tmdbAccountId != null) {
        _movieRepository.setAuthenticationDetails(
          sessionId: _userProfile!.tmdbSessionId,
          accountId: _userProfile!.tmdbAccountId,
        );
      }

      final result = await _movieRepository.rateMovie(movieId, rating);
      result.fold(
        (failure) => _setError('Failed to rate movie: ${failure.message}'),
        (_) {
          // Rating successful
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Failed to rate movie: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMovieRating(int movieId) async {
    _setLoading(true);
    _setError(null);

    try {
      // Ensure authentication details are set
      if (_userProfile?.tmdbSessionId != null && _userProfile?.tmdbAccountId != null) {
        _movieRepository.setAuthenticationDetails(
          sessionId: _userProfile!.tmdbSessionId,
          accountId: _userProfile!.tmdbAccountId,
        );
      }

      final result = await _movieRepository.deleteRating(movieId);
      result.fold(
        (failure) => _setError('Failed to delete rating: ${failure.message}'),
        (_) {
          // Rating deletion successful
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Failed to delete rating: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Movie>> getRatedMovies() async {
    try {
      // Ensure authentication details are set
      if (_userProfile?.tmdbSessionId != null && _userProfile?.tmdbAccountId != null) {
        _movieRepository.setAuthenticationDetails(
          sessionId: _userProfile!.tmdbSessionId,
          accountId: _userProfile!.tmdbAccountId,
        );
      }

      final result = await _movieRepository.getRatedMovies();
      return result.fold(
        (failure) {
          _setError('Failed to get rated movies: ${failure.message}');
          return <Movie>[];
        },
        (movies) => movies,
      );
    } catch (e) {
      _setError('Failed to get rated movies: ${e.toString()}');
      return <Movie>[];
    }
  }

  Future<List<Movie>> getWatchlist() async {
    try {
      // Ensure authentication details are set
      if (_userProfile?.tmdbSessionId != null && _userProfile?.tmdbAccountId != null) {
        _movieRepository.setAuthenticationDetails(
          sessionId: _userProfile!.tmdbSessionId,
          accountId: _userProfile!.tmdbAccountId,
        );
      }

      final result = await _movieRepository.getWatchlist();
      return result.fold(
        (failure) {
          _setError('Failed to get watchlist: ${failure.message}');
          return <Movie>[];
        },
        (movies) => movies,
      );
    } catch (e) {
      _setError('Failed to get watchlist: ${e.toString()}');
      return <Movie>[];
    }
  }

  // Profile management methods for external services
  Future<void> updateIMDbProfile(String username) async {
    await updateImdbUsername(username);
    
    // Also update preferences if needed
    if (_userPreferences != null) {
      final updatedPreferences = _userPreferences!.copyWith(
        imdbProfileUrl: 'https://www.imdb.com/user/$username/',
      );
      await saveUserPreferences(updatedPreferences);
    }
  }

  Future<void> updateLetterboxdProfile(String username) async {
    await updateLetterboxdUsername(username);
    
    // Also update preferences if needed
    if (_userPreferences != null) {
      final updatedPreferences = _userPreferences!.copyWith(
        letterboxdUsername: username,
      );
      await saveUserPreferences(updatedPreferences);
    }
  }
}