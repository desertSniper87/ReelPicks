import '../../core/utils/result.dart';

/// Abstract authentication repository interface
abstract class AuthenticationRepository {
  /// Create a new request token for TMDb authentication
  Future<Result<String>> createRequestToken();
  
  /// Create a session using an approved request token
  Future<Result<String>> createSession(String approvedToken);
  
  /// Validate the current session
  Future<Result<bool>> validateSession();
  
  /// Get account details for the current session
  Future<Result<Map<String, dynamic>>> getAccountDetails();
  
  /// Logout and clear session
  Future<Result<void>> logout();
  
  /// Get the current session ID
  String? getCurrentSessionId();
  
  /// Check if user is currently authenticated
  bool get isAuthenticated;
}