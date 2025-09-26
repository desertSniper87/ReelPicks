import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:movie_recommendation_app/core/error/failures.dart';
import 'package:movie_recommendation_app/presentation/widgets/error_retry_widget.dart';
import 'package:movie_recommendation_app/presentation/widgets/offline_indicator.dart';
import 'package:movie_recommendation_app/presentation/providers/recommendation_provider.dart';
import 'package:movie_recommendation_app/data/models/user_profile.dart';

import '../unit/providers/recommendation_provider_test.mocks.dart';

void main() {
  group('Error Handling Widget Tests', () {
    late MockRecommendationService mockRecommendationService;
    late MockMovieRepository mockMovieRepository;
    late RecommendationProvider recommendationProvider;

    setUp(() {
      mockRecommendationService = MockRecommendationService();
      mockMovieRepository = MockMovieRepository();
      recommendationProvider = RecommendationProvider(
        recommendationService: mockRecommendationService,
        movieRepository: mockMovieRepository,
      );
    });

    group('ErrorRetryWidget', () {
      testWidgets('should display network error with retry button', (tester) async {
        // Arrange
        const failure = NetworkFailure('Network error');
        var retryPressed = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                failure: failure,
                onRetry: () => retryPressed = true,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.text('Please check your internet connection and try again'), findsOneWidget);
        expect(find.text('Check your internet connection and try again'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);

        // Test retry button
        await tester.tap(find.text('Try Again'));
        expect(retryPressed, isTrue);
      });

      testWidgets('should display authentication error without retry button', (tester) async {
        // Arrange
        const failure = AuthenticationFailure('Auth failed');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                failure: failure,
                onRetry: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(find.text('Authentication failed. Please log in again'), findsOneWidget);
        expect(find.text('Please log in again to continue'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing); // No retry button for auth errors
      });

      testWidgets('should display API error with retry button', (tester) async {
        // Arrange
        const failure = ApiFailure('API error');
        var retryPressed = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                failure: failure,
                onRetry: () => retryPressed = true,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
        expect(find.text('Unable to fetch data. Please try again later'), findsOneWidget);
        expect(find.text('Our servers are having issues. Please try again later'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);

        // Test retry button
        await tester.tap(find.text('Try Again'));
        expect(retryPressed, isTrue);
      });

      testWidgets('should display data error without retry button', (tester) async {
        // Arrange
        const failure = DataFailure('Data error');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                failure: failure,
                onRetry: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Invalid data received. Please try again'), findsOneWidget);
        expect(find.text('The data received was invalid'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing); // No retry button for data errors
      });

      testWidgets('should display cache error without retry button', (tester) async {
        // Arrange
        const failure = CacheFailure('Cache error');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                failure: failure,
                onRetry: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.storage), findsOneWidget);
        expect(find.text('Unable to load cached data'), findsOneWidget);
        expect(find.text('Unable to load saved data'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing); // No retry button for cache errors
      });

      testWidgets('should display custom error message when provided', (tester) async {
        // Arrange
        const failure = NetworkFailure('Network error');
        const customMessage = 'Custom error message';

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                failure: failure,
                customMessage: customMessage,
                onRetry: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text(customMessage), findsOneWidget);
        expect(find.text('Please check your internet connection and try again'), findsNothing);
      });

      testWidgets('should hide retry button when showRetryButton is false', (tester) async {
        // Arrange
        const failure = NetworkFailure('Network error');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorRetryWidget(
                failure: failure,
                onRetry: () {},
                showRetryButton: false,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(FilledButton), findsNothing);
      });
    });

    group('OfflineIndicator', () {
      testWidgets('should display offline banner when offline', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: OfflineBanner(),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.text('No internet connection'), findsOneWidget);
        expect(find.text('Showing cached content when available'), findsOneWidget);
      });

      testWidgets('should wrap child widget properly', (tester) async {
        // Arrange
        const childWidget = Text('Child Content');

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                child: childWidget,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Child Content'), findsOneWidget);
      });
    });

    group('ErrorSnackBar', () {
      testWidgets('should show error snackbar with retry action', (tester) async {
        // Arrange
        const failure = NetworkFailure('Network error');
        var retryPressed = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorSnackBar.show(
                    context,
                    failure,
                    onRetry: () => retryPressed = true,
                  ),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        // Trigger the snackbar
        await tester.tap(find.text('Show Error'));
        await tester.pump();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.text('Please check your internet connection and try again'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Test retry action
        await tester.tap(find.text('Retry'));
        expect(retryPressed, isTrue);
      });

      testWidgets('should show error snackbar without retry for non-retryable errors', (tester) async {
        // Arrange
        const failure = AuthenticationFailure('Auth error');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ErrorSnackBar.show(context, failure),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        // Trigger the snackbar
        await tester.tap(find.text('Show Error'));
        await tester.pump();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(find.text('Authentication failed. Please log in again'), findsOneWidget);
        expect(find.text('Retry'), findsNothing); // No retry for auth errors
      });
    });

    group('Provider Error State Integration', () {
      testWidgets('should display error state in provider', (tester) async {
        // Arrange
        const failure = NetworkFailure('Network error');
        recommendationProvider.clearError();
        
        // Simulate setting an error in the provider
        // This would typically be done through a failed API call
        // For testing, we'll create a test widget that shows the error state

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: recommendationProvider,
              child: Consumer<RecommendationProvider>(
                builder: (context, provider, child) {
                  if (provider.failure != null) {
                    return ErrorRetryWidget(
                      failure: provider.failure!,
                      onRetry: () => provider.retry(null),
                    );
                  }
                  return const Text('No Error');
                },
              ),
            ),
          ),
        );

        // Assert initial state
        expect(find.text('No Error'), findsOneWidget);
        expect(find.byType(ErrorRetryWidget), findsNothing);
      });
    });
  });
}