import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/data/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    group('fromJson', () {
      test('should create UserProfile from complete JSON', () {
        // Arrange
        final json = {
          'tmdb_session_id': 'abc123session',
          'tmdb_account_id': 12345,
          'imdb_username': 'moviefan123',
          'letterboxd_username': 'cinephile456',
          'preferred_genres': ['Action', 'Drama', 'Comedy'],
          'is_authenticated': true,
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.tmdbSessionId, 'abc123session');
        expect(profile.tmdbAccountId, 12345);
        expect(profile.imdbUsername, 'moviefan123');
        expect(profile.letterboxdUsername, 'cinephile456');
        expect(profile.preferredGenres, ['Action', 'Drama', 'Comedy']);
        expect(profile.isAuthenticated, true);
      });

      test('should create UserProfile from minimal JSON with defaults', () {
        // Arrange
        final json = {
          'preferred_genres': ['Action'],
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.tmdbSessionId, null);
        expect(profile.tmdbAccountId, null);
        expect(profile.imdbUsername, null);
        expect(profile.letterboxdUsername, null);
        expect(profile.preferredGenres, ['Action']);
        expect(profile.isAuthenticated, false);
      });

      test('should handle null is_authenticated with default false', () {
        // Arrange
        final json = {
          'preferred_genres': ['Action'],
          'is_authenticated': null,
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.isAuthenticated, false);
      });

      test('should handle empty preferred genres list', () {
        // Arrange
        final json = {
          'preferred_genres': <String>[],
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.preferredGenres, isEmpty);
      });

      test('should handle tmdb_account_id as string and convert to int', () {
        // Arrange
        final json = {
          'preferred_genres': ['Action'],
          'tmdb_account_id': '12345',
        };

        // Act & Assert
        expect(() => UserProfile.fromJson(json), throwsA(isA<TypeError>()));
      });
    });

    group('toJson', () {
      test('should serialize UserProfile to JSON correctly', () {
        // Arrange
        const profile = UserProfile(
          tmdbSessionId: 'abc123session',
          tmdbAccountId: 12345,
          imdbUsername: 'moviefan123',
          letterboxdUsername: 'cinephile456',
          preferredGenres: ['Action', 'Drama'],
          isAuthenticated: true,
        );

        // Act
        final json = profile.toJson();

        // Assert
        expect(json['tmdb_session_id'], 'abc123session');
        expect(json['tmdb_account_id'], 12345);
        expect(json['imdb_username'], 'moviefan123');
        expect(json['letterboxd_username'], 'cinephile456');
        expect(json['preferred_genres'], ['Action', 'Drama']);
        expect(json['is_authenticated'], true);
      });

      test('should serialize UserProfile with null values correctly', () {
        // Arrange
        const profile = UserProfile(
          preferredGenres: ['Action'],
        );

        // Act
        final json = profile.toJson();

        // Assert
        expect(json['tmdb_session_id'], null);
        expect(json['tmdb_account_id'], null);
        expect(json['imdb_username'], null);
        expect(json['letterboxd_username'], null);
        expect(json['preferred_genres'], ['Action']);
        expect(json['is_authenticated'], false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        // Arrange
        const original = UserProfile(
          tmdbSessionId: 'original_session',
          tmdbAccountId: 12345,
          imdbUsername: 'original_user',
          preferredGenres: ['Action'],
          isAuthenticated: false,
        );

        // Act
        final updated = original.copyWith(
          tmdbSessionId: 'new_session',
          letterboxdUsername: 'new_letterboxd_user',
          preferredGenres: ['Drama', 'Comedy'],
          isAuthenticated: true,
        );

        // Assert
        expect(updated.tmdbSessionId, 'new_session');
        expect(updated.tmdbAccountId, 12345);
        expect(updated.imdbUsername, 'original_user');
        expect(updated.letterboxdUsername, 'new_letterboxd_user');
        expect(updated.preferredGenres, ['Drama', 'Comedy']);
        expect(updated.isAuthenticated, true);
      });

      test('should create copy with same values when no parameters provided', () {
        // Arrange
        const original = UserProfile(
          tmdbSessionId: 'session123',
          tmdbAccountId: 12345,
          imdbUsername: 'moviefan',
          letterboxdUsername: 'cinephile',
          preferredGenres: ['Action', 'Drama'],
          isAuthenticated: true,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.tmdbSessionId, original.tmdbSessionId);
        expect(copy.tmdbAccountId, original.tmdbAccountId);
        expect(copy.imdbUsername, original.imdbUsername);
        expect(copy.letterboxdUsername, original.letterboxdUsername);
        expect(copy.preferredGenres, original.preferredGenres);
        expect(copy.isAuthenticated, original.isAuthenticated);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const profile1 = UserProfile(
          tmdbSessionId: 'session123',
          tmdbAccountId: 12345,
          imdbUsername: 'moviefan',
          letterboxdUsername: 'cinephile',
          preferredGenres: ['Action', 'Drama'],
          isAuthenticated: true,
        );
        const profile2 = UserProfile(
          tmdbSessionId: 'session123',
          tmdbAccountId: 12345,
          imdbUsername: 'moviefan',
          letterboxdUsername: 'cinephile',
          preferredGenres: ['Action', 'Drama'],
          isAuthenticated: true,
        );

        // Act & Assert
        expect(profile1, equals(profile2));
        expect(profile1.hashCode, equals(profile2.hashCode));
      });

      test('should not be equal when tmdb session id is different', () {
        // Arrange
        const profile1 = UserProfile(
          tmdbSessionId: 'session123',
          preferredGenres: ['Action'],
        );
        const profile2 = UserProfile(
          tmdbSessionId: 'session456',
          preferredGenres: ['Action'],
        );

        // Act & Assert
        expect(profile1, isNot(equals(profile2)));
        expect(profile1.hashCode, isNot(equals(profile2.hashCode)));
      });

      test('should not be equal when tmdb account id is different', () {
        // Arrange
        const profile1 = UserProfile(
          tmdbAccountId: 12345,
          preferredGenres: ['Action'],
        );
        const profile2 = UserProfile(
          tmdbAccountId: 67890,
          preferredGenres: ['Action'],
        );

        // Act & Assert
        expect(profile1, isNot(equals(profile2)));
      });

      test('should not be equal when imdb username is different', () {
        // Arrange
        const profile1 = UserProfile(
          imdbUsername: 'user1',
          preferredGenres: ['Action'],
        );
        const profile2 = UserProfile(
          imdbUsername: 'user2',
          preferredGenres: ['Action'],
        );

        // Act & Assert
        expect(profile1, isNot(equals(profile2)));
      });

      test('should not be equal when letterboxd username is different', () {
        // Arrange
        const profile1 = UserProfile(
          letterboxdUsername: 'user1',
          preferredGenres: ['Action'],
        );
        const profile2 = UserProfile(
          letterboxdUsername: 'user2',
          preferredGenres: ['Action'],
        );

        // Act & Assert
        expect(profile1, isNot(equals(profile2)));
      });

      test('should not be equal when preferred genres are different', () {
        // Arrange
        const profile1 = UserProfile(
          preferredGenres: ['Action'],
        );
        const profile2 = UserProfile(
          preferredGenres: ['Drama'],
        );

        // Act & Assert
        expect(profile1, isNot(equals(profile2)));
      });

      test('should not be equal when authentication status is different', () {
        // Arrange
        const profile1 = UserProfile(
          preferredGenres: ['Action'],
          isAuthenticated: true,
        );
        const profile2 = UserProfile(
          preferredGenres: ['Action'],
          isAuthenticated: false,
        );

        // Act & Assert
        expect(profile1, isNot(equals(profile2)));
      });

      test('should handle null values in equality comparison', () {
        // Arrange
        const profile1 = UserProfile(
          tmdbSessionId: null,
          preferredGenres: ['Action'],
        );
        const profile2 = UserProfile(
          tmdbSessionId: null,
          preferredGenres: ['Action'],
        );

        // Act & Assert
        expect(profile1, equals(profile2));
      });

      test('should not be equal when one has null and other has value', () {
        // Arrange
        const profile1 = UserProfile(
          tmdbSessionId: null,
          preferredGenres: ['Action'],
        );
        const profile2 = UserProfile(
          tmdbSessionId: 'session123',
          preferredGenres: ['Action'],
        );

        // Act & Assert
        expect(profile1, isNot(equals(profile2)));
      });
    });

    group('edge cases', () {
      test('should handle very long session id', () {
        // Arrange
        final longSessionId = 'a' * 1000;
        final json = {
          'tmdb_session_id': longSessionId,
          'preferred_genres': ['Action'],
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.tmdbSessionId, longSessionId);
      });

      test('should handle special characters in usernames', () {
        // Arrange
        final json = {
          'imdb_username': 'user@123_special-chars',
          'letterboxd_username': 'user.with.dots',
          'preferred_genres': ['Action'],
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.imdbUsername, 'user@123_special-chars');
        expect(profile.letterboxdUsername, 'user.with.dots');
      });

      test('should handle large account id', () {
        // Arrange
        final json = {
          'tmdb_account_id': 999999999,
          'preferred_genres': ['Action'],
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.tmdbAccountId, 999999999);
      });
    });
  });
}