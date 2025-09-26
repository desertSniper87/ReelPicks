import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../error/failures.dart';
import '../../data/models/movie.dart';
import '../../data/models/recommendation_result.dart';

class CacheManager {
  static const String _movieCachePrefix = 'movie_cache_';
  static const String _recommendationCachePrefix = 'recommendation_cache_';
  static const String _genreCacheKey = 'genres_cache';
  static const String _userRatedMoviesKey = 'user_rated_movies';
  static const String _userWatchlistKey = 'user_watchlist';
  
  // Cache durations
  static const Duration movieCacheDuration = Duration(hours: 24);
  static const Duration recommendationCacheDuration = Duration(hours: 6);
  static const Duration genreCacheDuration = Duration(days: 7);
  static const Duration userDataCacheDuration = Duration(hours: 1);

  static Future<void> cacheMovie(Movie movie) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': movie.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(
        '$_movieCachePrefix${movie.id}',
        jsonEncode(cacheData),
      );
    } catch (e) {
      throw CacheFailure('Failed to cache movie: ${e.toString()}');
    }
  }

  static Future<Movie?> getCachedMovie(int movieId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_movieCachePrefix$movieId');
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
      
      if (DateTime.now().difference(timestamp) > movieCacheDuration) {
        await prefs.remove('$_movieCachePrefix$movieId');
        return null;
      }
      
      return Movie.fromJson(cacheData['data']);
    } catch (e) {
      throw CacheFailure('Failed to retrieve cached movie: ${e.toString()}');
    }
  }

  static Future<void> cacheRecommendations(
    RecommendationResult recommendations,
    String cacheKey,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': recommendations.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(
        '$_recommendationCachePrefix$cacheKey',
        jsonEncode(cacheData),
      );
    } catch (e) {
      throw CacheFailure('Failed to cache recommendations: ${e.toString()}');
    }
  }

  static Future<RecommendationResult?> getCachedRecommendations(
    String cacheKey,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_recommendationCachePrefix$cacheKey');
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
      
      if (DateTime.now().difference(timestamp) > recommendationCacheDuration) {
        await prefs.remove('$_recommendationCachePrefix$cacheKey');
        return null;
      }
      
      return RecommendationResult.fromJson(cacheData['data']);
    } catch (e) {
      throw CacheFailure('Failed to retrieve cached recommendations: ${e.toString()}');
    }
  }

  static Future<void> cacheGenres(List<Map<String, dynamic>> genres) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': genres,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_genreCacheKey, jsonEncode(cacheData));
    } catch (e) {
      throw CacheFailure('Failed to cache genres: ${e.toString()}');
    }
  }

  static Future<List<Map<String, dynamic>>?> getCachedGenres() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_genreCacheKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
      
      if (DateTime.now().difference(timestamp) > genreCacheDuration) {
        await prefs.remove(_genreCacheKey);
        return null;
      }
      
      return List<Map<String, dynamic>>.from(cacheData['data']);
    } catch (e) {
      throw CacheFailure('Failed to retrieve cached genres: ${e.toString()}');
    }
  }

  static Future<void> cacheUserRatedMovies(List<Movie> movies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': movies.map((m) => m.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_userRatedMoviesKey, jsonEncode(cacheData));
    } catch (e) {
      throw CacheFailure('Failed to cache user rated movies: ${e.toString()}');
    }
  }

  static Future<List<Movie>?> getCachedUserRatedMovies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_userRatedMoviesKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
      
      if (DateTime.now().difference(timestamp) > userDataCacheDuration) {
        await prefs.remove(_userRatedMoviesKey);
        return null;
      }
      
      final movieList = List<Map<String, dynamic>>.from(cacheData['data']);
      return movieList.map((json) => Movie.fromJson(json)).toList().cast<Movie>();
    } catch (e) {
      throw CacheFailure('Failed to retrieve cached user rated movies: ${e.toString()}');
    }
  }

  static Future<void> cacheUserWatchlist(List<Movie> movies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': movies.map((m) => m.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_userWatchlistKey, jsonEncode(cacheData));
    } catch (e) {
      throw CacheFailure('Failed to cache user watchlist: ${e.toString()}');
    }
  }

  static Future<List<Movie>?> getCachedUserWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_userWatchlistKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
      
      if (DateTime.now().difference(timestamp) > userDataCacheDuration) {
        await prefs.remove(_userWatchlistKey);
        return null;
      }
      
      final movieList = List<Map<String, dynamic>>.from(cacheData['data']);
      return movieList.map((json) => Movie.fromJson(json)).toList().cast<Movie>();
    } catch (e) {
      throw CacheFailure('Failed to retrieve cached user watchlist: ${e.toString()}');
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_movieCachePrefix) ||
            key.startsWith(_recommendationCachePrefix) ||
            key == _genreCacheKey ||
            key == _userRatedMoviesKey ||
            key == _userWatchlistKey) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      throw CacheFailure('Failed to clear cache: ${e.toString()}');
    }
  }

  static Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();
      
      for (final key in keys) {
        if (key.startsWith(_movieCachePrefix) ||
            key.startsWith(_recommendationCachePrefix) ||
            key == _genreCacheKey ||
            key == _userRatedMoviesKey ||
            key == _userWatchlistKey) {
          
          final cacheString = prefs.getString(key);
          if (cacheString != null) {
            try {
              final cacheData = jsonDecode(cacheString);
              final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
              
              Duration maxAge;
              if (key.startsWith(_movieCachePrefix)) {
                maxAge = movieCacheDuration;
              } else if (key.startsWith(_recommendationCachePrefix)) {
                maxAge = recommendationCacheDuration;
              } else if (key == _genreCacheKey) {
                maxAge = genreCacheDuration;
              } else {
                maxAge = userDataCacheDuration;
              }
              
              if (now.difference(timestamp) > maxAge) {
                await prefs.remove(key);
              }
            } catch (e) {
              // If we can't parse the cache data, remove it
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      throw CacheFailure('Failed to clear expired cache: ${e.toString()}');
    }
  }
}