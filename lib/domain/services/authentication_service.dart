import '../../core/utils/result.dart';

/// Abstract authentication service interface
abstract class AuthenticationService {
  /// Create a new request token for TMDb authentication
  Future<Result<String>> createRequestToken();
  
  /// Create a session using an approved request token
  Future<Result<String>> createSession(String approvedToken);
  
  /// Validate the current session
  Future<Result<bool>> validateSession();
  
  /// Get account details for the authenticated user
  Future<Result<Map<String, dynamic>>> getAccountDetails();
  
  /// Logout and clear session data
  Future<Result<void>> logout();
  
  /// Get the current session ID
  String? getCurrentSessionId();
  
  /// Check if user is currently authenticated
  bool get isAuthenticated;
  
  /// Get the TMDb authentication URL for user approval
  String getAuthenticationUrl(String requestToken);
}