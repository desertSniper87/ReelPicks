/// API constants for the movie recommendation app
class ApiConstants {
  // TMDb API configuration
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  
  // API endpoints
  static const String discoverMovies = '/discover/movie';
  static const String genreList = '/genre/movie/list';
  static const String movieRecommendations = '/movie/{id}/recommendations';
  static const String searchMovies = '/search/movie';
  static const String createRequestToken = '/authentication/token/new';
  static const String createSession = '/authentication/session/new';
  static const String rateMovie = '/movie/{id}/rating';
  static const String ratedMovies = '/account/{account_id}/rated/movies';
  static const String watchlist = '/account/{account_id}/watchlist/movies';
  
  // Rate limiting
  static const int maxRequestsPerWindow = 40;
  static const Duration rateLimitWindow = Duration(seconds: 10);
}