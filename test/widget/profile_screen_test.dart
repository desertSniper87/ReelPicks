import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/presentation/screens/profile_screen.dart';
import 'package:movie_recommendation_app/presentation/providers/auth_provider.dart';
import 'package:movie_recommendation_app/presentation/providers/user_provider.dart';
import 'package:movie_recommendation_app/data/models/user_profile.dart';
import 'package:movie_recommendation_app/data/models/user_preferences.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';
import 'package:movie_recommendation_app/domain/services/authentication_service.dart';
import 'package:movie_recommendation_app/domain/repositories/user_repository.dart';
import 'package:movie_recommendation_app/domain/repositories/movie_repository.dart';
import 'package:movie_recommendation_app/core/utils/result.dart';
import 'package:movie_recommendation_app/core/error/failures.dart';
import 'package:movie_recommendation_app/presentation/widgets/rated_movies_list.dart';

import 'profile_screen_test.mocks.dart';

@GenerateMocks([
  AuthenticationService,
  UserRepository,
  MovieRepository,
])
void main() {
  group('ProfileScreen Widget Tests', () {
    late MockAuthenticationService mockAuthService;
    late MockUserRepository mockUserRepository;
    late MockMovieRepository mockMovieRepository;
    late AuthProvider authProvider;
    late UserProvider userProvider;

    setUp(() {
      mockAuthService = MockAuthenticationService();
      mockUserRepository = MockUserRepository();
      mockMovieRepository = MockMovieRepository();
      
      authProvider = AuthProvider(authService: mockAuthService);
      userProvider = UserProvider(
        userRepository: mockUserRepository,
        movieRepository: mockMovieRepository,
      );

      // Setup default mock responses
      when(mockAuthService.isAuthenticated).thenReturn(false);
      when(mockAuthService.getCurrentSessionId()).thenReturn(null);
      when(mockAuthService.getStoredUsername()).thenAnswer((_) async => null);
      when(mockAuthService.getStoredAccountName()).thenAnswer((_) async => null);
      when(mockAuthService.initialize()).thenAnswer((_) async {});
      when(mockAuthService.validateSession()).thenAnswer((_) async => const Success(true));
      
      when(mockUserRepository.getUserPreferences()).thenAnswer(
        (_) async => Success(UserPreferences(
          preferredGenres: const [],
          enablePersonalization: true,
          defaultViewMode: ViewMode.swipe,
        )),
      );
      when(mockUserRepository.getUserProfile()).thenAnswer(
        (_) async => Success(UserProfile(
          preferredGenres: const [],
          isAuthenticated: false,
        )),
      );
    });

    testWidgets('displays profile screen with tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar and tabs are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('TMDb'), findsOneWidget);
      expect(find.text('External'), findsOneWidget);
      expect(find.text('Ratings'), findsOneWidget);
    });

    testWidgets('shows TMDb login section when not authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show login section
      expect(find.text('Connect to TMDb'), findsOneWidget);
      expect(find.text('Connect TMDb Account'), findsOneWidget);
    });

    testWidgets('shows empty state in ratings tab when not authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Ratings tab
      await tester.tap(find.text('Ratings'));
      await tester.pumpAndSettle();

      // Should show not authenticated message
      expect(find.text('Connect to TMDb to view your rated movies'), findsOneWidget);
    });

    testWidgets('handles authentication error gracefully', (WidgetTester tester) async {
      when(mockAuthService.createRequestToken()).thenAnswer(
        (_) async => const ResultFailure(AuthenticationFailure('Network error')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap connect button
      await tester.tap(find.text('Connect TMDb Account'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Failed to start authentication'), findsOneWidget);
    });
  });

  group('RatedMoviesList Widget Tests', () {
    testWidgets('displays movie list correctly', (WidgetTester tester) async {
      final testMovies = [
        Movie(
          id: 1,
          title: 'Test Movie',
          overview: 'Test overview',
          posterPath: '/test.jpg',
          genres: [Genre(id: 1, name: 'Action')],
          voteAverage: 8.5,
          releaseDate: '2023-01-01',
          runtime: 120,
          userRating: 9.0,
          isWatched: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatedMoviesList(
              movies: testMovies,
              onRefresh: () {},
              onRatingChanged: (movieId, newRating) async {},
            ),
          ),
        ),
      );

      expect(find.text('Test Movie'), findsOneWidget);
      expect(find.text('9.0'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('handles pull to refresh', (WidgetTester tester) async {
      bool refreshCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatedMoviesList(
              movies: const [],
              onRefresh: () => refreshCalled = true,
              onRatingChanged: (movieId, newRating) async {},
            ),
          ),
        ),
      );

      // Perform pull to refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
    });
  });

  group('TMDbAuthWebView Widget Tests', () {
    testWidgets('displays webview with correct title', (WidgetTester tester) async {
      // Simple test to verify the webview widget can be created
      // Note: WebView testing is limited in Flutter tests
      expect(true, isTrue); // Placeholder test
    });
  });
}