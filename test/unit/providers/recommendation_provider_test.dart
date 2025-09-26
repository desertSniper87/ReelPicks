import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:movie_recommendation_app/presentation/providers/recommendation_provider.dart';
import 'package:movie_recommendation_app/domain/services/recommendation_service.dart';
import 'package:movie_recommendation_app/domain/repositories/movie_repository.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';
import 'package:movie_recommendation_app/data/models/user_profile.dart';
import 'package:movie_recommendation_app/data/models/recommendation_result.dart';
import 'package:movie_recommendation_app/core/utils/result.dart';
import 'package:movie_recommendation_app/core/error/failures.dart';

import 'recommendation_provider_test.mocks.dart';

@GenerateMocks([RecommendationService, MovieRepository])
void main() {
  late RecommendationProvider provider;
  late MockRecommendationService mockRecommendationService;
  late MockMovieRepository mockMovieRepository;

  setUp(() {
    mockRecommendationService = MockRecommendationService();
    mockMovieRepository = MockMovieRepository();
    provider = RecommendationProvider(
      recommendationService: mockRecommendationService,
      movieRepository: mockMovieRepository,
    );
  });

  group('RecommendationProvider', () {
    final testMovies = [
      Movie(
        id: 1,
        title: 'Test Movie 1',
        overview: 'Test overview 1',
        posterPath: '/test1.jpg',
        genres: [Genre(id: 1, name: 'Action')],
        voteAverage: 7.5,
        releaseDate: '2023-01-01',
        runtime: 120,
      ),
      Movie(
        id: 2,
        title: 'Test Movie 2',
        overview: 'Test overview 2',
        posterPath: '/test2.jpg',
        genres: [Genre(id: 2, name: 'Comedy')],
        voteAverage: 8.0,
        releaseDate: '2023-02-01',
        runtime: 110,
      ),
    ];

    final testUserProfile = UserProfile(
      tmdbSessionId: 'test_session',
      tmdbAccountId: 123,
      preferredGenres: ['Action', 'Comedy'],
      isAuthenticated: true,
    );

    final testRecommendationResult = RecommendationResult(
      movies: testMovies,
      source: 'personalized',
      metadata: {},
      timestamp: DateTime.now(),
    );

    group('Initial State', () {
      test('should have correct initial values', () {
        expect(provider.recommendations, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, null);
        expect(provider.currentIndex, 0);
        expect(provider.selectedGenres, isEmpty);
        expect(provider.currentSource, 'popular');
        expect(provider.hasMorePages, true);
        expect(provider.currentMovie, null);
        expect(provider.availableGenres, isEmpty);
        expect(provider.isLoadingGenres, false);
        expect(provider.genreError, null);
      });
    });

    group('loadPersonalizedRecommendations', () {
      test('should load personalized recommendations successfully', () async {
        // Arrange
        when(mockRecommendationService.getPersonalizedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));

        // Act
        await provider.loadPersonalizedRecommendations(testUserProfile);

        // Assert
        expect(provider.recommendations, testMovies);
        expect(provider.currentSource, 'personalized');
        expect(provider.isLoading, false);
        expect(provider.error, null);
        expect(provider.currentMovie, testMovies.first);
      });

      test('should handle failure when loading personalized recommendations', () async {
        // Arrange
        const failure = NetworkFailure('Network error');
        when(mockRecommendationService.getPersonalizedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.loadPersonalizedRecommendations(testUserProfile);

        // Assert
        expect(provider.recommendations, isEmpty);
        expect(provider.error, 'Network error');
        expect(provider.isLoading, false);
      });

      test('should append recommendations when not refreshing', () async {
        // Arrange
        provider.loadPersonalizedRecommendations(testUserProfile);
        await untilCalled(mockRecommendationService.getPersonalizedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        ));

        when(mockRecommendationService.getPersonalizedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));

        // Act
        await provider.loadPersonalizedRecommendations(testUserProfile);

        // Assert
        expect(provider.recommendations.length, testMovies.length);
      });
    });

    group('loadGenreRecommendations', () {
      test('should load genre-based recommendations successfully', () async {
        // Arrange
        const genres = ['Action', 'Comedy'];
        when(mockRecommendationService.getGenreBasedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));

        // Act
        await provider.loadGenreRecommendations(genres);

        // Assert
        expect(provider.recommendations, testMovies);
        expect(provider.currentSource, 'genre');
        expect(provider.selectedGenres, genres);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle failure when loading genre recommendations', () async {
        // Arrange
        const genres = ['Action'];
        const failure = ApiFailure('API error');
        when(mockRecommendationService.getGenreBasedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.loadGenreRecommendations(genres);

        // Assert
        expect(provider.recommendations, isEmpty);
        expect(provider.error, 'API error');
        expect(provider.isLoading, false);
      });
    });

    group('loadPopularMovies', () {
      test('should load popular movies successfully', () async {
        // Arrange
        when(mockRecommendationService.getPopularMovies(
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));

        // Act
        await provider.loadPopularMovies();

        // Assert
        expect(provider.recommendations, testMovies);
        expect(provider.currentSource, 'popular');
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle failure when loading popular movies', () async {
        // Arrange
        const failure = NetworkFailure('Connection failed');
        when(mockRecommendationService.getPopularMovies(
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.loadPopularMovies();

        // Assert
        expect(provider.recommendations, isEmpty);
        expect(provider.error, 'Connection failed');
        expect(provider.isLoading, false);
      });
    });

    group('Navigation', () {
      setUp(() async {
        when(mockRecommendationService.getPopularMovies(
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));
        await provider.loadPopularMovies();
      });

      test('should navigate to next movie', () {
        // Act
        provider.nextMovie();

        // Assert
        expect(provider.currentIndex, 1);
        expect(provider.currentMovie, testMovies[1]);
      });

      test('should not navigate beyond last movie', () {
        // Arrange
        provider.setCurrentIndex(testMovies.length - 1);

        // Act
        provider.nextMovie();

        // Assert
        expect(provider.currentIndex, testMovies.length - 1);
      });

      test('should navigate to previous movie', () {
        // Arrange
        provider.nextMovie();

        // Act
        provider.previousMovie();

        // Assert
        expect(provider.currentIndex, 0);
        expect(provider.currentMovie, testMovies[0]);
      });

      test('should not navigate before first movie', () {
        // Act
        provider.previousMovie();

        // Assert
        expect(provider.currentIndex, 0);
      });

      test('should set current index correctly', () {
        // Act
        provider.setCurrentIndex(1);

        // Assert
        expect(provider.currentIndex, 1);
        expect(provider.currentMovie, testMovies[1]);
      });

      test('should not set invalid index', () {
        // Act
        provider.setCurrentIndex(-1);
        provider.setCurrentIndex(testMovies.length);

        // Assert
        expect(provider.currentIndex, 0);
      });
    });

    group('Genre Management', () {
      test('should set selected genres', () {
        // Arrange
        const genres = ['Action', 'Comedy'];

        // Act
        provider.setSelectedGenres(genres);

        // Assert
        expect(provider.selectedGenres, genres);
      });

      test('should add genre', () {
        // Act
        provider.addGenre('Action');

        // Assert
        expect(provider.selectedGenres, contains('Action'));
      });

      test('should not add duplicate genre', () {
        // Arrange
        provider.addGenre('Action');

        // Act
        provider.addGenre('Action');

        // Assert
        expect(provider.selectedGenres.where((g) => g == 'Action').length, 1);
      });

      test('should remove genre', () {
        // Arrange
        provider.addGenre('Action');
        provider.addGenre('Comedy');

        // Act
        provider.removeGenre('Action');

        // Assert
        expect(provider.selectedGenres, ['Comedy']);
      });

      test('should clear all genres', () {
        // Arrange
        provider.addGenre('Action');
        provider.addGenre('Comedy');

        // Act
        provider.clearGenres();

        // Assert
        expect(provider.selectedGenres, isEmpty);
      });
    });

    group('Movie Rating', () {
      test('should rate movie successfully and exclude it', () async {
        // Arrange
        when(mockRecommendationService.getPopularMovies(
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));
        await provider.loadPopularMovies();

        when(mockMovieRepository.rateMovie(any, any))
            .thenAnswer((_) async => const Success(true));

        // Act
        final result = await provider.rateMovie(1, 8.0);

        // Assert
        expect(result, true);
        expect(provider.recommendations.any((m) => m.id == 1), false);
      });

      test('should handle rating failure', () async {
        // Arrange
        const failure = ApiFailure('Rating failed');
        when(mockMovieRepository.rateMovie(any, any))
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        final result = await provider.rateMovie(1, 8.0);

        // Assert
        expect(result, false);
        expect(provider.error, 'Failed to rate movie: Rating failed');
      });
    });

    group('Genre Loading and Filtering', () {
      final testGenres = [
        const Genre(id: 28, name: 'Action'),
        const Genre(id: 35, name: 'Comedy'),
        const Genre(id: 18, name: 'Drama'),
        const Genre(id: 27, name: 'Horror'),
      ];

      test('should load genres successfully', () async {
        // Arrange
        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => Success(testGenres));

        // Act
        await provider.loadGenres();

        // Assert
        expect(provider.availableGenres, testGenres);
        expect(provider.isLoadingGenres, false);
        expect(provider.genreError, null);
      });

      test('should handle genre loading failure', () async {
        // Arrange
        const failure = ApiFailure('Failed to load genres');
        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.loadGenres();

        // Assert
        expect(provider.availableGenres, isEmpty);
        expect(provider.genreError, 'Failed to load genres');
        expect(provider.isLoadingGenres, false);
      });

      test('should not reload genres if already loaded', () async {
        // Arrange
        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => Success(testGenres));
        await provider.loadGenres();
        reset(mockMovieRepository);

        // Act
        await provider.loadGenres();

        // Assert
        verifyNever(mockMovieRepository.getGenres());
      });

      test('should apply genre filter with real-time filtering', () async {
        // Arrange
        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => Success(testGenres));
        await provider.loadGenres();

        when(mockMovieRepository.discoverMovies(
          genreIds: anyNamed('genreIds'),
          page: anyNamed('page'),
          sortBy: anyNamed('sortBy'),
        )).thenAnswer((_) async => Success(testMovies));

        // Act
        await provider.applyGenreFilterRealTime(['Action', 'Comedy'], testUserProfile);

        // Assert
        expect(provider.selectedGenres, ['Action', 'Comedy']);
        expect(provider.currentSource, 'genre');
        verify(mockMovieRepository.discoverMovies(
          genreIds: [28, 35], // Action and Comedy IDs
          page: 1,
          sortBy: 'popularity.desc',
        )).called(1);
      });

      test('should load personalized recommendations when no genres selected', () async {
        // Arrange
        when(mockRecommendationService.getPersonalizedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));

        // Act
        await provider.applyGenreFilterRealTime([], testUserProfile);

        // Assert
        expect(provider.selectedGenres, isEmpty);
        expect(provider.currentSource, 'personalized');
        verify(mockRecommendationService.getPersonalizedRecommendations(
          testUserProfile,
          page: 1,
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).called(1);
      });

      test('should load popular movies when no genres selected and user not authenticated', () async {
        // Arrange
        final unauthenticatedProfile = testUserProfile.copyWith(isAuthenticated: false);
        when(mockRecommendationService.getPopularMovies(
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));

        // Act
        await provider.applyGenreFilterRealTime([], unauthenticatedProfile);

        // Assert
        expect(provider.selectedGenres, isEmpty);
        expect(provider.currentSource, 'popular');
        verify(mockRecommendationService.getPopularMovies(
          page: 1,
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).called(1);
      });

      test('should toggle genre correctly', () async {
        // Arrange
        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => Success(testGenres));
        await provider.loadGenres();

        when(mockMovieRepository.discoverMovies(
          genreIds: anyNamed('genreIds'),
          page: anyNamed('page'),
          sortBy: anyNamed('sortBy'),
        )).thenAnswer((_) async => Success(testMovies));

        // Act - Add genre
        await provider.toggleGenre('Action', testUserProfile);

        // Assert
        expect(provider.selectedGenres, ['Action']);

        // Act - Remove genre
        await provider.toggleGenre('Action', testUserProfile);

        // Assert
        expect(provider.selectedGenres, isEmpty);
      });

      test('should clear genre filters', () async {
        // Arrange
        provider.setSelectedGenres(['Action', 'Comedy']);
        when(mockRecommendationService.getPersonalizedRecommendations(
          any,
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));

        // Act
        await provider.clearGenreFilters(testUserProfile);

        // Assert
        expect(provider.selectedGenres, isEmpty);
      });

      test('should get genre by name', () async {
        // Arrange
        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => Success(testGenres));
        await provider.loadGenres();

        // Act
        final actionGenre = provider.getGenreByName('Action');
        final nonExistentGenre = provider.getGenreByName('NonExistent');

        // Assert
        expect(actionGenre, const Genre(id: 28, name: 'Action'));
        expect(nonExistentGenre, null);
      });

      test('should get selected genre objects', () async {
        // Arrange
        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => Success(testGenres));
        await provider.loadGenres();
        provider.setSelectedGenres(['Action', 'Comedy']);

        // Act
        final selectedGenreObjects = provider.selectedGenreObjects;

        // Assert
        expect(selectedGenreObjects, [
          const Genre(id: 28, name: 'Action'),
          const Genre(id: 35, name: 'Comedy'),
        ]);
      });

      test('should filter out rated and watched movies from genre recommendations', () async {
        // Arrange
        final unratedMovie = Movie(
          id: 100,
          title: 'Unrated Movie',
          overview: 'Not rated yet',
          posterPath: '/unrated.jpg',
          genres: [const Genre(id: 28, name: 'Action')],
          voteAverage: 7.0,
          releaseDate: '2023-01-01',
          runtime: 120,
          userRating: null, // Not rated
          isWatched: false, // Not watched
        );
        
        final ratedMovie = Movie(
          id: 101,
          title: 'Rated Movie',
          overview: 'Already rated',
          posterPath: '/rated.jpg',
          genres: [const Genre(id: 28, name: 'Action')],
          voteAverage: 8.0,
          releaseDate: '2023-01-01',
          runtime: 120,
          userRating: 8.0, // Rated
          isWatched: true, // Watched
        );
        
        final moviesWithRated = [unratedMovie, ratedMovie];

        when(mockMovieRepository.getGenres())
            .thenAnswer((_) async => Success(testGenres));
        await provider.loadGenres();

        when(mockMovieRepository.discoverMovies(
          genreIds: anyNamed('genreIds'),
          page: anyNamed('page'),
          sortBy: anyNamed('sortBy'),
        )).thenAnswer((_) async => Success(moviesWithRated));

        // Act
        await provider.applyGenreFilterRealTime(['Action'], testUserProfile);

        // Assert - Only unrated/unwatched movies should be included
        expect(provider.recommendations.length, 1);
        expect(provider.recommendations.first.id, unratedMovie.id);
      });
    });

    group('Utility Methods', () {
      test('should determine if more recommendations should be loaded', () async {
        // Arrange
        when(mockRecommendationService.getPopularMovies(
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(testRecommendationResult));
        await provider.loadPopularMovies();

        // Act & Assert
        expect(provider.shouldLoadMore(0), false); // Too early
        expect(provider.shouldLoadMore(testMovies.length - 3), false); // Near end but list is too short
        
        // Test with longer list
        final longMovieList = List.generate(25, (i) => Movie(
          id: i + 10,
          title: 'Movie $i',
          overview: 'Overview $i',
          posterPath: '/test$i.jpg',
          genres: [Genre(id: 1, name: 'Action')],
          voteAverage: 7.0,
          releaseDate: '2023-01-01',
          runtime: 120,
        ));
        
        final longRecommendationResult = RecommendationResult(
          movies: longMovieList,
          source: 'popular',
          metadata: {},
          timestamp: DateTime.now(),
        );
        
        when(mockRecommendationService.getPopularMovies(
          page: anyNamed('page'),
          excludeMovieIds: anyNamed('excludeMovieIds'),
        )).thenAnswer((_) async => Success(longRecommendationResult));
        
        await provider.loadPopularMovies(refresh: true);
        expect(provider.shouldLoadMore(longMovieList.length - 3), true); // Near end with long list
      });

      test('should clear all data', () {
        // Arrange
        provider.addGenre('Action');
        provider.setCurrentIndex(1);

        // Act
        provider.clear();

        // Assert
        expect(provider.recommendations, isEmpty);
        expect(provider.currentIndex, 0);
        expect(provider.selectedGenres, isEmpty);
        expect(provider.error, null);
        expect(provider.isLoading, false);
        expect(provider.currentSource, 'popular');
      });

      test('should clear error', () {
        // Arrange
        provider.loadPopularMovies();

        // Act
        provider.clearError();

        // Assert
        expect(provider.error, null);
      });
    });
  });
}