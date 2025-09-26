import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';
import 'package:movie_recommendation_app/presentation/widgets/genre_filter.dart';

void main() {
  group('GenreFilter Widget Tests', () {
    late List<Genre> testGenres;
    late List<String> selectedGenres;
    late List<String> capturedGenres;

    setUp(() {
      testGenres = [
        const Genre(id: 28, name: 'Action'),
        const Genre(id: 35, name: 'Comedy'),
        const Genre(id: 18, name: 'Drama'),
        const Genre(id: 27, name: 'Horror'),
        const Genre(id: 10749, name: 'Romance'),
        const Genre(id: 878, name: 'Science Fiction'),
      ];
      selectedGenres = ['Action', 'Comedy'];
      capturedGenres = [];
    });

    Widget createGenreFilterWidget({
      List<Genre>? genres,
      List<String>? selected,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: GenreFilter(
            availableGenres: genres ?? testGenres,
            selectedGenres: selected ?? selectedGenres,
            onGenresChanged: (genres) {
              capturedGenres = genres;
            },
            isLoading: isLoading,
          ),
        ),
      );
    }

    testWidgets('displays loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Filter by Genre'), findsNothing);
    });

    testWidgets('displays empty widget when no genres available', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(genres: []));

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Filter by Genre'), findsNothing);
    });

    testWidgets('displays genre filter header and chips', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget());

      // Check header
      expect(find.text('Filter by Genre'), findsOneWidget);
      
      // Check all genre chips are displayed
      for (final genre in testGenres) {
        expect(find.text(genre.name), findsOneWidget);
      }
      
      // Check filter chips exist
      expect(find.byType(FilterChip), findsNWidgets(testGenres.length));
    });

    testWidgets('shows selected genres correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget());

      // Find Action and Comedy chips
      final actionChip = find.widgetWithText(FilterChip, 'Action');
      final comedyChip = find.widgetWithText(FilterChip, 'Comedy');
      final dramaChip = find.widgetWithText(FilterChip, 'Drama');

      expect(actionChip, findsOneWidget);
      expect(comedyChip, findsOneWidget);
      expect(dramaChip, findsOneWidget);

      // Check that Action and Comedy are selected
      final actionFilterChip = tester.widget<FilterChip>(actionChip);
      final comedyFilterChip = tester.widget<FilterChip>(comedyChip);
      final dramaFilterChip = tester.widget<FilterChip>(dramaChip);

      expect(actionFilterChip.selected, isTrue);
      expect(comedyFilterChip.selected, isTrue);
      expect(dramaFilterChip.selected, isFalse);
    });

    testWidgets('displays selected genres count', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget());

      expect(find.text('2 genres selected'), findsOneWidget);
    });

    testWidgets('displays singular form for single selected genre', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(selected: ['Action']));

      expect(find.text('1 genre selected'), findsOneWidget);
    });

    testWidgets('shows Clear All button when genres are selected', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget());

      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('hides Clear All button when no genres are selected', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(selected: []));

      expect(find.text('Clear All'), findsNothing);
      expect(find.text('0 genres selected'), findsNothing);
    });

    testWidgets('can select a genre by tapping chip', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(selected: []));

      // Tap on Drama chip
      await tester.tap(find.widgetWithText(FilterChip, 'Drama'));
      await tester.pump();

      // Verify callback was called with Drama added
      expect(capturedGenres, contains('Drama'));
      expect(capturedGenres.length, equals(1));
    });

    testWidgets('can deselect a genre by tapping selected chip', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget());

      // Tap on Action chip (which is already selected)
      await tester.tap(find.widgetWithText(FilterChip, 'Action'));
      await tester.pump();

      // Verify callback was called with Action removed
      expect(capturedGenres, isNot(contains('Action')));
      expect(capturedGenres, contains('Comedy'));
      expect(capturedGenres.length, equals(1));
    });

    testWidgets('can select multiple genres', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(selected: []));

      // Tap on multiple chips
      await tester.tap(find.widgetWithText(FilterChip, 'Action'));
      await tester.pump();
      
      await tester.tap(find.widgetWithText(FilterChip, 'Horror'));
      await tester.pump();
      
      await tester.tap(find.widgetWithText(FilterChip, 'Romance'));
      await tester.pump();

      // Verify all three genres are selected
      expect(capturedGenres, containsAll(['Action', 'Horror', 'Romance']));
      expect(capturedGenres.length, equals(3));
    });

    testWidgets('Clear All button clears all selected genres', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget());

      // Tap Clear All button
      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // Verify callback was called with empty list
      expect(capturedGenres, isEmpty);
    });

    testWidgets('updates when selectedGenres prop changes', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(selected: ['Action']));

      // Verify initial state
      expect(find.text('1 genre selected'), findsOneWidget);

      // Update with new selection
      await tester.pumpWidget(createGenreFilterWidget(selected: ['Action', 'Drama', 'Horror']));
      await tester.pump();

      // Verify updated state
      expect(find.text('3 genres selected'), findsOneWidget);
      
      // Check that the correct chips are selected
      final actionChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Action'));
      final dramaChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Drama'));
      final horrorChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Horror'));
      final comedyChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Comedy'));

      expect(actionChip.selected, isTrue);
      expect(dramaChip.selected, isTrue);
      expect(horrorChip.selected, isTrue);
      expect(comedyChip.selected, isFalse);
    });

    testWidgets('applies Material Design 3 styling', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget());

      // Find a selected and unselected chip
      final selectedChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Action'));
      final unselectedChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Drama'));

      // Verify Material Design properties
      expect(selectedChip.materialTapTargetSize, equals(MaterialTapTargetSize.shrinkWrap));
      expect(selectedChip.visualDensity, equals(VisualDensity.compact));
      expect(selectedChip.elevation, equals(2));
      expect(selectedChip.pressElevation, equals(4));

      expect(unselectedChip.materialTapTargetSize, equals(MaterialTapTargetSize.shrinkWrap));
      expect(unselectedChip.visualDensity, equals(VisualDensity.compact));
      expect(unselectedChip.elevation, equals(0));
      expect(unselectedChip.pressElevation, equals(4));
    });

    testWidgets('handles empty genre list gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createGenreFilterWidget(genres: [], selected: []));

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('maintains state during widget updates', (WidgetTester tester) async {
      // Start with some selected genres
      await tester.pumpWidget(createGenreFilterWidget(selected: ['Action', 'Comedy']));
      
      // Tap to add another genre
      await tester.tap(find.widgetWithText(FilterChip, 'Drama'));
      await tester.pump();
      
      // Verify the selection was updated
      expect(capturedGenres, containsAll(['Action', 'Comedy', 'Drama']));
      
      // Update the widget with the same props
      await tester.pumpWidget(createGenreFilterWidget(selected: ['Action', 'Comedy']));
      await tester.pump();
      
      // The internal state should reflect the prop change
      expect(find.text('2 genres selected'), findsOneWidget);
    });
  });
}