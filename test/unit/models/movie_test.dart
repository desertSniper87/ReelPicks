import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/data/models/movie.dart';

void main() {
  group('Movie Model Tests', () {
    group('fromTMDbJson', () {
      test('should create Movie from complete TMDb JSON', () {
        // Arrange
        final json = {
          'id': 550,
          'title': 'Fight Club',
          'overview': 'A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.',
          'poster_path': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
          'backdrop_path': '/fCayJrkfRaCRCTh8GqN30f8oyQF.jpg',
          'genres': [
            {'id': 18, 'name': 'Drama'},
            {'id': 53, 'name': 'Thriller'}
          ],
          'vote_average': 8.433,
          'release_date': '1999-10-15',
          'runtime': 139,
          'user_rating': 9.0,
          'is_watched': true,
        };

        // Act
        final movie = Movie.fromTMDbJson(json);

        // Assert
        expect(movie.id, 550);
        expect(movie.title, 'Fight Club');
        expect(movie.overview, 'A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.');
        expect(movie.posterPath, '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg');
        expect(movie.backdropPath, '/fCayJrkfRaCRCTh8GqN30f8oyQF.jpg');
        expect(movie.genres.length, 2);
        expect(movie.genres[0].id, 18);
        expect(movie.genres[0].name, 'Drama');
        expect(movie.genres[1].id, 53);
        expect(movie.genres[1].name, 'Thriller');
        expect(movie.voteAverage, 8.433);
        expect(movie.releaseDate, '1999-10-15');
        expect(movie.runtime, 139);
        expect(movie.userRating, 9.0);
        expect(movie.isWatched, true);
      });

      test('should create Movie from minimal TMDb JSON', () {
        // Arrange
        final json = {
          'id': 550,
          'title': 'Fight Club',
          'overview': 'A great movie',
          'vote_average': 8.4,
          'release_date': '1999-10-15',
        };

        // Act
        final movie = Movie.fromTMDbJson(json);

        // Assert
        expect(movie.id, 550);
        expect(movie.title, 'Fight Club');
        expect(movie.overview, 'A great movie');
        expect(movie.posterPath, null);
        expect(movie.backdropPath, null);
        expect(movie.genres, isEmpty);
        expect(movie.voteAverage, 8.4);
        expect(movie.releaseDate, '1999-10-15');
        expect(movie.runtime, null);
        expect(movie.userRating, null);
        expect(movie.isWatched, false);
      });

      test('should handle null genres list', () {
        // Arrange
        final json = {
          'id': 550,
          'title': 'Fight Club',
          'overview': 'A great movie',
          'vote_average': 8.4,
          'release_date': '1999-10-15',
          'genres': null,
        };

        // Act
        final movie = Movie.fromTMDbJson(json);

        // Assert
        expect(movie.genres, isEmpty);
      });

      test('should handle vote_average as int', () {
        // Arrange
        final json = {
          'id': 550,
          'title': 'Fight Club',
          'overview': 'A great movie',
          'vote_average': 8,
          'release_date': '1999-10-15',
        };

        // Act
        final movie = Movie.fromTMDbJson(json);

        // Assert
        expect(movie.voteAverage, 8.0);
      });
    });

    group('toJson', () {
      test('should serialize Movie to JSON correctly', () {
        // Arrange
        final movie = Movie(
          id: 550,
          title: 'Fight Club',
          overview: 'A great movie',
          posterPath: '/poster.jpg',
          backdropPath: '/backdrop.jpg',
          genres: [
            const Genre(id: 18, name: 'Drama'),
            const Genre(id: 53, name: 'Thriller'),
          ],
          voteAverage: 8.4,
          releaseDate: '1999-10-15',
          runtime: 139,
          userRating: 9.0,
          isWatched: true,
        );

        // Act
        final json = movie.toJson();

        // Assert
        expect(json['id'], 550);
        expect(json['title'], 'Fight Club');
        expect(json['overview'], 'A great movie');
        expect(json['poster_path'], '/poster.jpg');
        expect(json['backdrop_path'], '/backdrop.jpg');
        expect(json['genres'], hasLength(2));
        expect(json['genres'][0]['id'], 18);
        expect(json['genres'][0]['name'], 'Drama');
        expect(json['vote_average'], 8.4);
        expect(json['release_date'], '1999-10-15');
        expect(json['runtime'], 139);
        expect(json['user_rating'], 9.0);
        expect(json['is_watched'], true);
      });

      test('should serialize Movie with null values correctly', () {
        // Arrange
        final movie = Movie(
          id: 550,
          title: 'Fight Club',
          overview: 'A great movie',
          genres: const [],
          voteAverage: 8.4,
          releaseDate: '1999-10-15',
        );

        // Act
        final json = movie.toJson();

        // Assert
        expect(json['poster_path'], null);
        expect(json['backdrop_path'], null);
        expect(json['runtime'], null);
        expect(json['user_rating'], null);
        expect(json['is_watched'], false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        // Arrange
        final original = Movie(
          id: 550,
          title: 'Fight Club',
          overview: 'Original overview',
          genres: const [],
          voteAverage: 8.4,
          releaseDate: '1999-10-15',
        );

        // Act
        final updated = original.copyWith(
          title: 'Updated Title',
          userRating: 9.0,
          isWatched: true,
        );

        // Assert
        expect(updated.id, 550);
        expect(updated.title, 'Updated Title');
        expect(updated.overview, 'Original overview');
        expect(updated.userRating, 9.0);
        expect(updated.isWatched, true);
        expect(updated.voteAverage, 8.4);
      });

      test('should create copy with same values when no parameters provided', () {
        // Arrange
        final original = Movie(
          id: 550,
          title: 'Fight Club',
          overview: 'Original overview',
          genres: const [],
          voteAverage: 8.4,
          releaseDate: '1999-10-15',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.overview, original.overview);
        expect(copy.voteAverage, original.voteAverage);
        expect(copy.releaseDate, original.releaseDate);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when ids are the same', () {
        // Arrange
        final movie1 = Movie(
          id: 550,
          title: 'Fight Club',
          overview: 'Overview 1',
          genres: const [],
          voteAverage: 8.4,
          releaseDate: '1999-10-15',
        );
        final movie2 = Movie(
          id: 550,
          title: 'Different Title',
          overview: 'Overview 2',
          genres: const [],
          voteAverage: 7.0,
          releaseDate: '2000-01-01',
        );

        // Act & Assert
        expect(movie1, equals(movie2));
        expect(movie1.hashCode, equals(movie2.hashCode));
      });

      test('should not be equal when ids are different', () {
        // Arrange
        final movie1 = Movie(
          id: 550,
          title: 'Fight Club',
          overview: 'Overview',
          genres: const [],
          voteAverage: 8.4,
          releaseDate: '1999-10-15',
        );
        final movie2 = Movie(
          id: 551,
          title: 'Fight Club',
          overview: 'Overview',
          genres: const [],
          voteAverage: 8.4,
          releaseDate: '1999-10-15',
        );

        // Act & Assert
        expect(movie1, isNot(equals(movie2)));
        expect(movie1.hashCode, isNot(equals(movie2.hashCode)));
      });
    });
  });

  group('Genre Model Tests', () {
    group('fromJson', () {
      test('should create Genre from JSON', () {
        // Arrange
        final json = {
          'id': 18,
          'name': 'Drama',
        };

        // Act
        final genre = Genre.fromJson(json);

        // Assert
        expect(genre.id, 18);
        expect(genre.name, 'Drama');
      });
    });

    group('toJson', () {
      test('should serialize Genre to JSON correctly', () {
        // Arrange
        const genre = Genre(id: 18, name: 'Drama');

        // Act
        final json = genre.toJson();

        // Assert
        expect(json['id'], 18);
        expect(json['name'], 'Drama');
      });
    });

    group('equality and hashCode', () {
      test('should be equal when ids are the same', () {
        // Arrange
        const genre1 = Genre(id: 18, name: 'Drama');
        const genre2 = Genre(id: 18, name: 'Different Name');

        // Act & Assert
        expect(genre1, equals(genre2));
        expect(genre1.hashCode, equals(genre2.hashCode));
      });

      test('should not be equal when ids are different', () {
        // Arrange
        const genre1 = Genre(id: 18, name: 'Drama');
        const genre2 = Genre(id: 19, name: 'Drama');

        // Act & Assert
        expect(genre1, isNot(equals(genre2)));
        expect(genre1.hashCode, isNot(equals(genre2.hashCode)));
      });
    });
  });
}