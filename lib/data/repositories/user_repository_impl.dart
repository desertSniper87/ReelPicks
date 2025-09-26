import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_preferences.dart';
import '../models/user_profile.dart';

/// Implementation of UserRepository for local storage
class UserRepositoryImpl implements UserRepository {
  static const String _userPreferencesKey = 'user_preferences';
  static const String _userProfileKey = 'user_profile';
  static const String _tmdbSessionKey = 'tmdb_session_id';
  static const String _tmdbAccountKey = 'tmdb_account_id';
  static const String _imdbProfileKey = 'imdb_profile_url';
  static const String _letterboxdUsernameKey = 'letterboxd_username';
  static const String _genrePreferencesKey = 'genre_preferences';

  final SharedPreferences _sharedPreferences;
  final FlutterSecureStorage _secureStorage;

  UserRepositoryImpl({
    required SharedPreferences sharedPreferences,
    required FlutterSecureStorage secureStorage,
  })  : _sharedPreferences = sharedPreferences,
        _secureStorage = secureStorage;

  @override
  Future<Result<void>> saveUserPreferences(UserPreferences preferences) async {
    try {
      final jsonString = jsonEncode(preferences.toJson());
      await _sharedPreferences.setString(_userPreferencesKey, jsonString);
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to save user preferences: $e'),
      );
    }
  }

  @override
  Future<Result<UserPreferences?>> getUserPreferences() async {
    try {
      final jsonString = _sharedPreferences.getString(_userPreferencesKey);
      if (jsonString == null) {
        return const Success(null);
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final preferences = UserPreferences.fromJson(json);
      return Success(preferences);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to get user preferences: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveUserProfile(UserProfile profile) async {
    try {
      // Save sensitive data (session ID) in secure storage
      if (profile.tmdbSessionId != null) {
        await _secureStorage.write(
          key: _tmdbSessionKey,
          value: profile.tmdbSessionId,
        );
      }

      // Save non-sensitive profile data in shared preferences
      final profileData = profile.toJson();
      // Remove session ID from shared preferences data
      profileData.remove('tmdb_session_id');
      
      final jsonString = jsonEncode(profileData);
      await _sharedPreferences.setString(_userProfileKey, jsonString);
      
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to save user profile: $e'),
      );
    }
  }

  @override
  Future<Result<UserProfile?>> getUserProfile() async {
    try {
      final jsonString = _sharedPreferences.getString(_userProfileKey);
      if (jsonString == null) {
        return const Success(null);
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Get session ID from secure storage
      final sessionId = await _secureStorage.read(key: _tmdbSessionKey);
      if (sessionId != null) {
        json['tmdb_session_id'] = sessionId;
      }

      final profile = UserProfile.fromJson(json);
      return Success(profile);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to get user profile: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveImdbProfile(String profileUrl) async {
    try {
      await _sharedPreferences.setString(_imdbProfileKey, profileUrl);
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to save IMDb profile: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveLetterboxdProfile(String username) async {
    try {
      await _sharedPreferences.setString(_letterboxdUsernameKey, username);
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to save Letterboxd profile: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveGenrePreferences(List<String> genres) async {
    try {
      await _sharedPreferences.setStringList(_genrePreferencesKey, genres);
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to save genre preferences: $e'),
      );
    }
  }

  @override
  Future<Result<List<String>>> getGenrePreferences() async {
    try {
      final genres = _sharedPreferences.getStringList(_genrePreferencesKey);
      return Success(genres ?? []);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to get genre preferences: $e'),
      );
    }
  }

  @override
  Future<Result<void>> clearUserData() async {
    try {
      // Clear shared preferences data
      await _sharedPreferences.remove(_userPreferencesKey);
      await _sharedPreferences.remove(_userProfileKey);
      await _sharedPreferences.remove(_imdbProfileKey);
      await _sharedPreferences.remove(_letterboxdUsernameKey);
      await _sharedPreferences.remove(_genrePreferencesKey);

      // Clear secure storage data
      await _secureStorage.delete(key: _tmdbSessionKey);
      await _secureStorage.delete(key: _tmdbAccountKey);

      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to clear user data: $e'),
      );
    }
  }

  /// Additional helper methods for specific operations

  /// Save TMDb session ID securely
  Future<Result<void>> saveTmdbSession(String sessionId) async {
    try {
      await _secureStorage.write(key: _tmdbSessionKey, value: sessionId);
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to save TMDb session: $e'),
      );
    }
  }

  /// Get TMDb session ID from secure storage
  Future<Result<String?>> getTmdbSession() async {
    try {
      final sessionId = await _secureStorage.read(key: _tmdbSessionKey);
      return Success(sessionId);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to get TMDb session: $e'),
      );
    }
  }

  /// Save TMDb account ID
  Future<Result<void>> saveTmdbAccountId(int accountId) async {
    try {
      await _secureStorage.write(
        key: _tmdbAccountKey,
        value: accountId.toString(),
      );
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to save TMDb account ID: $e'),
      );
    }
  }

  /// Get TMDb account ID
  Future<Result<int?>> getTmdbAccountId() async {
    try {
      final accountIdString = await _secureStorage.read(key: _tmdbAccountKey);
      if (accountIdString == null) {
        return const Success(null);
      }
      final accountId = int.tryParse(accountIdString);
      return Success(accountId);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to get TMDb account ID: $e'),
      );
    }
  }

  /// Check if user has any stored preferences
  Future<Result<bool>> hasUserData() async {
    try {
      final hasPreferences = _sharedPreferences.containsKey(_userPreferencesKey);
      final hasProfile = _sharedPreferences.containsKey(_userProfileKey);
      final hasSession = await _secureStorage.containsKey(key: _tmdbSessionKey);
      
      return Success(hasPreferences || hasProfile || hasSession);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to check user data: $e'),
      );
    }
  }

  /// Get IMDb profile URL
  Future<Result<String?>> getImdbProfile() async {
    try {
      final profileUrl = _sharedPreferences.getString(_imdbProfileKey);
      return Success(profileUrl);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to get IMDb profile: $e'),
      );
    }
  }

  /// Get Letterboxd username
  Future<Result<String?>> getLetterboxdProfile() async {
    try {
      final username = _sharedPreferences.getString(_letterboxdUsernameKey);
      return Success(username);
    } catch (e) {
      return ResultFailure(
        LocalStorageFailure('Failed to get Letterboxd profile: $e'),
      );
    }
  }
}