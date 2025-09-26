import 'movie.dart';

/// Recommendation result data model
class RecommendationResult {
  final List<Movie> movies;
  final String source;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const RecommendationResult({
    required this.movies,
    required this.source,
    required this.metadata,
    required this.timestamp,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    return RecommendationResult(
      movies: (json['movies'] as List<dynamic>)
          .map((movie) => Movie.fromTMDbJson(movie as Map<String, dynamic>))
          .toList(),
      source: json['source'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movies': movies.map((movie) => movie.toJson()).toList(),
      'source': source,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  RecommendationResult copyWith({
    List<Movie>? movies,
    String? source,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return RecommendationResult(
      movies: movies ?? this.movies,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationResult &&
          runtimeType == other.runtimeType &&
          movies == other.movies &&
          source == other.source &&
          metadata == other.metadata &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      movies.hashCode ^
      source.hashCode ^
      metadata.hashCode ^
      timestamp.hashCode;
}