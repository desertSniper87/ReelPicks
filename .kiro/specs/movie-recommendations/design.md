# Design Document

## Overview

The movie recommendation system will be built as a Flutter application using a clean architecture pattern with clear separation of concerns. The app will integrate with The Movie Database (TMDb) API for movie data and recommendations, while supporting IMDb profile integration through web scraping or user input. The system will feature a card-based swipe interface for single movie browsing and a list view for multiple recommendations, all following Material Design 3 principles.

## Architecture

### High-Level Architecture

The application follows a layered architecture pattern:

```
Presentation Layer (UI)
├── Screens (Home, Profile, Settings)
├── Widgets (MovieCard, MovieList, FilterChips)
└── State Management (Provider/Riverpod)

Business Logic Layer
├── Services (RecommendationService, ProfileService)
├── Repositories (MovieRepository, UserRepository)
└── Models (Movie, User, Recommendation)

Data Layer
├── API Clients (TMDbClient, IMDbClient)
├── Local Storage (SharedPreferences, SQLite)
└── Network Layer (HTTP Client, Error Handling)
```

### State Management

The app will use **Provider** or **Riverpod** for state management to handle:
- User authentication state
- Movie recommendations state
- Filter preferences
- Profile connection status
- Loading states and error handling

## Components and Interfaces

### Core Components

#### 1. Movie Model
```dart
class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final List<String> genres;
  final double voteAverage;
  final String releaseDate;
}
```

#### 2. User Profile Model
```dart
class UserProfile {
  final String? tmdbSessionId;
  final int? tmdbAccountId;
  final String? imdbUsername;
  final String? letterboxdUsername;
  final List<String> preferredGenres;
  final bool isAuthenticated;
}
```

#### 3. Recommendation Service Interface
```dart
abstract class RecommendationService {
  Future<List<Movie>> getPersonalizedRecommendations(UserProfile profile);
  Future<List<Movie>> getGenreBasedRecommendations(List<String> genres);
  Future<List<Movie>> getPopularMovies();
}
```

#### 5. Authentication Service Interface
```dart
abstract class AuthenticationService {
  Future<String> createRequestToken();
  Future<String> createSession(String approvedToken);
  Future<bool> validateSession();
  Future<void> logout();
  String? getCurrentSessionId();
}
```

#### 4. Movie Repository Interface
```dart
abstract class MovieRepository {
  Future<List<Movie>> searchMovies(String query);
  Future<Movie> getMovieDetails(int movieId);
  Future<List<Movie>> getRecommendations(int movieId);
  Future<List<String>> getGenres();
  Future<bool> rateMovie(int movieId, double rating);
  Future<bool> deleteRating(int movieId);
  Future<List<Movie>> getRatedMovies();
  Future<List<Movie>> getWatchlist();
}
```

### UI Components

#### 1. MovieCard Widget
- Displays movie poster, title, and genres
- Supports swipe gestures (left/right)
- Material Design 3 card styling
- Smooth animations for transitions

#### 2. MovieListView Widget
- Scrollable list of movie recommendations
- Lazy loading for performance
- Pull-to-refresh functionality
- Search and filter integration

#### 3. GenreFilter Widget
- Chip-based genre selection
- Multi-select capability
- Material Design filter chips
- Real-time filtering

#### 4. ProfileConnection Widget
- IMDb/Letterboxd profile linking
- Connection status indicators
- Profile validation and error handling

## Data Models

### Movie Data Structure
```dart
class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String? backdropPath;
  final List<Genre> genres;
  final double voteAverage;
  final String releaseDate;
  final int runtime;
  final double? userRating; // User's rating (null if not rated)
  final bool isWatched; // Track watched status
  
  // Constructor and methods
  factory Movie.fromTMDbJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

class Genre {
  final int id;
  final String name;
}
```

### User Preferences Data Structure
```dart
class UserPreferences {
  final List<String> preferredGenres;
  final String? imdbProfileUrl;
  final String? letterboxdUsername;
  final bool enablePersonalization;
  final ViewMode defaultViewMode; // swipe or list
  
  // Persistence methods
  factory UserPreferences.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

enum ViewMode { swipe, list }
```

### Recommendation Data Structure
```dart
class RecommendationResult {
  final List<Movie> movies;
  final String source; // 'personalized', 'genre', 'popular'
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
}
```

## Error Handling

### API Error Handling Strategy

1. **Network Errors**
   - Implement retry logic with exponential backoff
   - Cache previous recommendations for offline viewing
   - Display user-friendly error messages

2. **Authentication Errors**
   - Handle API key validation
   - Graceful degradation when profile connection fails
   - Clear error messaging for profile setup

3. **Data Validation**
   - Validate movie data completeness
   - Handle missing poster images with placeholders
   - Sanitize user input for profile URLs

### Error Recovery Mechanisms

```dart
class ErrorHandler {
  static Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on NetworkException catch (e) {
      // Handle network errors
      throw UserFriendlyException('Network connection failed');
    } on ApiException catch (e) {
      // Handle API-specific errors
      throw UserFriendlyException('Unable to fetch movie data');
    }
  }
}
```

## Testing Strategy

### Unit Testing
- Test all business logic components
- Mock external API dependencies
- Test data model serialization/deserialization
- Validate recommendation algorithms

### Widget Testing
- Test UI component rendering
- Verify swipe gesture handling
- Test filter functionality
- Validate navigation flows

### Integration Testing
- Test API integration with TMDb
- Verify profile connection workflows
- Test recommendation generation end-to-end
- Validate offline functionality

### Test Structure
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── repositories/
├── widget/
│   ├── screens/
│   └── components/
└── integration/
    ├── api_integration_test.dart
    └── recommendation_flow_test.dart
```

## API Integration

### TMDb API Integration

**Base Configuration:**
- API Key management through environment variables
- Base URL: `https://api.themoviedb.org/3/`
- Image base URL: `https://image.tmdb.org/t/p/w500/`
- User authentication for watchlist management

**Key Endpoints:**
- `/discover/movie` - Get movie recommendations
- `/genre/movie/list` - Get available genres
- `/movie/{id}/recommendations` - Get similar movies
- `/search/movie` - Search for specific movies
- `/authentication/token/new` - Create request token
- `/authentication/session/new` - Create session
- `/movie/{id}/rating` - Rate a movie (POST/DELETE)
- `/account/{account_id}/rated/movies` - Get user's rated movies
- `/account/{account_id}/watchlist/movies` - Get user's watchlist

**Authentication Flow:**
- Request token → User approval → Session creation
- Session-based API calls for user-specific actions
- Secure token storage for persistent login

**Rate Limiting:**
- Implement request throttling (40 requests per 10 seconds)
- Use caching to reduce API calls
- Implement request queuing for batch operations

### IMDb Profile Integration

Since IMDb doesn't provide a public API for user data, the integration will use:

1. **User Input Method:**
   - Users manually input their favorite genres
   - Users provide their IMDb profile URL for reference
   - Manual entry of recently watched movies

2. **Web Scraping Alternative (Advanced):**
   - Parse public IMDb watchlists and ratings
   - Extract genre preferences from viewing history
   - Respect robots.txt and rate limiting

### Data Caching Strategy

```dart
class CacheManager {
  // Cache movie data for 24 hours
  static const Duration movieCacheDuration = Duration(hours: 24);
  
  // Cache recommendations for 6 hours
  static const Duration recommendationCacheDuration = Duration(hours: 6);
  
  // Cache user preferences indefinitely until changed
  static const Duration userPreferencesCacheDuration = Duration(days: 365);
}
```

## Performance Considerations

### Image Loading Optimization
- Use `cached_network_image` package for poster caching
- Implement progressive image loading
- Optimize image sizes based on device screen density

### List Performance
- Implement lazy loading for movie lists
- Use `ListView.builder` for efficient scrolling
- Paginate API results to reduce initial load time

### Memory Management
- Dispose of unused image caches
- Implement proper widget lifecycle management
- Use weak references for large data structures

## Security Considerations

### API Key Security
- Store API keys in environment variables
- Use obfuscation for production builds
- Implement API key rotation capability

### User Data Protection
- Store user preferences locally only
- No sensitive data transmission
- Implement data encryption for local storage

### Network Security
- Use HTTPS for all API communications
- Implement certificate pinning for production
- Validate all incoming data from APIs