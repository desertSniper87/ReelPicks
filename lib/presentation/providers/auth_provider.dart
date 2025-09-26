import 'package:flutter/foundation.dart';
import '../../domain/services/authentication_service.dart';

/// Provider for managing TMDb authentication state
class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService;

  String? _sessionId;
  int? _accountId;
  String? _username;
  String? _accountName;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _requestToken;
  bool _isInitialized = false;

  AuthProvider({required AuthenticationService authService})
      : _authService = authService;

  // Getters
  String? get sessionId => _sessionId;
  int? get accountId => _accountId;
  String? get username => _username;
  String? get accountName => _accountName;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get requestToken => _requestToken;
  bool get isInitialized => _isInitialized;

  // Loading state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error state management
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Initialize authentication service and restore session
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _setError(null);

    try {
      await _authService.initialize();
      
      // Check if user is already authenticated
      _isAuthenticated = _authService.isAuthenticated;
      _sessionId = _authService.getCurrentSessionId();

      if (_isAuthenticated) {
        // Load stored user info
        _username = await _authService.getStoredUsername();
        _accountName = await _authService.getStoredAccountName();
        
        // Validate current session
        final validationResult = await _authService.validateSession();
        validationResult.fold(
          (failure) {
            _setError('Session validation failed: ${failure.message}');
            _isAuthenticated = false;
            _sessionId = null;
          },
          (isValid) {
            if (!isValid) {
              _isAuthenticated = false;
              _sessionId = null;
            }
          },
        );
      }

      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Start authentication flow by creating request token
  Future<String?> startAuthentication() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.createRequestToken();
      return result.fold(
        (failure) {
          _setError('Failed to create request token: ${failure.message}');
          return null;
        },
        (token) {
          _requestToken = token;
          notifyListeners();
          return token;
        },
      );
    } catch (e) {
      _setError('Failed to start authentication: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete authentication flow by creating session
  Future<bool> completeAuthentication(String approvedToken) async {
    _setLoading(true);
    _setError(null);

    try {
      final sessionResult = await _authService.createSession(approvedToken);
      return await sessionResult.fold(
        (failure) async {
          _setError('Failed to create session: ${failure.message}');
          return false;
        },
        (sessionId) async {
          _sessionId = sessionId;
          _isAuthenticated = true;
          _requestToken = null;

          // Get account details
          final accountResult = await _authService.getAccountDetails();
          accountResult.fold(
            (failure) => _setError('Failed to get account details: ${failure.message}'),
            (accountData) {
              _accountId = accountData['id'] as int?;
              _username = accountData['username'] as String?;
              _accountName = accountData['name'] as String?;
            },
          );

          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _setError('Failed to complete authentication: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get TMDb authentication URL
  String getAuthenticationUrl(String requestToken) {
    return _authService.getAuthenticationUrl(requestToken);
  }

  /// Logout user and clear session
  Future<void> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.logout();
      result.fold(
        (failure) => _setError('Failed to logout: ${failure.message}'),
        (_) {
          _sessionId = null;
          _accountId = null;
          _username = null;
          _accountName = null;
          _isAuthenticated = false;
          _requestToken = null;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Failed to logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Validate current session
  Future<bool> validateSession() async {
    if (!_isAuthenticated || _sessionId == null) return false;

    try {
      final result = await _authService.validateSession();
      return result.fold(
        (failure) {
          _setError('Session validation failed: ${failure.message}');
          return false;
        },
        (isValid) {
          if (!isValid) {
            _isAuthenticated = false;
            _sessionId = null;
            notifyListeners();
          }
          return isValid;
        },
      );
    } catch (e) {
      _setError('Failed to validate session: ${e.toString()}');
      return false;
    }
  }

  // Clear all authentication data
  void clear() {
    _sessionId = null;
    _accountId = null;
    _username = null;
    _accountName = null;
    _isAuthenticated = false;
    _requestToken = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  /// Refresh authentication state
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  /// Set session details for testing purposes
  void setSessionDetails({String? sessionId, int? accountId}) {
    _sessionId = sessionId;
    _accountId = accountId;
    _isAuthenticated = sessionId != null;
    notifyListeners();
  }
}