import 'package:flutter/foundation.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';

/// Provider for managing user preferences and profile connections
class UserProvider extends ChangeNotifier {
  UserPreferences? _userPreferences;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserPreferences? get userPreferences => _userPreferences;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userProfile?.isAuthenticated ?? false;

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error state management
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // User preferences management
  void setUserPreferences(UserPreferences preferences) {
    _userPreferences = preferences;
    notifyListeners();
  }

  void updatePreferredGenres(List<String> genres) {
    if (_userPreferences != null) {
      _userPreferences = _userPreferences!.copyWith(preferredGenres: genres);
      notifyListeners();
    }
  }

  void updateImdbProfile(String profileUrl) {
    if (_userPreferences != null) {
      _userPreferences = _userPreferences!.copyWith(imdbProfileUrl: profileUrl);
      notifyListeners();
    }
  }

  void updateLetterboxdProfile(String username) {
    if (_userPreferences != null) {
      _userPreferences = _userPreferences!.copyWith(letterboxdUsername: username);
      notifyListeners();
    }
  }

  void updatePersonalizationEnabled(bool enabled) {
    if (_userPreferences != null) {
      _userPreferences = _userPreferences!.copyWith(enablePersonalization: enabled);
      notifyListeners();
    }
  }

  void updateDefaultViewMode(ViewMode viewMode) {
    if (_userPreferences != null) {
      _userPreferences = _userPreferences!.copyWith(defaultViewMode: viewMode);
      notifyListeners();
    }
  }

  // User profile management
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  void updateTmdbSession(String sessionId, int accountId) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        tmdbSessionId: sessionId,
        tmdbAccountId: accountId,
        isAuthenticated: true,
      );
    } else {
      _userProfile = UserProfile(
        tmdbSessionId: sessionId,
        tmdbAccountId: accountId,
        preferredGenres: const [],
        isAuthenticated: true,
      );
    }
    notifyListeners();
  }

  void updateImdbUsername(String username) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(imdbUsername: username);
    } else {
      _userProfile = UserProfile(
        imdbUsername: username,
        preferredGenres: const [],
      );
    }
    notifyListeners();
  }

  void updateLetterboxdUsername(String username) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(letterboxdUsername: username);
    } else {
      _userProfile = UserProfile(
        letterboxdUsername: username,
        preferredGenres: const [],
      );
    }
    notifyListeners();
  }

  // Clear user data
  void clearUserData() {
    _userPreferences = null;
    _userProfile = null;
    _error = null;
    notifyListeners();
  }

  void logout() {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        tmdbSessionId: null,
        tmdbAccountId: null,
        isAuthenticated: false,
      );
      notifyListeners();
    }
  }
}