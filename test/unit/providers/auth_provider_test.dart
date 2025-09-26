import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:movie_recommendation_app/presentation/providers/auth_provider.dart';
import 'package:movie_recommendation_app/domain/services/authentication_service.dart';
import 'package:movie_recommendation_app/core/utils/result.dart';
import 'package:movie_recommendation_app/core/error/failures.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([AuthenticationService])
void main() {
  late AuthProvider provider;
  late MockAuthenticationService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthenticationService();
    provider = AuthProvider(authService: mockAuthService);
  });

  group('AuthProvider', () {
    const testSessionId = 'test_session_123';
    const testAccountId = 456;
    const testUsername = 'testuser';
    const testAccountName = 'Test User';
    const testRequestToken = 'test_token_123';

    final testAccountData = {
      'id': testAccountId,
      'username': testUsername,
      'name': testAccountName,
    };

    group('Initial State', () {
      test('should have correct initial values', () {
        expect(provider.sessionId, null);
        expect(provider.accountId, null);
        expect(provider.username, null);
        expect(provider.accountName, null);
        expect(provider.isAuthenticated, false);
        expect(provider.isLoading, false);
        expect(provider.error, null);
        expect(provider.requestToken, null);
        expect(provider.isInitialized, false);
      });
    });

    group('initialize', () {
      test('should initialize with existing authenticated session', () async {
        // Arrange
        when(mockAuthService.initialize()).thenAnswer((_) async {});
        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentSessionId()).thenReturn(testSessionId);
        when(mockAuthService.getStoredUsername()).thenAnswer((_) async => testUsername);
        when(mockAuthService.getStoredAccountName()).thenAnswer((_) async => testAccountName);
        when(mockAuthService.validateSession()).thenAnswer((_) async => const Success(true));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.isAuthenticated, true);
        expect(provider.sessionId, testSessionId);
        expect(provider.username, testUsername);
        expect(provider.accountName, testAccountName);
        expect(provider.isInitialized, true);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should initialize with no existing session', () async {
        // Arrange
        when(mockAuthService.initialize()).thenAnswer((_) async {});
        when(mockAuthService.isAuthenticated).thenReturn(false);
        when(mockAuthService.getCurrentSessionId()).thenReturn(null);

        // Act
        await provider.initialize();

        // Assert
        expect(provider.isAuthenticated, false);
        expect(provider.sessionId, null);
        expect(provider.isInitialized, true);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle session validation failure', () async {
        // Arrange
        when(mockAuthService.initialize()).thenAnswer((_) async {});
        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentSessionId()).thenReturn(testSessionId);
        when(mockAuthService.getStoredUsername()).thenAnswer((_) async => testUsername);
        when(mockAuthService.getStoredAccountName()).thenAnswer((_) async => testAccountName);
        
        const failure = AuthenticationFailure('Session expired');
        when(mockAuthService.validateSession()).thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.isAuthenticated, false);
        expect(provider.sessionId, null);
        expect(provider.error, 'Session validation failed: Session expired');
        expect(provider.isInitialized, true);
      });

      test('should handle invalid session', () async {
        // Arrange
        when(mockAuthService.initialize()).thenAnswer((_) async {});
        when(mockAuthService.isAuthenticated).thenReturn(true);
        when(mockAuthService.getCurrentSessionId()).thenReturn(testSessionId);
        when(mockAuthService.getStoredUsername()).thenAnswer((_) async => testUsername);
        when(mockAuthService.getStoredAccountName()).thenAnswer((_) async => testAccountName);
        when(mockAuthService.validateSession()).thenAnswer((_) async => const Success(false));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.isAuthenticated, false);
        expect(provider.sessionId, null);
        expect(provider.isInitialized, true);
      });

      test('should not initialize twice', () async {
        // Arrange
        when(mockAuthService.initialize()).thenAnswer((_) async {});
        when(mockAuthService.isAuthenticated).thenReturn(false);
        when(mockAuthService.getCurrentSessionId()).thenReturn(null);

        // Act
        await provider.initialize();
        await provider.initialize();

        // Assert
        verify(mockAuthService.initialize()).called(1);
      });
    });

    group('startAuthentication', () {
      test('should start authentication successfully', () async {
        // Arrange
        when(mockAuthService.createRequestToken())
            .thenAnswer((_) async => const Success(testRequestToken));

        // Act
        final result = await provider.startAuthentication();

        // Assert
        expect(result, testRequestToken);
        expect(provider.requestToken, testRequestToken);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle failure when creating request token', () async {
        // Arrange
        const failure = ApiFailure('Token creation failed');
        when(mockAuthService.createRequestToken())
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        final result = await provider.startAuthentication();

        // Assert
        expect(result, null);
        expect(provider.requestToken, null);
        expect(provider.error, 'Failed to create request token: Token creation failed');
        expect(provider.isLoading, false);
      });
    });

    group('completeAuthentication', () {
      test('should complete authentication successfully', () async {
        // Arrange
        when(mockAuthService.createSession(any))
            .thenAnswer((_) async => const Success(testSessionId));
        when(mockAuthService.getAccountDetails())
            .thenAnswer((_) async => Success(testAccountData));

        // Act
        final result = await provider.completeAuthentication(testRequestToken);

        // Assert
        expect(result, true);
        expect(provider.sessionId, testSessionId);
        expect(provider.accountId, testAccountId);
        expect(provider.username, testUsername);
        expect(provider.accountName, testAccountName);
        expect(provider.isAuthenticated, true);
        expect(provider.requestToken, null);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle session creation failure', () async {
        // Arrange
        const failure = AuthenticationFailure('Session creation failed');
        when(mockAuthService.createSession(any))
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        final result = await provider.completeAuthentication(testRequestToken);

        // Assert
        expect(result, false);
        expect(provider.sessionId, null);
        expect(provider.isAuthenticated, false);
        expect(provider.error, 'Failed to create session: Session creation failed');
        expect(provider.isLoading, false);
      });

      test('should handle account details failure', () async {
        // Arrange
        when(mockAuthService.createSession(any))
            .thenAnswer((_) async => const Success(testSessionId));
        
        const failure = ApiFailure('Account details failed');
        when(mockAuthService.getAccountDetails())
            .thenAnswer((_) async => ResultFailure(failure));

        // Act
        final result = await provider.completeAuthentication(testRequestToken);

        // Assert
        expect(result, true);
        expect(provider.sessionId, testSessionId);
        expect(provider.isAuthenticated, true);
        expect(provider.accountId, null);
        expect(provider.username, null);
        expect(provider.accountName, null);
        expect(provider.error, 'Failed to get account details: Account details failed');
      });
    });

    group('getAuthenticationUrl', () {
      test('should return authentication URL', () {
        // Arrange
        const expectedUrl = 'https://www.themoviedb.org/authenticate/$testRequestToken';
        when(mockAuthService.getAuthenticationUrl(testRequestToken))
            .thenReturn(expectedUrl);

        // Act
        final url = provider.getAuthenticationUrl(testRequestToken);

        // Assert
        expect(url, expectedUrl);
      });
    });

    group('logout', () {
      test('should logout successfully', () async {
        // Arrange
        // Set up authenticated state first
        provider.completeAuthentication(testRequestToken);
        await untilCalled(mockAuthService.createSession(any));
        
        when(mockAuthService.logout()).thenAnswer((_) async => const Success(null));

        // Act
        await provider.logout();

        // Assert
        expect(provider.sessionId, null);
        expect(provider.accountId, null);
        expect(provider.username, null);
        expect(provider.accountName, null);
        expect(provider.isAuthenticated, false);
        expect(provider.requestToken, null);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle logout failure', () async {
        // Arrange
        const failure = AuthenticationFailure('Logout failed');
        when(mockAuthService.logout()).thenAnswer((_) async => ResultFailure(failure));

        // Act
        await provider.logout();

        // Assert
        expect(provider.error, 'Failed to logout: Logout failed');
        expect(provider.isLoading, false);
      });
    });

    group('validateSession', () {
      test('should validate session successfully', () async {
        // Arrange
        // Set up authenticated state first
        when(mockAuthService.createSession(any))
            .thenAnswer((_) async => const Success(testSessionId));
        when(mockAuthService.getAccountDetails())
            .thenAnswer((_) async => Success(testAccountData));
        
        await provider.completeAuthentication(testRequestToken);
        
        when(mockAuthService.validateSession()).thenAnswer((_) async => const Success(true));

        // Act
        final result = await provider.validateSession();

        // Assert
        expect(result, true);
        expect(provider.isAuthenticated, true);
        expect(provider.error, null);
      });

      test('should handle invalid session', () async {
        // Arrange
        // Set up authenticated state first
        when(mockAuthService.createSession(any))
            .thenAnswer((_) async => const Success(testSessionId));
        when(mockAuthService.getAccountDetails())
            .thenAnswer((_) async => Success(testAccountData));
        
        await provider.completeAuthentication(testRequestToken);
        
        when(mockAuthService.validateSession()).thenAnswer((_) async => const Success(false));

        // Act
        final result = await provider.validateSession();

        // Assert
        expect(result, false);
        expect(provider.isAuthenticated, false);
        expect(provider.sessionId, null);
      });

      test('should return false for unauthenticated user', () async {
        // Act
        final result = await provider.validateSession();

        // Assert
        expect(result, false);
        verifyNever(mockAuthService.validateSession());
      });

      test('should handle validation failure', () async {
        // Arrange
        // Set up authenticated state first
        when(mockAuthService.createSession(any))
            .thenAnswer((_) async => const Success(testSessionId));
        when(mockAuthService.getAccountDetails())
            .thenAnswer((_) async => Success(testAccountData));
        
        await provider.completeAuthentication(testRequestToken);
        
        const failure = NetworkFailure('Network error');
        when(mockAuthService.validateSession()).thenAnswer((_) async => ResultFailure(failure));

        // Act
        final result = await provider.validateSession();

        // Assert
        expect(result, false);
        expect(provider.error, 'Session validation failed: Network error');
      });
    });

    group('Utility Methods', () {
      test('should clear all data', () {
        // Arrange
        // Set up some state
        provider.completeAuthentication(testRequestToken);

        // Act
        provider.clear();

        // Assert
        expect(provider.sessionId, null);
        expect(provider.accountId, null);
        expect(provider.username, null);
        expect(provider.accountName, null);
        expect(provider.isAuthenticated, false);
        expect(provider.requestToken, null);
        expect(provider.error, null);
        expect(provider.isLoading, false);
        expect(provider.isInitialized, false);
      });

      test('should clear error', () {
        // Arrange
        provider.startAuthentication();

        // Act
        provider.clearError();

        // Assert
        expect(provider.error, null);
      });

      test('should refresh authentication state', () async {
        // Arrange
        when(mockAuthService.initialize()).thenAnswer((_) async {});
        when(mockAuthService.isAuthenticated).thenReturn(false);
        when(mockAuthService.getCurrentSessionId()).thenReturn(null);

        // Initialize first
        await provider.initialize();
        
        // Act
        await provider.refresh();

        // Assert
        verify(mockAuthService.initialize()).called(2);
      });
    });
  });
}