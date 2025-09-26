import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_recommendation_app/presentation/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider themeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
      // Wait for initialization
      await themeProvider.initialized;
    });

    test('should initialize with system theme mode by default', () {
      expect(themeProvider.themeMode, ThemeMode.system);
      expect(themeProvider.isSystemMode, true);
    });

    test('should set theme mode and persist to shared preferences', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);
      
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
      expect(themeProvider.isLightMode, false);
      expect(themeProvider.isSystemMode, false);
    });

    test('should toggle theme mode correctly', () async {
      // Start with light
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
      
      // Toggle to dark
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.dark);
      
      // Toggle to system
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.system);
      
      // Toggle back to light
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('should return correct theme names', () async {
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.currentThemeName, 'Light');
      
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.currentThemeName, 'Dark');
      
      await themeProvider.setThemeMode(ThemeMode.system);
      expect(themeProvider.currentThemeName, 'System');
    });

    test('should return correct theme icons', () async {
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.currentThemeIcon, Icons.light_mode);
      
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.currentThemeIcon, Icons.dark_mode);
      
      await themeProvider.setThemeMode(ThemeMode.system);
      expect(themeProvider.currentThemeIcon, Icons.brightness_auto);
    });



    test('should notify listeners when theme changes', () async {
      bool notified = false;
      themeProvider.addListener(() {
        notified = true;
      });
      
      await themeProvider.setThemeMode(ThemeMode.dark);
      
      expect(notified, true);
    });
  });

  group('ThemeProvider SharedPreferences', () {
    test('should persist theme changes to shared preferences', () async {
      final provider = ThemeProvider();
      await provider.initialized;
      
      await provider.setThemeMode(ThemeMode.dark);
      
      // Create a new provider instance to test persistence
      final newProvider = ThemeProvider();
      await newProvider.initialized;
      
      // The new provider should load the persisted theme
      expect(newProvider.themeMode, ThemeMode.dark);
    });
  });
}