import '../../core/utils/result.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';

/// Abstract user repository interface
abstract class UserRepository {
  /// Save user preferences locally
  Future<Result<void>> saveUserPreferences(UserPreferences preferences);
  
  /// Get user preferences from local storage
  Future<Result<UserPreferences?>> getUserPreferences();
  
  /// Save TMDb session and account information
  Future<Result<void>> saveUserProfile(UserProfile profile);
  
  /// Get user profile from local storage
  Future<Result<UserProfile?>> getUserProfile();
  
  /// Save IMDb profile connection
  Future<Result<void>> saveImdbProfile(String profileUrl);
  
  /// Save Letterboxd profile connection
  Future<Result<void>> saveLetterboxdProfile(String username);
  
  /// Save genre preferences
  Future<Result<void>> saveGenrePreferences(List<String> genres);
  
  /// Get genre preferences
  Future<Result<List<String>>> getGenrePreferences();
  
  /// Clear all user data
  Future<Result<void>> clearUserData();
}