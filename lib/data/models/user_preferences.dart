/// User preferences data model
class UserPreferences {
  final List<String> preferredGenres;
  final String? imdbProfileUrl;
  final String? letterboxdUsername;
  final bool enablePersonalization;
  final ViewMode defaultViewMode;

  const UserPreferences({
    required this.preferredGenres,
    this.imdbProfileUrl,
    this.letterboxdUsername,
    this.enablePersonalization = true,
    this.defaultViewMode = ViewMode.swipe,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredGenres: (json['preferred_genres'] as List<dynamic>)
          .map((genre) => genre as String)
          .toList(),
      imdbProfileUrl: json['imdb_profile_url'] as String?,
      letterboxdUsername: json['letterboxd_username'] as String?,
      enablePersonalization: json['enable_personalization'] as bool? ?? true,
      defaultViewMode: ViewMode.values.firstWhere(
        (mode) => mode.name == json['default_view_mode'],
        orElse: () => ViewMode.swipe,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_genres': preferredGenres,
      'imdb_profile_url': imdbProfileUrl,
      'letterboxd_username': letterboxdUsername,
      'enable_personalization': enablePersonalization,
      'default_view_mode': defaultViewMode.name,
    };
  }

  UserPreferences copyWith({
    List<String>? preferredGenres,
    String? imdbProfileUrl,
    String? letterboxdUsername,
    bool? enablePersonalization,
    ViewMode? defaultViewMode,
  }) {
    return UserPreferences(
      preferredGenres: preferredGenres ?? this.preferredGenres,
      imdbProfileUrl: imdbProfileUrl ?? this.imdbProfileUrl,
      letterboxdUsername: letterboxdUsername ?? this.letterboxdUsername,
      enablePersonalization: enablePersonalization ?? this.enablePersonalization,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          preferredGenres == other.preferredGenres &&
          imdbProfileUrl == other.imdbProfileUrl &&
          letterboxdUsername == other.letterboxdUsername &&
          enablePersonalization == other.enablePersonalization &&
          defaultViewMode == other.defaultViewMode;

  @override
  int get hashCode =>
      preferredGenres.hashCode ^
      imdbProfileUrl.hashCode ^
      letterboxdUsername.hashCode ^
      enablePersonalization.hashCode ^
      defaultViewMode.hashCode;
}

/// View mode enumeration
enum ViewMode { swipe, list }