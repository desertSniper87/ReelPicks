import 'package:flutter/foundation.dart';
import '../../data/models/movie.dart';

/// Provider for managing movie recommendation state
class RecommendationProvider extends ChangeNotifier {
  List<Movie> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  int _currentIndex = 0;
  List<String> _selectedGenres = [];

  // Getters
  List<Movie> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  List<String> get selectedGenres => _selectedGenres;
  Movie? get currentMovie => 
      _recommendations.isNotEmpty && _currentIndex < _recommendations.length
          ? _recommendations[_currentIndex]
          : null;

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error state management
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Recommendation management
  void setRecommendations(List<Movie> recommendations) {
    _recommendations = recommendations;
    _currentIndex = 0;
    notifyListeners();
  }

  void addRecommendations(List<Movie> newRecommendations) {
    _recommendations.addAll(newRecommendations);
    notifyListeners();
  }

  // Navigation
  void nextMovie() {
    if (_currentIndex < _recommendations.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousMovie() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _recommendations.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Genre filtering
  void setSelectedGenres(List<String> genres) {
    _selectedGenres = genres;
    notifyListeners();
  }

  void addGenre(String genre) {
    if (!_selectedGenres.contains(genre)) {
      _selectedGenres.add(genre);
      notifyListeners();
    }
  }

  void removeGenre(String genre) {
    _selectedGenres.remove(genre);
    notifyListeners();
  }

  void clearGenres() {
    _selectedGenres.clear();
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _recommendations.clear();
    _currentIndex = 0;
    _error = null;
    _isLoading = false;
    _selectedGenres.clear();
    notifyListeners();
  }
}