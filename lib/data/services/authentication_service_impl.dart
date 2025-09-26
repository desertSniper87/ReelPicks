import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/services/authentication_service.dart';
import '../datasources/tmdb_client.dart';

/// Concrete implementation of AuthenticationService using TMDb API
class AuthenticationServiceImpl implements AuthenticationService {
  final TMDbClient _tmdbClient;
  final FlutterSecureStorage _secureStorage;
  String? _currentSessionId;
  int? _currentAccountId;

  // Storage keys for secure storage
  static const String _sessionIdKey = 'tmdb_session_id';
  static const String _accountIdKey = 'tmdb_account_id';
  static const String _usernameKey = 'tmdb_username';
  static const String _accountNameKey = 'tmdb_account_name';

  AuthenticationServiceImpl({
    required TMDbClient tmdbClient,
    FlutterSecureStorage? secureStorage,
  }) : _tmdbClient = tmdbClient,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<Result<String>> createRequestToken() async {
    try {
      final token = await _tmdbClient.createRequestToken();
      return Success(token);
    } on AuthenticationException catch (e) {
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<String>> createSession(String approvedToken) async {
    try {
      final sessionId = await _tmdbClient.createSession(approvedToken);
      _currentSessionId = sessionId;
      
      // Get account details to store account ID and other info
      final accountDetails = await _tmdbClient.getAccountDetails(sessionId);
      _currentAccountId = accountDetails['id'] as int?;
      
      // Store session and account information securely
      await _storeSessionData(
        sessionId: sessionId,
        accountId: _currentAccountId,
        username: accountDetails['username'] as String?,
        accountName: accountDetails['name'] as String?,
      );
      
      return Success(sessionId);
    } on AuthenticationException catch (e) {
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> validateSession() async {
    if (_currentSessionId == null) {
      return const ResultFailure(AuthenticationFailure('No active session'));
    }

    try {
      // Try to get account details to validate the session
      await _tmdbClient.getAccountDetails(_currentSessionId!);
      return const Success(true);
    } on AuthenticationException catch (e) {
      // Session is invalid, clear it
      _currentSessionId = null;
      _currentAccountId = null;
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Clear local session data
      _currentSessionId = null;
      _currentAccountId = null;
      
      // Clear secure storage
      await _clearSessionData();
      
      // Clear any cached data in the client
      _tmdbClient.clearCache();
      
      return const Success(null);
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Logout failed: ${e.toString()}'));
    }
  }

  @override
  String? getCurrentSessionId() {
    return _currentSessionId;
  }

  @override
  bool get isAuthenticated => _currentSessionId != null && _currentAccountId != null;

  @override
  String getAuthenticationUrl(String requestToken) {
    return 'https://www.themoviedb.org/authenticate/$requestToken';
  }

  @override
  Future<Result<Map<String, dynamic>>> getAccountDetails() async {
    if (_currentSessionId == null) {
      return const ResultFailure(AuthenticationFailure('No active session'));
    }

    try {
      final accountDetails = await _tmdbClient.getAccountDetails(_currentSessionId!);
      return Success(accountDetails);
    } on AuthenticationException catch (e) {
      return ResultFailure(AuthenticationFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message, e.code));
    } on ApiException catch (e) {
      return ResultFailure(ApiFailure(e.message, e.code));
    } on Exception catch (e) {
      return ResultFailure(ApiFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Get current account ID (useful for repository operations)
  int? getCurrentAccountId() {
    return _currentAccountId;
  }

  /// Set session details (useful for restoring from storage)
  void setSessionDetails({String? sessionId, int? accountId}) {
    _currentSessionId = sessionId;
    _currentAccountId = accountId;
  }

  /// Initialize authentication service by restoring session from secure storage
  Future<void> initialize() async {
    try {
      final sessionId = await _secureStorage.read(key: _sessionIdKey);
      final accountIdStr = await _secureStorage.read(key: _accountIdKey);
      
      if (sessionId != null && accountIdStr != null) {
        final accountId = int.tryParse(accountIdStr);
        if (accountId != null) {
          _currentSessionId = sessionId;
          _currentAccountId = accountId;
          
          // Validate the restored session
          final validationResult = await validateSession();
          if (validationResult is ResultFailure) {
            // Session is invalid, clear it
            await _clearSessionData();
          }
        }
      }
    } catch (e) {
      // If there's any error reading from secure storage, continue without session
      _currentSessionId = null;
      _currentAccountId = null;
    }
  }

  /// Store session data securely
  Future<void> _storeSessionData({
    required String sessionId,
    required int? accountId,
    String? username,
    String? accountName,
  }) async {
    try {
      await _secureStorage.write(key: _sessionIdKey, value: sessionId);
      
      if (accountId != null) {
        await _secureStorage.write(key: _accountIdKey, value: accountId.toString());
      }
      
      if (username != null) {
        await _secureStorage.write(key: _usernameKey, value: username);
      }
      
      if (accountName != null) {
        await _secureStorage.write(key: _accountNameKey, value: accountName);
      }
    } catch (e) {
      // Log error but don't throw - the session is still valid in memory
      // In a real app, you might want to log this error
    }
  }

  /// Clear all session data from secure storage
  Future<void> _clearSessionData() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _sessionIdKey),
        _secureStorage.delete(key: _accountIdKey),
        _secureStorage.delete(key: _usernameKey),
        _secureStorage.delete(key: _accountNameKey),
      ]);
    } catch (e) {
      // Log error but don't throw - we're clearing data anyway
    }
  }

  /// Get stored username from secure storage
  Future<String?> getStoredUsername() async {
    try {
      return await _secureStorage.read(key: _usernameKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored account name from secure storage
  Future<String?> getStoredAccountName() async {
    try {
      return await _secureStorage.read(key: _accountNameKey);
    } catch (e) {
      return null;
    }
  }
}