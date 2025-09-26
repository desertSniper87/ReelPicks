/// Movie data model
class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final List<Genre> genres;
  final double voteAverage;
  final String releaseDate;
  final int? runtime;
  final double? userRating;
  final bool isWatched;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.genres,
    required this.voteAverage,
    required this.releaseDate,
    this.runtime,
    this.userRating,
    this.isWatched = false,
  });

  factory Movie.fromTMDbJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String,
      overview: json['overview'] as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((genre) => Genre.fromJson(genre as Map<String, dynamic>))
              .toList() ??
          [],
      voteAverage: (json['vote_average'] as num).toDouble(),
      releaseDate: json['release_date'] as String,
      runtime: json['runtime'] as int?,
      userRating: json['user_rating'] as double?,
      isWatched: json['is_watched'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'genres': genres.map((genre) => genre.toJson()).toList(),
      'vote_average': voteAverage,
      'release_date': releaseDate,
      'runtime': runtime,
      'user_rating': userRating,
      'is_watched': isWatched,
    };
  }

  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    List<Genre>? genres,
    double? voteAverage,
    String? releaseDate,
    int? runtime,
    double? userRating,
    bool? isWatched,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      genres: genres ?? this.genres,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      runtime: runtime ?? this.runtime,
      userRating: userRating ?? this.userRating,
      isWatched: isWatched ?? this.isWatched,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Genre data model
class Genre {
  final int id;
  final String name;

  const Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Genre && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}