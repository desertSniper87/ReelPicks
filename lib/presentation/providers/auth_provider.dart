import 'package:flutter/foundation.dart';

/// Provider for managing TMDb authentication state
class AuthProvider extends ChangeNotifier {
  String? _sessionId;
  int? _accountId;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _requestToken;

  // Getters
  String? get sessionId => _sessionId;
  int? get accountId => _accountId;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get requestToken => _requestToken;

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

  // Authentication state management
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    notifyListeners();
  }

  void setSessionId(String? sessionId) {
    _sessionId = sessionId;
    _isAuthenticated = sessionId != null;
    notifyListeners();
  }

  void setAccountId(int? accountId) {
    _accountId = accountId;
    notifyListeners();
  }

  void setRequestToken(String? token) {
    _requestToken = token;
    notifyListeners();
  }

  // Authentication actions
  void login(String sessionId, int accountId) {
    _sessionId = sessionId;
    _accountId = accountId;
    _isAuthenticated = true;
    _error = null;
    notifyListeners();
  }

  void logout() {
    _sessionId = null;
    _accountId = null;
    _isAuthenticated = false;
    _requestToken = null;
    _error = null;
    notifyListeners();
  }

  // Clear all authentication data
  void clear() {
    _sessionId = null;
    _accountId = null;
    _isAuthenticated = false;
    _requestToken = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}