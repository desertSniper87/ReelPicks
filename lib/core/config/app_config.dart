import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration class
class AppConfig {
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static String get tmdbBaseUrl => dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';
  static String get tmdbImageBaseUrl => dotenv.env['TMDB_IMAGE_BASE_URL'] ?? 'https://image.tmdb.org/t/p/w500';
  
  /// Initialize the configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }
  
  /// Validate that required configuration is present
  static bool validateConfig() {
    return tmdbApiKey.isNotEmpty;
  }
}