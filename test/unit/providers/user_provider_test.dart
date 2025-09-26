import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:movie_recommendation_app/presentation/providers/user_provider.dart';
import 'package:movie_recommendation_app/domain/repositories/user_repository.dart';
import 'package:movie_recommendation_app/data/models/user_preferences.dart';
import 'package:movie_recommendation_app/data/models/user_profile.dart';
import 'package:movie_recommendation_app/core/utils/result.dart';
import 'package:movie_recommendation_app/core/error/failures.dart';

import 'user_provider_test.mocks.dart';

@GenerateMocks([UserRepository])
void main() {
  late UserProvider provider;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockUserRepository = MockUserRepository();
    provider = UserProvider(userRepository: mockUserRepository);
  });

  group('UserProvider', () {
    final testUserPreferences = UserPreferences(
      preferredGenres: ['Action', 'Comedy'],
      imdbProfileUrl: 'https://imdb.com/user/test',
      letterboxdUsername: 'testuser',
      enablePersonalization: true,
      defaultViewMode: ViewMode.swipe,
    );

    final testUserProfile = UserProfile(
      tmdbSessionId: 'test_session',
      tmdbAccountId: 123,
      imdbUsername: 'testuser',
      letterboxdUsername: 'testuser',
      preferredGenres: ['Action', 'Comedy'],
      isAuthenticated: true,
    );

    group('Initial State', () {
      test('should have correct initial values', () {
        expect(provider.userPreferences, null);
        expect(provider.userProfile, null);
        expect(provider.isLoading, false);
        expect(provider.error, null);
        expect(provider.isAuthenticated, false);
        expect(provider.isInitialized, false);
      });
    });

    group('initialize', () {
      test('should initialize user data successfully', () async {
        // Arrange
        when(mockUserRepository.getUserPreferences())
            .thenAnswer((_) async => Success(testUserPreferences));
        when(mockUserRepository.getUserProfile())
            .thenAnswer((_) async => Success(testUserProfile));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.userPreferences, testUserPreferences);
        expect(provider.userProfile, testUserProfile);
        expect(provider.isInitialized, true);
        expect(provider.isLoading, false);
        expect(provider.error, null);
        expect(provider.isAuthenticated, true);
      });

      test('should handle failure when loading preferences', () async {
        // Arrange
        const failure = CacheFailure('Failed to load preferences');
        when(mockUserRepository.getUserPreferences())
            .thenAnswer((_) async => ResultFailure(failure));
        when(mockUserRepository.getUserProfile())
            .thenAnswer((_) async => Success(testUserProfile));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.userPreferences, null);
        expect(provider.userProfile, testUserProfile);
        expect(provider.error, 'Failed to load preferences: Failed to load preferences');
        expect(provider.isInitialized, true);
      });

      test('should handle failure when loading profile', () async {
        // Arrange
        const failure = CacheFailure('Failed to load profile');
        when(mockUserRepository.getUserPreferences())
            .thenAnswer((_) async => Success(testUserPreferences));
        when(mockUserRepository.getUserProfile())
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.userPreferences, testUserPreferences);
        expect(provider.userProfile, null);
        expect(provider.error, 'Failed to load profile: Failed to load profile');
        expect(provider.isInitialized, true);
      });

      test('should not initialize twice', () async {
        // Arrange
        when(mockUserRepository.getUserPreferences())
            .thenAnswer((_) async => Success(testUserPreferences));
        when(mockUserRepository.getUserProfile())
            .thenAnswer((_) async => Success(testUserProfile));

        // Act
        await provider.initialize();
        await provider.initialize();

        // Assert
        verify(mockUserRepository.getUserPreferences()).called(1);
        verify(mockUserRepository.getUserProfile()).called(1);
      });
    });

    group('User Preferences Management', () {
      test('should save user preferences successfully', () async {
        // Arrange
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.saveUserPreferences(testUserPreferences);

        // Assert
        expect(provider.userPreferences, testUserPreferences);
        expect(provider.isLoading, false);
        expect(provider.error, null);
        verify(mockUserRepository.saveUserPreferences(testUserPreferences)).called(1);
      });

      test('should handle failure when saving preferences', () async {
        // Arrange
        const failure = CacheFailure('Save failed');
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.saveUserPreferences(testUserPreferences);

        // Assert
        expect(provider.userPreferences, null);
        expect(provider.error, 'Failed to save preferences: Save failed');
        expect(provider.isLoading, false);
      });

      test('should update preferred genres', () async {
        // Arrange
        provider.saveUserPreferences(testUserPreferences);
        await untilCalled(mockUserRepository.saveUserPreferences(any));
        
        const newGenres = ['Drama', 'Thriller'];
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updatePreferredGenres(newGenres);

        // Assert
        expect(provider.userPreferences?.preferredGenres, newGenres);
      });

      test('should create new preferences when updating genres with no existing preferences', () async {
        // Arrange
        const newGenres = ['Drama', 'Thriller'];
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updatePreferredGenres(newGenres);

        // Assert
        expect(provider.userPreferences?.preferredGenres, newGenres);
        expect(provider.userPreferences?.enablePersonalization, true);
        expect(provider.userPreferences?.defaultViewMode, ViewMode.swipe);
      });

      test('should update IMDb profile', () async {
        // Arrange
        provider.saveUserPreferences(testUserPreferences);
        await untilCalled(mockUserRepository.saveUserPreferences(any));
        
        const newImdbUrl = 'https://imdb.com/user/newuser';
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updateImdbProfile(newImdbUrl);

        // Assert
        expect(provider.userPreferences?.imdbProfileUrl, newImdbUrl);
      });

      test('should update Letterboxd profile', () async {
        // Arrange
        provider.saveUserPreferences(testUserPreferences);
        await untilCalled(mockUserRepository.saveUserPreferences(any));
        
        const newUsername = 'newuser';
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updateLetterboxdProfile(newUsername);

        // Assert
        expect(provider.userPreferences?.letterboxdUsername, newUsername);
      });

      test('should update personalization enabled', () async {
        // Arrange
        await provider.saveUserPreferences(testUserPreferences);
        
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updatePersonalizationEnabled(false);

        // Assert
        expect(provider.userPreferences?.enablePersonalization, false);
      });

      test('should update default view mode', () async {
        // Arrange
        await provider.saveUserPreferences(testUserPreferences);
        
        when(mockUserRepository.saveUserPreferences(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updateDefaultViewMode(ViewMode.list);

        // Assert
        expect(provider.userPreferences?.defaultViewMode, ViewMode.list);
      });
    });

    group('User Profile Management', () {
      test('should save user profile successfully', () async {
        // Arrange
        when(mockUserRepository.saveUserProfile(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.saveUserProfile(testUserProfile);

        // Assert
        expect(provider.userProfile, testUserProfile);
        expect(provider.isLoading, false);
        expect(provider.error, null);
        verify(mockUserRepository.saveUserProfile(testUserProfile)).called(1);
      });

      test('should handle failure when saving profile', () async {
        // Arrange
        const failure = CacheFailure('Save failed');
        when(mockUserRepository.saveUserProfile(any))
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.saveUserProfile(testUserProfile);

        // Assert
        expect(provider.userProfile, null);
        expect(provider.error, 'Failed to save profile: Save failed');
        expect(provider.isLoading, false);
      });

      test('should update TMDb session', () async {
        // Arrange
        when(mockUserRepository.saveUserProfile(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updateTmdbSession('new_session', 456);

        // Assert
        expect(provider.userProfile?.tmdbSessionId, 'new_session');
        expect(provider.userProfile?.tmdbAccountId, 456);
        expect(provider.userProfile?.isAuthenticated, true);
      });

      test('should update IMDb username', () async {
        // Arrange
        provider.saveUserProfile(testUserProfile);
        await untilCalled(mockUserRepository.saveUserProfile(any));
        
        when(mockUserRepository.saveUserProfile(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updateImdbUsername('newuser');

        // Assert
        expect(provider.userProfile?.imdbUsername, 'newuser');
      });

      test('should update Letterboxd username', () async {
        // Arrange
        provider.saveUserProfile(testUserProfile);
        await untilCalled(mockUserRepository.saveUserProfile(any));
        
        when(mockUserRepository.saveUserProfile(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.updateLetterboxdUsername('newuser');

        // Assert
        expect(provider.userProfile?.letterboxdUsername, 'newuser');
      });
    });

    group('Data Management', () {
      test('should clear user data successfully', () async {
        // Arrange
        provider.saveUserProfile(testUserProfile);
        provider.saveUserPreferences(testUserPreferences);
        await untilCalled(mockUserRepository.saveUserProfile(any));
        await untilCalled(mockUserRepository.saveUserPreferences(any));
        
        when(mockUserRepository.clearUserData())
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.clearUserData();

        // Assert
        expect(provider.userProfile, null);
        expect(provider.userPreferences, null);
        expect(provider.isInitialized, false);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle failure when clearing data', () async {
        // Arrange
        const failure = CacheFailure('Clear failed');
        when(mockUserRepository.clearUserData())
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.clearUserData();

        // Assert
        expect(provider.error, 'Failed to clear user data: Clear failed');
        expect(provider.isLoading, false);
      });

      test('should logout user', () async {
        // Arrange
        await provider.saveUserProfile(testUserProfile);
        
        when(mockUserRepository.saveUserProfile(any))
            .thenAnswer((_) async => const Success(null));

        // Act
        await provider.logout();

        // Assert
        expect(provider.userProfile?.isAuthenticated, false);
        expect(provider.userProfile?.tmdbSessionId, null);
        expect(provider.userProfile?.tmdbAccountId, null);
      });

      test('should refresh user data', () async {
        // Arrange
        when(mockUserRepository.getUserPreferences())
            .thenAnswer((_) async => Success(testUserPreferences));
        when(mockUserRepository.getUserProfile())
            .thenAnswer((_) async => Success(testUserProfile));

        // Initialize first
        await provider.initialize();
        
        // Act
        await provider.refresh();

        // Assert
        verify(mockUserRepository.getUserPreferences()).called(2);
        verify(mockUserRepository.getUserProfile()).called(2);
      });

      test('should clear error', () {
        // Arrange
        provider.clearUserData();

        // Act
        provider.clearError();

        // Assert
        expect(provider.error, null);
      });
    });
  });
}