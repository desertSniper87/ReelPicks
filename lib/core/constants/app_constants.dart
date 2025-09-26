/// Application constants
class AppConstants {
  // App information
  static const String appName = 'Movie Recommendations';
  static const String appVersion = '1.0.0';
  
  // Cache durations
  static const Duration movieCacheDuration = Duration(hours: 24);
  static const Duration recommendationCacheDuration = Duration(hours: 6);
  static const Duration userPreferencesCacheDuration = Duration(days: 365);
  
  // UI constants
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxRecommendations = 100;
}