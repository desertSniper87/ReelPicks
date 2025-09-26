import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/data/models/user_preferences.dart';

void main() {
  group('UserPreferences Model Tests', () {
    group('fromJson', () {
      test('should create UserPreferences from complete JSON', () {
        // Arrange
        final json = {
          'preferred_genres': ['Action', 'Drama', 'Comedy'],
          'imdb_profile_url': 'https://www.imdb.com/user/ur12345678/',
          'letterboxd_username': 'moviefan123',
          'enable_personalization': true,
          'default_view_mode': 'list',
        };

        // Act
        final preferences = UserPreferences.fromJson(json);

        // Assert
        expect(preferences.preferredGenres, ['Action', 'Drama', 'Comedy']);
        expect(preferences.imdbProfileUrl, 'https://www.imdb.com/user/ur12345678/');
        expect(preferences.letterboxdUsername, 'moviefan123');
        expect(preferences.enablePersonalization, true);
        expect(preferences.defaultViewMode, ViewMode.list);
      });

      test('should create UserPreferences from minimal JSON with defaults', () {
        // Arrange
        final json = {
          'preferred_genres': ['Action'],
        };

        // Act
        final preferences = UserPreferences.fromJson(json);

        // Assert
        expect(preferences.preferredGenres, ['Action']);
        expect(preferences.imdbProfileUrl, null);
        expect(preferences.letterboxdUsername, null);
        expect(preferences.enablePersonalization, true);
        expect(preferences.defaultViewMode, ViewMode.swipe);
      });

      test('should handle null enable_personalization with default true', () {
        // Arrange
        final json = {
          'preferred_genres': ['Action'],
          'enable_personalization': null,
        };

        // Act
        final preferences = UserPreferences.fromJson(json);

        // Assert
        expect(preferences.enablePersonalization, true);
      });

      test('should handle invalid view mode with default swipe', () {
        // Arrange
        final json = {
          'preferred_genres': ['Action'],
          'default_view_mode': 'invalid_mode',
        };

        // Act
        final preferences = UserPreferences.fromJson(json);

        // Assert
        expect(preferences.defaultViewMode, ViewMode.swipe);
      });

      test('should handle empty preferred genres list', () {
        // Arrange
        final json = {
          'preferred_genres': <String>[],
        };

        // Act
        final preferences = UserPreferences.fromJson(json);

        // Assert
        expect(preferences.preferredGenres, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize UserPreferences to JSON correctly', () {
        // Arrange
        const preferences = UserPreferences(
          preferredGenres: ['Action', 'Drama'],
          imdbProfileUrl: 'https://www.imdb.com/user/ur12345678/',
          letterboxdUsername: 'moviefan123',
          enablePersonalization: false,
          defaultViewMode: ViewMode.list,
        );

        // Act
        final json = preferences.toJson();

        // Assert
        expect(json['preferred_genres'], ['Action', 'Drama']);
        expect(json['imdb_profile_url'], 'https://www.imdb.com/user/ur12345678/');
        expect(json['letterboxd_username'], 'moviefan123');
        expect(json['enable_personalization'], false);
        expect(json['default_view_mode'], 'list');
      });

      test('should serialize UserPreferences with null values correctly', () {
        // Arrange
        const preferences = UserPreferences(
          preferredGenres: ['Action'],
        );

        // Act
        final json = preferences.toJson();

        // Assert
        expect(json['preferred_genres'], ['Action']);
        expect(json['imdb_profile_url'], null);
        expect(json['letterboxd_username'], null);
        expect(json['enable_personalization'], true);
        expect(json['default_view_mode'], 'swipe');
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        // Arrange
        const original = UserPreferences(
          preferredGenres: ['Action'],
          imdbProfileUrl: 'https://www.imdb.com/user/ur12345678/',
          enablePersonalization: true,
          defaultViewMode: ViewMode.swipe,
        );

        // Act
        final updated = original.copyWith(
          preferredGenres: ['Drama', 'Comedy'],
          letterboxdUsername: 'newuser',
          enablePersonalization: false,
        );

        // Assert
        expect(updated.preferredGenres, ['Drama', 'Comedy']);
        expect(updated.imdbProfileUrl, 'https://www.imdb.com/user/ur12345678/');
        expect(updated.letterboxdUsername, 'newuser');
        expect(updated.enablePersonalization, false);
        expect(updated.defaultViewMode, ViewMode.swipe);
      });

      test('should create copy with same values when no parameters provided', () {
        // Arrange
        const original = UserPreferences(
          preferredGenres: ['Action'],
          imdbProfileUrl: 'https://www.imdb.com/user/ur12345678/',
          letterboxdUsername: 'moviefan123',
          enablePersonalization: false,
          defaultViewMode: ViewMode.list,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.preferredGenres, original.preferredGenres);
        expect(copy.imdbProfileUrl, original.imdbProfileUrl);
        expect(copy.letterboxdUsername, original.letterboxdUsername);
        expect(copy.enablePersonalization, original.enablePersonalization);
        expect(copy.defaultViewMode, original.defaultViewMode);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const preferences1 = UserPreferences(
          preferredGenres: ['Action', 'Drama'],
          imdbProfileUrl: 'https://www.imdb.com/user/ur12345678/',
          letterboxdUsername: 'moviefan123',
          enablePersonalization: true,
          defaultViewMode: ViewMode.list,
        );
        const preferences2 = UserPreferences(
          preferredGenres: ['Action', 'Drama'],
          imdbProfileUrl: 'https://www.imdb.com/user/ur12345678/',
          letterboxdUsername: 'moviefan123',
          enablePersonalization: true,
          defaultViewMode: ViewMode.list,
        );

        // Act & Assert
        expect(preferences1, equals(preferences2));
        expect(preferences1.hashCode, equals(preferences2.hashCode));
      });

      test('should not be equal when preferred genres are different', () {
        // Arrange
        const preferences1 = UserPreferences(
          preferredGenres: ['Action'],
        );
        const preferences2 = UserPreferences(
          preferredGenres: ['Drama'],
        );

        // Act & Assert
        expect(preferences1, isNot(equals(preferences2)));
        expect(preferences1.hashCode, isNot(equals(preferences2.hashCode)));
      });

      test('should not be equal when imdb profile url is different', () {
        // Arrange
        const preferences1 = UserPreferences(
          preferredGenres: ['Action'],
          imdbProfileUrl: 'https://www.imdb.com/user/ur12345678/',
        );
        const preferences2 = UserPreferences(
          preferredGenres: ['Action'],
          imdbProfileUrl: 'https://www.imdb.com/user/ur87654321/',
        );

        // Act & Assert
        expect(preferences1, isNot(equals(preferences2)));
      });

      test('should not be equal when letterboxd username is different', () {
        // Arrange
        const preferences1 = UserPreferences(
          preferredGenres: ['Action'],
          letterboxdUsername: 'user1',
        );
        const preferences2 = UserPreferences(
          preferredGenres: ['Action'],
          letterboxdUsername: 'user2',
        );

        // Act & Assert
        expect(preferences1, isNot(equals(preferences2)));
      });

      test('should not be equal when enable personalization is different', () {
        // Arrange
        const preferences1 = UserPreferences(
          preferredGenres: ['Action'],
          enablePersonalization: true,
        );
        const preferences2 = UserPreferences(
          preferredGenres: ['Action'],
          enablePersonalization: false,
        );

        // Act & Assert
        expect(preferences1, isNot(equals(preferences2)));
      });

      test('should not be equal when default view mode is different', () {
        // Arrange
        const preferences1 = UserPreferences(
          preferredGenres: ['Action'],
          defaultViewMode: ViewMode.swipe,
        );
        const preferences2 = UserPreferences(
          preferredGenres: ['Action'],
          defaultViewMode: ViewMode.list,
        );

        // Act & Assert
        expect(preferences1, isNot(equals(preferences2)));
      });
    });
  });

  group('ViewMode Enum Tests', () {
    test('should have correct enum values', () {
      expect(ViewMode.values, hasLength(2));
      expect(ViewMode.values, contains(ViewMode.swipe));
      expect(ViewMode.values, contains(ViewMode.list));
    });

    test('should have correct string names', () {
      expect(ViewMode.swipe.name, 'swipe');
      expect(ViewMode.list.name, 'list');
    });
  });
}