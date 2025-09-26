import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/movie.dart';

/// TMDb API client for movie data and user interactions
class TMDbClient {
  final http.Client _httpClient;
  final Map<String, DateTime> _requestTimestamps = {};
  final Map<String, dynamic> _cache = {};
  static const Duration _cacheExpiration = Duration(hours: 1);
  
  TMDbClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Get API key from environment
  String get _apiKey {
    final apiKey = dotenv.env['TMDB_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw const ApiException('TMDb API key not found in environment variables');
    }
    return apiKey;
  }

  /// Get base URL from environment
  String get _baseUrl {
    return dotenv.env['TMDB_BASE_URL'] ?? ApiConstants.tmdbBaseUrl;
  }

  /// Build complete URL with API key
  String _buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final params = <String, String>{
      'api_key': _apiKey,
      ...?queryParams,
    };
    return uri.replace(queryParameters: params).toString();
  }

  /// Rate limiting check
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    final windowStart = now.subtract(ApiConstants.rateLimitWindow);
    
    // Remove old timestamps
    _requestTimestamps.removeWhere((key, timestamp) => timestamp.isBefore(windowStart));
    
    // Check if we've exceeded the rate limit
    if (_requestTimestamps.length >= ApiConstants.maxRequestsPerWindow) {
      final oldestRequest = _requestTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
      final waitTime = oldestRequest.add(ApiConstants.rateLimitWindow).difference(now);
      if (waitTime.isNegative == false) {
        await Future.delayed(waitTime);
      }
    }
    
    // Record this request
    _requestTimestamps[now.millisecondsSinceEpoch.toString()] = now;
  }

  /// Generic HTTP GET request with error handling
  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? queryParams, bool useCache = true}) async {
    await _checkRateLimit();
    
    final url = _buildUrl(endpoint, queryParams: queryParams);
    final cacheKey = url;
    
    // Check cache first
    if (useCache && _cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey];
      final cacheTime = cachedData['timestamp'] as DateTime;
      if (DateTime.now().difference(cacheTime) < _cacheExpiration) {
        return cachedData['data'] as Map<String, dynamic>;
      }
    }
    
    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);
      
      // Cache the response
      if (useCache) {
        _cache[cacheKey] = {
          'data': data,
          'timestamp': DateTime.now(),
        };
      }
      
      return data;
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on TimeoutException {
      throw const NetworkException('Request timeout');
    } on FormatException {
      throw const ApiException('Invalid response format');
    }
  }

  /// Generic HTTP POST request with error handling
  Future<Map<String, dynamic>> _post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    await _checkRateLimit();
    
    final url = _buildUrl(endpoint, queryParams: queryParams);
    
    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on TimeoutException {
      throw const NetworkException('Request timeout');
    } on FormatException {
      throw const ApiException('Invalid response format');
    }
  }

  /// Generic HTTP DELETE request with error handling
  Future<Map<String, dynamic>> _delete(String endpoint, {Map<String, String>? queryParams}) async {
    await _checkRateLimit();
    
    final url = _buildUrl(endpoint, queryParams: queryParams);
    
    try {
      final response = await _httpClient.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on TimeoutException {
      throw const NetworkException('Request timeout');
    } on FormatException {
      throw const ApiException('Invalid response format');
    }
  }

  /// Handle HTTP response and extract JSON data
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw const ApiException('Failed to parse response JSON');
      }
    } else {
      _handleErrorResponse(response);
    }
  }

  /// Handle error responses from API
  Never _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    String message = 'API request failed';
    
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      message = errorData['status_message'] as String? ?? message;
    } catch (e) {
      // Use default message if JSON parsing fails
    }
    
    switch (statusCode) {
      case 401:
        throw AuthenticationException(message, statusCode.toString());
      case 404:
        throw ApiException('Resource not found', statusCode.toString());
      case 429:
        throw ApiException('Rate limit exceeded', statusCode.toString());
      case >= 500:
        throw ApiException('Server error', statusCode.toString());
      default:
        throw ApiException(message, statusCode.toString());
    }
  }

  /// Fetch movie recommendations based on discovery
  Future<List<Movie>> getMovieRecommendations({
    List<String>? genres,
    int page = 1,
    String sortBy = 'popularity.desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'sort_by': sortBy,
      'include_adult': 'false',
      'include_video': 'false',
    };
    
    if (genres != null && genres.isNotEmpty) {
      queryParams['with_genres'] = genres.join(',');
    }
    
    final data = await _get(ApiConstants.discoverMovies, queryParams: queryParams);
    final results = data['results'] as List<dynamic>;
    
    return results.map((movieJson) => Movie.fromTMDbJson(movieJson as Map<String, dynamic>)).toList();
  }

  /// Fetch movie recommendations based on a specific movie
  Future<List<Movie>> getMovieBasedRecommendations(int movieId, {int page = 1}) async {
    final endpoint = ApiConstants.movieRecommendations.replaceAll('{id}', movieId.toString());
    final queryParams = <String, String>{
      'page': page.toString(),
    };
    
    final data = await _get(endpoint, queryParams: queryParams);
    final results = data['results'] as List<dynamic>;
    
    return results.map((movieJson) => Movie.fromTMDbJson(movieJson as Map<String, dynamic>)).toList();
  }

  /// Fetch available movie genres
  Future<List<Genre>> getGenres() async {
    final data = await _get(ApiConstants.genreList);
    final genres = data['genres'] as List<dynamic>;
    
    return genres.map((genreJson) => Genre.fromJson(genreJson as Map<String, dynamic>)).toList();
  }

  /// Fetch detailed information about a specific movie
  Future<Movie> getMovieDetails(int movieId) async {
    final endpoint = '/movie/$movieId';
    final queryParams = <String, String>{
      'append_to_response': 'genres',
    };
    
    final data = await _get(endpoint, queryParams: queryParams);
    return Movie.fromTMDbJson(data);
  }

  /// Search for movies by query
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final queryParams = <String, String>{
      'query': query,
      'page': page.toString(),
      'include_adult': 'false',
    };
    
    final data = await _get(ApiConstants.searchMovies, queryParams: queryParams);
    final results = data['results'] as List<dynamic>;
    
    return results.map((movieJson) => Movie.fromTMDbJson(movieJson as Map<String, dynamic>)).toList();
  }

  /// Create a request token for authentication
  Future<String> createRequestToken() async {
    final data = await _get(ApiConstants.createRequestToken, useCache: false);
    final token = data['request_token'] as String?;
    
    if (token == null) {
      throw const AuthenticationException('Failed to create request token');
    }
    
    return token;
  }

  /// Create a session with an approved request token
  Future<String> createSession(String approvedToken) async {
    final body = {
      'request_token': approvedToken,
    };
    
    final data = await _post(ApiConstants.createSession, body: body);
    final sessionId = data['session_id'] as String?;
    
    if (sessionId == null) {
      throw const AuthenticationException('Failed to create session');
    }
    
    return sessionId;
  }

  /// Rate a movie (requires session)
  Future<bool> rateMovie(int movieId, double rating, String sessionId) async {
    if (rating < 0.5 || rating > 10.0) {
      throw const ValidationException('Rating must be between 0.5 and 10.0');
    }
    
    final endpoint = ApiConstants.rateMovie.replaceAll('{id}', movieId.toString());
    final queryParams = <String, String>{
      'session_id': sessionId,
    };
    final body = {
      'value': rating,
    };
    
    try {
      final data = await _post(endpoint, body: body, queryParams: queryParams);
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      return false;
    }
  }

  /// Delete a movie rating (requires session)
  Future<bool> deleteMovieRating(int movieId, String sessionId) async {
    final endpoint = ApiConstants.rateMovie.replaceAll('{id}', movieId.toString());
    final queryParams = <String, String>{
      'session_id': sessionId,
    };
    
    try {
      final data = await _delete(endpoint, queryParams: queryParams);
      return data['success'] as bool? ?? false;
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      return false;
    }
  }

  /// Get user's rated movies (requires session and account ID)
  Future<List<Movie>> getRatedMovies(int accountId, String sessionId, {int page = 1}) async {
    final endpoint = ApiConstants.ratedMovies.replaceAll('{account_id}', accountId.toString());
    final queryParams = <String, String>{
      'session_id': sessionId,
      'page': page.toString(),
    };
    
    final data = await _get(endpoint, queryParams: queryParams, useCache: false);
    final results = data['results'] as List<dynamic>;
    
    return results.map((movieJson) {
      final movie = Movie.fromTMDbJson(movieJson as Map<String, dynamic>);
      // Add user rating from the response
      final userRating = movieJson['rating'] as double?;
      return movie.copyWith(userRating: userRating, isWatched: true);
    }).toList();
  }

  /// Get user's watchlist movies (requires session and account ID)
  Future<List<Movie>> getWatchlistMovies(int accountId, String sessionId, {int page = 1}) async {
    final endpoint = ApiConstants.watchlist.replaceAll('{account_id}', accountId.toString());
    final queryParams = <String, String>{
      'session_id': sessionId,
      'page': page.toString(),
    };
    
    final data = await _get(endpoint, queryParams: queryParams, useCache: false);
    final results = data['results'] as List<dynamic>;
    
    return results.map((movieJson) {
      final movie = Movie.fromTMDbJson(movieJson as Map<String, dynamic>);
      return movie.copyWith(isWatched: true);
    }).toList();
  }

  /// Get account details (requires session)
  Future<Map<String, dynamic>> getAccountDetails(String sessionId) async {
    const endpoint = '/account';
    final queryParams = <String, String>{
      'session_id': sessionId,
    };
    
    return await _get(endpoint, queryParams: queryParams, useCache: false);
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
    _cache.clear();
    _requestTimestamps.clear();
  }
}