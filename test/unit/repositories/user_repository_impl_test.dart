import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/error/failures.dart';
import '../../../lib/core/utils/result.dart';
import '../../../lib/data/models/user_preferences.dart';
import '../../../lib/data/models/user_profile.dart';
import '../../../lib/data/repositories/user_repository_impl.dart';

import 'user_repository_impl_test.mocks.dart';

@GenerateMocks([SharedPreferences, FlutterSecureStorage])
void main() {
  late UserRepositoryImpl repository;
  late MockSharedPreferences mockSharedPreferences;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockSecureStorage = MockFlutterSecureStorage();
    repository = UserRepositoryImpl(
      sharedPreferences: mockSharedPreferences,
      secureStorage: mockSecureStorage,
    );
  });

  // Helper function to extract data from Success result
  T? getSuccessData<T>(Result<T> result) {
    return result.fold(
      (failure) => null,
      (data) => data,
    );
  }

  // Helper function to extract failure from ResultFailure
  Failure? getFailure<T>(Result<T> result) {
    return result.fold(
      (failure) => failure,
      (data) => null,
    );
  }

  group('UserRepositoryImpl', () {
    group('saveUserPreferences', () {
      test('should save user preferences successfully', () async {
        // Arrange
        const preferences = UserPreferences(
          preferredGenres: ['Action', 'Comedy'],
          imdbProfileUrl: 'https://imdb.com/user/test',
          letterboxdUsername: 'testuser',
          enablePersonalization: true,
          defaultViewMode: ViewMode.swipe,
        );

        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.saveUserPreferences(preferences);

        // Assert
        expect(result.isSuccess, true);
        verify(mockSharedPreferences.setString(
          'user_preferences',
          jsonEncode(preferences.toJson()),
        )).called(1);
      });

      test('should return failure when saving preferences fails', () async {
        // Arrange
        const preferences = UserPreferences(
          preferredGenres: ['Action'],
        );

        when(mockSharedPreferences.setString(any, any))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.saveUserPreferences(preferences);

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('getUserPreferences', () {
      test('should return user preferences when they exist', () async {
        // Arrange
        const preferences = UserPreferences(
          preferredGenres: ['Action', 'Comedy'],
          imdbProfileUrl: 'https://imdb.com/user/test',
          letterboxdUsername: 'testuser',
          enablePersonalization: true,
          defaultViewMode: ViewMode.list,
        );

        when(mockSharedPreferences.getString('user_preferences'))
            .thenReturn(jsonEncode(preferences.toJson()));

        // Act
        final result = await repository.getUserPreferences();

        // Assert
        expect(result.isSuccess, true);
        final retrievedPreferences = getSuccessData(result);
        expect(retrievedPreferences?.preferredGenres, equals(['Action', 'Comedy']));
        expect(retrievedPreferences?.imdbProfileUrl, equals('https://imdb.com/user/test'));
        expect(retrievedPreferences?.letterboxdUsername, equals('testuser'));
        expect(retrievedPreferences?.enablePersonalization, equals(true));
        expect(retrievedPreferences?.defaultViewMode, equals(ViewMode.list));
      });

      test('should return null when no preferences exist', () async {
        // Arrange
        when(mockSharedPreferences.getString('user_preferences'))
            .thenReturn(null);

        // Act
        final result = await repository.getUserPreferences();

        // Assert
        expect(result.isSuccess, true);
        expect(getSuccessData(result), isNull);
      });

      test('should return failure when getting preferences fails', () async {
        // Arrange
        when(mockSharedPreferences.getString('user_preferences'))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.getUserPreferences();

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('saveUserProfile', () {
      test('should save user profile with session ID in secure storage', () async {
        // Arrange
        const profile = UserProfile(
          tmdbSessionId: 'session123',
          tmdbAccountId: 456,
          imdbUsername: 'testuser',
          letterboxdUsername: 'testuser',
          preferredGenres: ['Action'],
          isAuthenticated: true,
        );

        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});
        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.saveUserProfile(profile);

        // Assert
        expect(result.isSuccess, true);
        verify(mockSecureStorage.write(
          key: 'tmdb_session_id',
          value: 'session123',
        )).called(1);
        verify(mockSharedPreferences.setString(
          'user_profile',
          any,
        )).called(1);
      });

      test('should save profile without session ID when null', () async {
        // Arrange
        const profile = UserProfile(
          tmdbAccountId: 456,
          preferredGenres: ['Action'],
          isAuthenticated: false,
        );

        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.saveUserProfile(profile);

        // Assert
        expect(result.isSuccess, true);
        verifyNever(mockSecureStorage.write(
          key: 'tmdb_session_id',
          value: anyNamed('value'),
        ));
      });

      test('should return failure when saving profile fails', () async {
        // Arrange
        const profile = UserProfile(
          preferredGenres: ['Action'],
        );

        when(mockSharedPreferences.setString(any, any))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.saveUserProfile(profile);

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('getUserProfile', () {
      test('should return user profile with session ID from secure storage', () async {
        // Arrange
        const profileData = {
          'tmdb_account_id': 456,
          'imdb_username': 'testuser',
          'letterboxd_username': 'testuser',
          'preferred_genres': ['Action'],
          'is_authenticated': true,
        };

        when(mockSharedPreferences.getString('user_profile'))
            .thenReturn(jsonEncode(profileData));
        when(mockSecureStorage.read(key: 'tmdb_session_id'))
            .thenAnswer((_) async => 'session123');

        // Act
        final result = await repository.getUserProfile();

        // Assert
        expect(result.isSuccess, true);
        final profile = getSuccessData(result);
        expect(profile?.tmdbSessionId, equals('session123'));
        expect(profile?.tmdbAccountId, equals(456));
        expect(profile?.isAuthenticated, equals(true));
      });

      test('should return null when no profile exists', () async {
        // Arrange
        when(mockSharedPreferences.getString('user_profile'))
            .thenReturn(null);

        // Act
        final result = await repository.getUserProfile();

        // Assert
        expect(result.isSuccess, true);
        expect(getSuccessData(result), isNull);
      });

      test('should return failure when getting profile fails', () async {
        // Arrange
        when(mockSharedPreferences.getString('user_profile'))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.getUserProfile();

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('saveImdbProfile', () {
      test('should save IMDb profile URL successfully', () async {
        // Arrange
        const profileUrl = 'https://imdb.com/user/test';
        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.saveImdbProfile(profileUrl);

        // Assert
        expect(result.isSuccess, true);
        verify(mockSharedPreferences.setString(
          'imdb_profile_url',
          profileUrl,
        )).called(1);
      });

      test('should return failure when saving IMDb profile fails', () async {
        // Arrange
        when(mockSharedPreferences.setString(any, any))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.saveImdbProfile('test');

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('saveLetterboxdProfile', () {
      test('should save Letterboxd username successfully', () async {
        // Arrange
        const username = 'testuser';
        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.saveLetterboxdProfile(username);

        // Assert
        expect(result.isSuccess, true);
        verify(mockSharedPreferences.setString(
          'letterboxd_username',
          username,
        )).called(1);
      });

      test('should return failure when saving Letterboxd profile fails', () async {
        // Arrange
        when(mockSharedPreferences.setString(any, any))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.saveLetterboxdProfile('test');

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('saveGenrePreferences', () {
      test('should save genre preferences successfully', () async {
        // Arrange
        const genres = ['Action', 'Comedy', 'Drama'];
        when(mockSharedPreferences.setStringList(any, any))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.saveGenrePreferences(genres);

        // Assert
        expect(result.isSuccess, true);
        verify(mockSharedPreferences.setStringList(
          'genre_preferences',
          genres,
        )).called(1);
      });

      test('should return failure when saving genre preferences fails', () async {
        // Arrange
        when(mockSharedPreferences.setStringList(any, any))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.saveGenrePreferences(['Action']);

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('getGenrePreferences', () {
      test('should return genre preferences when they exist', () async {
        // Arrange
        const genres = ['Action', 'Comedy', 'Drama'];
        when(mockSharedPreferences.getStringList('genre_preferences'))
            .thenReturn(genres);

        // Act
        final result = await repository.getGenrePreferences();

        // Assert
        expect(result.isSuccess, true);
        expect(getSuccessData(result), equals(genres));
      });

      test('should return empty list when no preferences exist', () async {
        // Arrange
        when(mockSharedPreferences.getStringList('genre_preferences'))
            .thenReturn(null);

        // Act
        final result = await repository.getGenrePreferences();

        // Assert
        expect(result.isSuccess, true);
        expect(getSuccessData(result), equals([]));
      });

      test('should return failure when getting genre preferences fails', () async {
        // Arrange
        when(mockSharedPreferences.getStringList('genre_preferences'))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.getGenrePreferences();

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('clearUserData', () {
      test('should clear all user data successfully', () async {
        // Arrange
        when(mockSharedPreferences.remove(any))
            .thenAnswer((_) async => true);
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.clearUserData();

        // Assert
        expect(result.isSuccess, true);
        verify(mockSharedPreferences.remove('user_preferences')).called(1);
        verify(mockSharedPreferences.remove('user_profile')).called(1);
        verify(mockSharedPreferences.remove('imdb_profile_url')).called(1);
        verify(mockSharedPreferences.remove('letterboxd_username')).called(1);
        verify(mockSharedPreferences.remove('genre_preferences')).called(1);
        verify(mockSecureStorage.delete(key: 'tmdb_session_id')).called(1);
        verify(mockSecureStorage.delete(key: 'tmdb_account_id')).called(1);
      });

      test('should return failure when clearing data fails', () async {
        // Arrange
        when(mockSharedPreferences.remove(any))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.clearUserData();

        // Assert
        expect(result.isFailure, true);
        expect(getFailure(result), isA<LocalStorageFailure>());
      });
    });

    group('helper methods', () {
      group('saveTmdbSession', () {
        test('should save TMDb session ID securely', () async {
          // Arrange
          const sessionId = 'session123';
          when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
              .thenAnswer((_) async {});

          // Act
          final result = await repository.saveTmdbSession(sessionId);

          // Assert
          expect(result.isSuccess, true);
          verify(mockSecureStorage.write(
            key: 'tmdb_session_id',
            value: sessionId,
          )).called(1);
        });
      });

      group('getTmdbSession', () {
        test('should return TMDb session ID', () async {
          // Arrange
          const sessionId = 'session123';
          when(mockSecureStorage.read(key: 'tmdb_session_id'))
              .thenAnswer((_) async => sessionId);

          // Act
          final result = await repository.getTmdbSession();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), equals(sessionId));
        });

        test('should return null when no session exists', () async {
          // Arrange
          when(mockSecureStorage.read(key: 'tmdb_session_id'))
              .thenAnswer((_) async => null);

          // Act
          final result = await repository.getTmdbSession();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), isNull);
        });
      });

      group('saveTmdbAccountId', () {
        test('should save TMDb account ID', () async {
          // Arrange
          const accountId = 123;
          when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
              .thenAnswer((_) async {});

          // Act
          final result = await repository.saveTmdbAccountId(accountId);

          // Assert
          expect(result.isSuccess, true);
          verify(mockSecureStorage.write(
            key: 'tmdb_account_id',
            value: accountId.toString(),
          )).called(1);
        });
      });

      group('getTmdbAccountId', () {
        test('should return TMDb account ID', () async {
          // Arrange
          const accountId = 123;
          when(mockSecureStorage.read(key: 'tmdb_account_id'))
              .thenAnswer((_) async => accountId.toString());

          // Act
          final result = await repository.getTmdbAccountId();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), equals(accountId));
        });

        test('should return null when no account ID exists', () async {
          // Arrange
          when(mockSecureStorage.read(key: 'tmdb_account_id'))
              .thenAnswer((_) async => null);

          // Act
          final result = await repository.getTmdbAccountId();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), isNull);
        });
      });

      group('hasUserData', () {
        test('should return true when user data exists', () async {
          // Arrange
          when(mockSharedPreferences.containsKey('user_preferences'))
              .thenReturn(true);
          when(mockSharedPreferences.containsKey('user_profile'))
              .thenReturn(false);
          when(mockSecureStorage.containsKey(key: 'tmdb_session_id'))
              .thenAnswer((_) async => false);

          // Act
          final result = await repository.hasUserData();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), true);
        });

        test('should return false when no user data exists', () async {
          // Arrange
          when(mockSharedPreferences.containsKey(any))
              .thenReturn(false);
          when(mockSecureStorage.containsKey(key: anyNamed('key')))
              .thenAnswer((_) async => false);

          // Act
          final result = await repository.hasUserData();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), false);
        });
      });

      group('getImdbProfile', () {
        test('should return IMDb profile URL', () async {
          // Arrange
          const profileUrl = 'https://imdb.com/user/test';
          when(mockSharedPreferences.getString('imdb_profile_url'))
              .thenReturn(profileUrl);

          // Act
          final result = await repository.getImdbProfile();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), equals(profileUrl));
        });
      });

      group('getLetterboxdProfile', () {
        test('should return Letterboxd username', () async {
          // Arrange
          const username = 'testuser';
          when(mockSharedPreferences.getString('letterboxd_username'))
              .thenReturn(username);

          // Act
          final result = await repository.getLetterboxdProfile();

          // Assert
          expect(result.isSuccess, true);
          expect(getSuccessData(result), equals(username));
        });
      });
    });
  });
}