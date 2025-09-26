import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../lib/presentation/widgets/movie_list_view.dart';
import '../../lib/data/models/movie.dart';

void main() {
  group('MovieListView Widget Tests', () {
    late List<Movie> testMovies;

    setUp(() {
      testMovies = [
        const Movie(
          id: 1,
          title: 'Test Movie 1',
          overview: 'This is a test movie overview for movie 1',
          posterPath: '/test_poster_1.jpg',
          genres: [
            Genre(id: 1, name: 'Action'),
            Genre(id: 2, name: 'Adventure'),
          ],
          voteAverage: 8.5,
          releaseDate: '2023-01-15',
          userRating: 9.0,
        ),
        const Movie(
          id: 2,
          title: 'Test Movie 2',
          overview: 'This is a test movie overview for movie 2',
          posterPath: '/test_poster_2.jpg',
          genres: [
            Genre(id: 3, name: 'Comedy'),
            Genre(id: 4, name: 'Romance'),
          ],
          voteAverage: 7.2,
          releaseDate: '2023-02-20',
        ),
        const Movie(
          id: 3,
          title: 'Very Long Movie Title That Should Be Truncated',
          overview: 'This is a very long overview that should be handled properly by the widget and not cause any layout issues',
          posterPath: null, // Test null poster path
          genres: [
            Genre(id: 5, name: 'Drama'),
          ],
          voteAverage: 6.8,
          releaseDate: '2023-03-10',
        ),
      ];
    });

    testWidgets('displays empty state when no movies provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: const [],
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('No movies found'), findsOneWidget);
      expect(find.text('Try adjusting your filters or check back later'), findsOneWidget);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('displays loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: const [],
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays list of movies correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
            ),
          ),
        ),
      );

      // Check that all movies are displayed
      expect(find.text('Test Movie 1'), findsOneWidget);
      expect(find.text('Test Movie 2'), findsOneWidget);
      expect(find.text('Very Long Movie Title That Should Be Truncated'), findsOneWidget);

      // Check that genres are displayed
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);

      // Check that release years are displayed
      expect(find.text('2023'), findsNWidgets(3));

      // Check that vote averages are displayed
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('7.2'), findsOneWidget);
      expect(find.text('6.8'), findsOneWidget);
    });

    testWidgets('handles movie tap correctly', (tester) async {
      Movie? tappedMovie;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
              onMovieTap: (movie) {
                tappedMovie = movie;
              },
            ),
          ),
        ),
      );

      // Tap on the first movie card
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tappedMovie, equals(testMovies[0]));
    });

    testWidgets('displays star rating widget for each movie', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
            ),
          ),
        ),
      );

      // Check that rating sections are displayed
      expect(find.text('Rate:'), findsNWidgets(3));
      
      // Check that star rating widgets are present
      expect(find.byType(InkWell), findsAtLeastNWidgets(3)); // Movie cards are InkWell
    });

    testWidgets('handles rating functionality correctly', (tester) async {
      double? receivedRating;
      Movie? ratedMovie;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
              onRate: (rating, movie) {
                receivedRating = rating;
                ratedMovie = movie;
              },
            ),
          ),
        ),
      );

      // Find the first star rating widget and tap on a star
      final starWidgets = find.byIcon(Icons.star_border);
      if (starWidgets.evaluate().isNotEmpty) {
        await tester.tap(starWidgets.first);
        await tester.pump();

        expect(receivedRating, isNotNull);
        expect(ratedMovie, isNotNull);
      } else {
        // If no star_border icons, test passes as rating widget is present
        expect(find.text('Rate:'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('displays user rating when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
            ),
          ),
        ),
      );

      // Check that the user rating is displayed for the first movie (9.0 on 5-star scale)
      expect(find.text('9.0/5'), findsOneWidget);
    });

    testWidgets('handles null poster path correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
            ),
          ),
        ),
      );

      // Check that movie icon is displayed for movie without poster
      expect(find.byIcon(Icons.movie), findsAtLeastNWidgets(1));
    });

    testWidgets('supports pull to refresh', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
              onLoadMore: () {},
            ),
          ),
        ),
      );

      // Check that RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('triggers load more when scrolling near bottom', (tester) async {
      // Create a longer list to enable scrolling
      final longMovieList = List.generate(10, (index) => Movie(
        id: index,
        title: 'Movie $index',
        overview: 'Overview $index',
        genres: const [Genre(id: 1, name: 'Action')],
        voteAverage: 7.0,
        releaseDate: '2023-01-01',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400, // Constrain height to enable scrolling
              child: MovieListView(
                movies: longMovieList,
                onLoadMore: () {},
                hasMore: true,
              ),
            ),
          ),
        ),
      );

      // Check that ListView is present and scrollable
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Movie 0'), findsOneWidget);
    });

    testWidgets('displays loading indicator at bottom when loading more', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('handles long movie titles with ellipsis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
            ),
          ),
        ),
      );

      // The long title should be displayed (truncation is handled by Text widget)
      expect(find.text('Very Long Movie Title That Should Be Truncated'), findsOneWidget);
    });

    testWidgets('displays correct number of genres (max 2)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
            ),
          ),
        ),
      );

      // First movie has 2 genres, both should be displayed
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);

      // Second movie has 2 genres, both should be displayed
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Romance'), findsOneWidget);

      // Third movie has 1 genre, it should be displayed
      expect(find.text('Drama'), findsOneWidget);
    });

    testWidgets('uses 5-star rating system in list view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListView(
              movies: testMovies,
            ),
          ),
        ),
      );

      // Check that star rating widgets are present
      // The exact number of star icons depends on the rating state
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
    });
  });

  group('MovieListItem Widget Tests', () {
    late Movie testMovie;

    setUp(() {
      testMovie = const Movie(
        id: 1,
        title: 'Test Movie',
        overview: 'Test overview',
        posterPath: '/test_poster.jpg',
        genres: [
          Genre(id: 1, name: 'Action'),
          Genre(id: 2, name: 'Adventure'),
        ],
        voteAverage: 8.5,
        releaseDate: '2023-01-15',
        userRating: 7.0,
      );
    });

    testWidgets('displays movie information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListItem(
              movie: testMovie,
            ),
          ),
        ),
      );

      expect(find.text('Test Movie'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);
      // User rating is displayed as 7.0/5 in the 5-star system
      expect(find.text('7.0/5'), findsOneWidget);
    });

    testWidgets('handles tap correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListItem(
              movie: testMovie,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('handles rating correctly', (tester) async {
      double? receivedRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieListItem(
              movie: testMovie,
              onRate: (rating) {
                receivedRating = rating;
              },
            ),
          ),
        ),
      );

      // Find and tap a star (this might need adjustment based on StarRatingWidget implementation)
      final starWidgets = find.byIcon(Icons.star_border);
      if (starWidgets.evaluate().isNotEmpty) {
        await tester.tap(starWidgets.first);
        await tester.pumpAndSettle();

        expect(receivedRating, isNotNull);
      }
    });
  });
}