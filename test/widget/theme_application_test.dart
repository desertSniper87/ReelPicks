import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/core/theme/app_theme.dart';

void main() {
  group('Theme Application Tests', () {
    test('should create valid light theme with Material Design 3', () {
      final lightTheme = AppTheme.lightTheme;
      
      // Verify Material Design 3 is enabled
      expect(lightTheme.useMaterial3, true);
      expect(lightTheme.colorScheme.brightness, Brightness.light);
      expect(lightTheme.colorScheme.primary, isNotNull);
      expect(lightTheme.colorScheme.surface, isNotNull);
      
      // Verify typography
      expect(lightTheme.textTheme.displayLarge?.fontSize, 57);
      expect(lightTheme.textTheme.headlineMedium?.fontSize, 28);
      expect(lightTheme.textTheme.titleLarge?.fontSize, 22);
      expect(lightTheme.textTheme.bodyLarge?.fontSize, 16);
      expect(lightTheme.textTheme.labelMedium?.fontSize, 12);
      
      // Verify font weights
      expect(lightTheme.textTheme.displayLarge?.fontWeight, FontWeight.w400);
      expect(lightTheme.textTheme.titleLarge?.fontWeight, FontWeight.w400);
      expect(lightTheme.textTheme.labelMedium?.fontWeight, FontWeight.w500);
    });

    test('should create valid dark theme with Material Design 3', () {
      final darkTheme = AppTheme.darkTheme;
      
      // Verify Material Design 3 is enabled
      expect(darkTheme.useMaterial3, true);
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.primary, isNotNull);
      expect(darkTheme.colorScheme.surface, isNotNull);
      
      // Verify typography is consistent
      expect(darkTheme.textTheme.displayLarge?.fontSize, 57);
      expect(darkTheme.textTheme.headlineMedium?.fontSize, 28);
      expect(darkTheme.textTheme.titleLarge?.fontSize, 22);
      expect(darkTheme.textTheme.bodyLarge?.fontSize, 16);
      expect(darkTheme.textTheme.labelMedium?.fontSize, 12);
    });

    test('should have consistent theme properties between light and dark', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;
      
      // Both themes should use Material Design 3
      expect(lightTheme.useMaterial3, true);
      expect(darkTheme.useMaterial3, true);
      
      // Both themes should have the same typography
      expect(lightTheme.textTheme.displayLarge?.fontSize, 
             darkTheme.textTheme.displayLarge?.fontSize);
      expect(lightTheme.textTheme.headlineMedium?.fontSize, 
             darkTheme.textTheme.headlineMedium?.fontSize);
      expect(lightTheme.textTheme.titleLarge?.fontSize, 
             darkTheme.textTheme.titleLarge?.fontSize);
      
      // Both themes should have card themes configured
      expect(lightTheme.cardTheme.elevation, 1.0);
      expect(darkTheme.cardTheme.elevation, 1.0);
      expect(lightTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(darkTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
      
      // Both themes should have button themes configured
      expect(lightTheme.elevatedButtonTheme.style, isNotNull);
      expect(darkTheme.elevatedButtonTheme.style, isNotNull);
      expect(lightTheme.filledButtonTheme.style, isNotNull);
      expect(darkTheme.filledButtonTheme.style, isNotNull);
    });

    test('should have proper color scheme configuration', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;
      
      // Light theme color scheme
      expect(lightTheme.colorScheme.brightness, Brightness.light);
      expect(lightTheme.colorScheme.primary, isNotNull);
      expect(lightTheme.colorScheme.onPrimary, isNotNull);
      expect(lightTheme.colorScheme.surface, isNotNull);
      expect(lightTheme.colorScheme.onSurface, isNotNull);
      
      // Dark theme color scheme
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.primary, isNotNull);
      expect(darkTheme.colorScheme.onPrimary, isNotNull);
      expect(darkTheme.colorScheme.surface, isNotNull);
      expect(darkTheme.colorScheme.onSurface, isNotNull);
      
      // Colors should be different between light and dark themes
      expect(lightTheme.colorScheme.surface, isNot(equals(darkTheme.colorScheme.surface)));
    });

    testWidgets('should apply light theme to basic widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                Text('Test Text'),
                Card(child: Text('Test Card')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify theme is applied
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);
      
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.brightness, Brightness.light);
      
      // Verify widgets exist
      expect(find.text('Test Text'), findsOneWidget);
      expect(find.text('Test Card'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should apply Material Design 3 typography', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                Text('Display Large', style: AppTheme.lightTheme.textTheme.displayLarge),
                Text('Headline Medium', style: AppTheme.lightTheme.textTheme.headlineMedium),
                Text('Title Large', style: AppTheme.lightTheme.textTheme.titleLarge),
                Text('Body Large', style: AppTheme.lightTheme.textTheme.bodyLarge),
                Text('Label Medium', style: AppTheme.lightTheme.textTheme.labelMedium),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find text widgets and verify they exist
      expect(find.text('Display Large'), findsOneWidget);
      expect(find.text('Headline Medium'), findsOneWidget);
      expect(find.text('Title Large'), findsOneWidget);
      expect(find.text('Body Large'), findsOneWidget);
      expect(find.text('Label Medium'), findsOneWidget);
    });

    testWidgets('should apply button styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                FilledButton(onPressed: () {}, child: const Text('Filled')),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all button types exist
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}