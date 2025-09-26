import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';
import 'package:movie_recommendation_app/presentation/widgets/movie_card.dart';

void main() {
  group('MovieCard Widget Tests', () {
    late Movie testMovie;

    setUp(() {
      testMovie = const Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'This is a test movie overview.',
        posterPath: '/test_poster.jpg',
        genres: [
          Genre(id: 1, name: 'Action'),
          Genre(id: 2, name: 'Adventure'),
          Genre(id: 3, name: 'Comedy'),
        ],
        voteAverage: 7.5,
        releaseDate: '2023-01-01',
        userRating: 8.0,
        isWatched: false,
      );
    });

    testWidgets('displays movie information correctly', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(movie: testMovie),
            ),
          ),
        ),
      );

      // Verify movie title is displayed
      expect(find.text('Test Movie'), findsOneWidget);
      
      // Verify overview is displayed
      expect(find.textContaining('This is a test movie overview'), findsOneWidget);
      
      // Verify genres are displayed as chips (limited to 3)
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      
      // Verify rating section is displayed
      expect(find.text('Rate this movie:'), findsOneWidget);
      
      // Verify swipe instructions are displayed
      expect(find.text('Swipe to navigate'), findsOneWidget);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('displays placeholder when poster path is null', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      final movieWithoutPoster = const Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'This is a test movie overview.',
        posterPath: null, // Explicitly null
        genres: [
          Genre(id: 1, name: 'Action'),
          Genre(id: 2, name: 'Adventure'),
          Genre(id: 3, name: 'Comedy'),
        ],
        voteAverage: 7.5,
        releaseDate: '2023-01-01',
        userRating: null, // No rating
        isWatched: false,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(movie: movieWithoutPoster),
            ),
          ),
        ),
      );

      // Verify placeholder is displayed
      expect(find.text('No poster available'), findsOneWidget);
      expect(find.byIcon(Icons.movie), findsOneWidget);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('displays user rating when available', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(movie: testMovie),
            ),
          ),
        ),
      );

      // Verify user rating is displayed
      expect(find.text('Your rating: 8.0/10'), findsOneWidget);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('handles rating interaction', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      double? ratedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(
                movie: testMovie.copyWith(userRating: null),
                onRate: (rating) {
                  ratedValue = rating;
                },
              ),
            ),
          ),
        ),
      );

      // Find the star rating widget
      final starRatingWidget = find.byType(StarRatingWidget);
      expect(starRatingWidget, findsOneWidget);
      
      // Find all star icons within the rating widget
      final starIcons = find.descendant(
        of: starRatingWidget,
        matching: find.byIcon(Icons.star_border),
      );
      
      // Ensure we have star icons to tap
      expect(starIcons, findsWidgets);
      
      // Tap the first available star icon
      await tester.tap(starIcons.first);
      await tester.pump();

      // Verify rating callback was called (any rating is fine for this test)
      expect(ratedValue, isNotNull);
      expect(ratedValue! > 0, isTrue);
      expect(ratedValue! <= 10, isTrue);
      
      // Verify rating display is updated
      expect(find.textContaining('Your rating:'), findsOneWidget);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('handles swipe gestures', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      bool swipedLeft = false;
      bool swipedRight = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(
                movie: testMovie,
                onSwipeLeft: () {
                  swipedLeft = true;
                },
                onSwipeRight: () {
                  swipedRight = true;
                },
              ),
            ),
          ),
        ),
      );

      // Test swipe right gesture on the card content
      final cardFinder = find.byType(Card);
      await tester.drag(cardFinder, const Offset(150, 0));
      await tester.pump();
      
      expect(swipedRight, isTrue);
      expect(swipedLeft, isFalse);

      // Reset flags
      swipedLeft = false;
      swipedRight = false;

      // Test swipe left gesture
      await tester.drag(cardFinder, const Offset(-150, 0));
      await tester.pump();
      
      expect(swipedLeft, isTrue);
      expect(swipedRight, isFalse);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('does not trigger swipe for small drag distances', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      bool swipedLeft = false;
      bool swipedRight = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(
                movie: testMovie,
                onSwipeLeft: () {
                  swipedLeft = true;
                },
                onSwipeRight: () {
                  swipedRight = true;
                },
              ),
            ),
          ),
        ),
      );

      // Test small drag that shouldn't trigger swipe
      final cardFinder = find.byType(Card);
      await tester.drag(cardFinder, const Offset(50, 0));
      await tester.pump();
      
      expect(swipedRight, isFalse);
      expect(swipedLeft, isFalse);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('shows visual feedback during drag', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(movie: testMovie),
            ),
          ),
        ),
      );

      final cardFinder = find.byType(Card);
      
      // Get initial card properties
      Card initialCard = tester.widget(cardFinder);
      expect(initialCard.elevation, equals(8));

      // Start drag gesture
      await tester.startGesture(tester.getCenter(cardFinder));
      await tester.pump();

      // Verify elevated state during drag
      Card draggedCard = tester.widget(cardFinder);
      expect(draggedCard.elevation, equals(12));
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('disables rating when isRatingEnabled is false', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(
                movie: testMovie,
                isRatingEnabled: false,
              ),
            ),
          ),
        ),
      );

      // Verify rating section is not displayed
      expect(find.text('Rate this movie:'), findsNothing);
      expect(find.byType(StarRatingWidget), findsNothing);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('limits genre display to 3 chips', (WidgetTester tester) async {
      // Set a larger screen size for testing
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      final movieWithManyGenres = testMovie.copyWith(
        genres: const [
          Genre(id: 1, name: 'Action'),
          Genre(id: 2, name: 'Adventure'),
          Genre(id: 3, name: 'Comedy'),
          Genre(id: 4, name: 'Drama'),
          Genre(id: 5, name: 'Thriller'),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MovieCard(movie: movieWithManyGenres),
            ),
          ),
        ),
      );

      // Verify only first 3 genres are displayed
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Drama'), findsNothing);
      expect(find.text('Thriller'), findsNothing);
      
      // Reset screen size
      addTearDown(tester.view.reset);
    });
  });

  group('StarRatingWidget Tests', () {
    testWidgets('displays correct number of stars', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 5.0,
              onRatingChanged: (rating) {},
              starCount: 10,
            ),
          ),
        ),
      );

      // Verify 10 stars are displayed
      final starIcons = find.byIcon(Icons.star).evaluate().length +
                       find.byIcon(Icons.star_border).evaluate().length +
                       find.byIcon(Icons.star_half).evaluate().length;
      expect(starIcons, equals(10));
    });

    testWidgets('displays filled stars for rating', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 7.0,
              onRatingChanged: (rating) {},
              starCount: 10,
            ),
          ),
        ),
      );

      // Verify 7 filled stars
      expect(find.byIcon(Icons.star), findsNWidgets(7));
      expect(find.byIcon(Icons.star_border), findsNWidgets(3));
    });

    testWidgets('handles star tap to change rating', (WidgetTester tester) async {
      double? newRating;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 0.0,
              onRatingChanged: (rating) {
                newRating = rating;
              },
              starCount: 10,
            ),
          ),
        ),
      );

      // Tap the 8th star
      final starWidgets = find.byIcon(Icons.star_border);
      await tester.tap(starWidgets.at(7)); // 8th star (index 7)
      await tester.pump();

      expect(newRating, equals(8.0));
    });

    testWidgets('updates visual state when rating changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 3.0,
              onRatingChanged: (rating) {},
              starCount: 10,
            ),
          ),
        ),
      );

      // Initially 3 filled stars
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(7));

      // Tap 6th star to change rating
      final starWidgets = find.byIcon(Icons.star_border);
      await tester.tap(starWidgets.at(2)); // This should be the 6th star overall
      await tester.pump();

      // Should now have 6 filled stars
      expect(find.byIcon(Icons.star), findsNWidgets(6));
      expect(find.byIcon(Icons.star_border), findsNWidgets(4));
    });
  });
}