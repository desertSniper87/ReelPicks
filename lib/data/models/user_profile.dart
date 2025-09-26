/// User profile data model
class UserProfile {
  final String? tmdbSessionId;
  final int? tmdbAccountId;
  final String? imdbUsername;
  final String? letterboxdUsername;
  final List<String> preferredGenres;
  final bool isAuthenticated;

  const UserProfile({
    this.tmdbSessionId,
    this.tmdbAccountId,
    this.imdbUsername,
    this.letterboxdUsername,
    required this.preferredGenres,
    this.isAuthenticated = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      tmdbSessionId: json['tmdb_session_id'] as String?,
      tmdbAccountId: json['tmdb_account_id'] as int?,
      imdbUsername: json['imdb_username'] as String?,
      letterboxdUsername: json['letterboxd_username'] as String?,
      preferredGenres: (json['preferred_genres'] as List<dynamic>)
          .map((genre) => genre as String)
          .toList(),
      isAuthenticated: json['is_authenticated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tmdb_session_id': tmdbSessionId,
      'tmdb_account_id': tmdbAccountId,
      'imdb_username': imdbUsername,
      'letterboxd_username': letterboxdUsername,
      'preferred_genres': preferredGenres,
      'is_authenticated': isAuthenticated,
    };
  }

  UserProfile copyWith({
    String? tmdbSessionId,
    int? tmdbAccountId,
    String? imdbUsername,
    String? letterboxdUsername,
    List<String>? preferredGenres,
    bool? isAuthenticated,
  }) {
    return UserProfile(
      tmdbSessionId: tmdbSessionId ?? this.tmdbSessionId,
      tmdbAccountId: tmdbAccountId ?? this.tmdbAccountId,
      imdbUsername: imdbUsername ?? this.imdbUsername,
      letterboxdUsername: letterboxdUsername ?? this.letterboxdUsername,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          tmdbSessionId == other.tmdbSessionId &&
          tmdbAccountId == other.tmdbAccountId &&
          imdbUsername == other.imdbUsername &&
          letterboxdUsername == other.letterboxdUsername &&
          preferredGenres == other.preferredGenres &&
          isAuthenticated == other.isAuthenticated;

  @override
  int get hashCode =>
      tmdbSessionId.hashCode ^
      tmdbAccountId.hashCode ^
      imdbUsername.hashCode ^
      letterboxdUsername.hashCode ^
      preferredGenres.hashCode ^
      isAuthenticated.hashCode;
}