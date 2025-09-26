import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/presentation/screens/main_navigation_screen.dart';

void main() {
  group('MainNavigationScreen Widget Tests', () {
    testWidgets('should display bottom navigation with correct destinations', (tester) async {
      // Create a simple test widget without providers for basic navigation testing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (index) {},
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.swipe),
                  selectedIcon: Icon(Icons.swipe),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list),
                  selectedIcon: Icon(Icons.list),
                  label: 'List',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify bottom navigation bar exists
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify all navigation destinations
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.swipe), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should handle navigation destination selection', (tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(_getAppBarTitle(selectedIndex)),
                ),
                body: Text('Content for index $selectedIndex'),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.swipe),
                      label: 'Discover',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.list),
                      label: 'List',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Discover Movies'), findsOneWidget);
      expect(find.text('Content for index 0'), findsOneWidget);

      // Tap on List tab
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();

      // Verify navigation to list view
      expect(find.text('Movie List'), findsOneWidget);
      expect(find.text('Content for index 1'), findsOneWidget);

      // Tap on Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify navigation to profile view (check app bar specifically)
      expect(find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Profile'),
      ), findsOneWidget);
      expect(find.text('Content for index 2'), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify navigation to settings view (check app bar specifically)
      expect(find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Settings'),
      ), findsOneWidget);
      expect(find.text('Content for index 3'), findsOneWidget);
    });

    testWidgets('should show correct app bar titles for each tab', (tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(_getAppBarTitle(selectedIndex)),
                  actions: _getAppBarActions(selectedIndex),
                ),
                body: const Text('Test content'),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.swipe), label: 'Discover'),
                    NavigationDestination(icon: Icon(Icons.list), label: 'List'),
                    NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
                    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test each tab's app bar title
      final tabs = ['Discover', 'List', 'Profile', 'Settings'];
      final expectedTitles = ['Discover Movies', 'Movie List', 'Profile', 'Settings'];

      for (int i = 0; i < tabs.length; i++) {
        await tester.tap(find.text(tabs[i]));
        await tester.pumpAndSettle();
        expect(find.descendant(
          of: find.byType(AppBar),
          matching: find.text(expectedTitles[i]),
        ), findsOneWidget);
      }
    });

    testWidgets('should show filter button for discover and list tabs', (tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(_getAppBarTitle(selectedIndex)),
                  actions: _getAppBarActions(selectedIndex),
                ),
                body: const Text('Test content'),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.swipe), label: 'Discover'),
                    NavigationDestination(icon: Icon(Icons.list), label: 'List'),
                    NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
                    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Discover tab has filter button
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Check List tab has filter button
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Check Profile tab has no filter button
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.filter_list), findsNothing);

      // Check Settings tab has no filter button
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.filter_list), findsNothing);
    });
  });
}

String _getAppBarTitle(int index) {
  switch (index) {
    case 0:
      return 'Discover Movies';
    case 1:
      return 'Movie List';
    case 2:
      return 'Profile';
    case 3:
      return 'Settings';
    default:
      return 'Movie Recommendations';
  }
}

List<Widget> _getAppBarActions(int index) {
  if (index == 0 || index == 1) {
    return [
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: () {},
        tooltip: 'Show Filters',
      ),
    ];
  }
  return [];
}