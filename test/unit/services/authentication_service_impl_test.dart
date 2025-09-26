import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:movie_recommendation_app/core/error/exceptions.dart';
import 'package:movie_recommendation_app/core/error/failures.dart';
import 'package:movie_recommendation_app/core/utils/result.dart';
import 'package:movie_recommendation_app/data/datasources/tmdb_client.dart';
import 'package:movie_recommendation_app/data/services/authentication_service_impl.dart';

import 'authentication_service_impl_test.mocks.dart';

@GenerateMocks([TMDbClient])
void main() {
  late AuthenticationServiceImpl authService;
  late MockTMDbClient mockTMDbClient;

  setUp(() {
    mockTMDbClient = MockTMDbClient();
    authService = AuthenticationServiceImpl(tmdbClient: mockTMDbClient);
  });

  group('AuthenticationServiceImpl', () {
    group('createRequestToken', () {
      test('should return Success with token when TMDb client succeeds', () async {
        // Arrange
        const expectedToken = 'test_request_token';
        when(mockTMDbClient.createRequestToken()).thenAnswer((_) async => expectedToken);

        // Act
        final result = await authService.createRequestToken();

        // Assert
        expect(result, isA<Success<String>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (token) => expect(token, expectedToken),
        );
        verify(mockTMDbClient.createRequestToken()).called(1);
      });

      test('should return AuthenticationFailure when AuthenticationException is thrown', () async {
        // Arrange
        when(mockTMDbClient.createRequestToken())
            .thenThrow(const AuthenticationException('Failed to create token'));

        // Act
        final result = await authService.createRequestToken();

        // Assert
        expect(result, isA<ResultFailure<String>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthenticationFailure>());
            expect(failure.message, 'Failed to create token');
          },
          (token) => fail('Expected failure but got success'),
        );
      });

      test('should return NetworkFailure when NetworkException is thrown', () async {
        // Arrange
        when(mockTMDbClient.createRequestToken())
            .thenThrow(const NetworkException('No internet connection'));

        // Act
        final result = await authService.createRequestToken();

        // Assert
        expect(result, isA<ResultFailure<String>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'No internet connection');
          },
          (token) => fail('Expected failure but got success'),
        );
      });
    });

    group('createSession', () {
      test('should return Success with session ID and set account details when successful', () async {
        // Arrange
        const approvedToken = 'approved_token';
        const expectedSessionId = 'test_session_id';
        const accountDetails = {
          'id': 123,
          'username': 'testuser',
          'name': 'Test User',
        };

        when(mockTMDbClient.createSession(approvedToken))
            .thenAnswer((_) async => expectedSessionId);
        when(mockTMDbClient.getAccountDetails(expectedSessionId))
            .thenAnswer((_) async => accountDetails);

        // Act
        final result = await authService.createSession(approvedToken);

        // Assert
        expect(result, isA<Success<String>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (sessionId) => expect(sessionId, expectedSessionId),
        );
        
        expect(authService.getCurrentSessionId(), expectedSessionId);
        expect(authService.getCurrentAccountId(), 123);
        expect(authService.isAuthenticated, true);
        
        verify(mockTMDbClient.createSession(approvedToken)).called(1);
        verify(mockTMDbClient.getAccountDetails(expectedSessionId)).called(1);
      });

      test('should return AuthenticationFailure when session creation fails', () async {
        // Arrange
        const approvedToken = 'approved_token';
        when(mockTMDbClient.createSession(approvedToken))
            .thenThrow(const AuthenticationException('Invalid token'));

        // Act
        final result = await authService.createSession(approvedToken);

        // Assert
        expect(result, isA<ResultFailure<String>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthenticationFailure>());
            expect(failure.message, 'Invalid token');
          },
          (sessionId) => fail('Expected failure but got success'),
        );
        
        expect(authService.isAuthenticated, false);
      });

      test('should handle account details failure gracefully', () async {
        // Arrange
        const approvedToken = 'approved_token';
        const expectedSessionId = 'test_session_id';

        when(mockTMDbClient.createSession(approvedToken))
            .thenAnswer((_) async => expectedSessionId);
        when(mockTMDbClient.getAccountDetails(expectedSessionId))
            .thenThrow(const ApiException('Failed to get account details'));

        // Act
        final result = await authService.createSession(approvedToken);

        // Assert
        expect(result, isA<ResultFailure<String>>());
        result.fold(
          (failure) {
            expect(failure, isA<ApiFailure>());
            expect(failure.message, 'Failed to get account details');
          },
          (sessionId) => fail('Expected failure but got success'),
        );
      });
    });

    group('validateSession', () {
      test('should return AuthenticationFailure when no active session', () async {
        // Act
        final result = await authService.validateSession();

        // Assert
        expect(result, isA<ResultFailure<bool>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthenticationFailure>());
            expect(failure.message, 'No active session');
          },
          (isValid) => fail('Expected failure but got success'),
        );
      });

      test('should return Success when session is valid', () async {
        // Arrange
        const sessionId = 'valid_session';
        const accountId = 123;
        const accountDetails = {'id': accountId, 'username': 'testuser'};
        
        authService.setSessionDetails(sessionId: sessionId, accountId: accountId);
        when(mockTMDbClient.getAccountDetails(sessionId))
            .thenAnswer((_) async => accountDetails);

        // Act
        final result = await authService.validateSession();

        // Assert
        expect(result, isA<Success<bool>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (isValid) => expect(isValid, true),
        );
        verify(mockTMDbClient.getAccountDetails(sessionId)).called(1);
      });

      test('should clear session when validation fails', () async {
        // Arrange
        const sessionId = 'invalid_session';
        const accountId = 123;
        
        authService.setSessionDetails(sessionId: sessionId, accountId: accountId);
        when(mockTMDbClient.getAccountDetails(sessionId))
            .thenThrow(const AuthenticationException('Invalid session'));

        // Act
        final result = await authService.validateSession();

        // Assert
        expect(result, isA<ResultFailure<bool>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthenticationFailure>());
            expect(failure.message, 'Invalid session');
          },
          (isValid) => fail('Expected failure but got success'),
        );
        
        expect(authService.getCurrentSessionId(), null);
        expect(authService.getCurrentAccountId(), null);
        expect(authService.isAuthenticated, false);
      });
    });

    group('logout', () {
      test('should clear session data and cache', () async {
        // Arrange
        const sessionId = 'test_session';
        const accountId = 123;
        authService.setSessionDetails(sessionId: sessionId, accountId: accountId);
        
        expect(authService.isAuthenticated, true);

        // Act
        final result = await authService.logout();

        // Assert
        expect(result, isA<Success<void>>());
        expect(authService.getCurrentSessionId(), null);
        expect(authService.getCurrentAccountId(), null);
        expect(authService.isAuthenticated, false);
        
        verify(mockTMDbClient.clearCache()).called(1);
      });
    });

    group('getAuthenticationUrl', () {
      test('should return correct TMDb authentication URL', () {
        // Arrange
        const requestToken = 'test_token';
        const expectedUrl = 'https://www.themoviedb.org/authenticate/test_token';

        // Act
        final url = authService.getAuthenticationUrl(requestToken);

        // Assert
        expect(url, expectedUrl);
      });
    });

    group('getAccountDetails', () {
      test('should return AuthenticationFailure when no active session', () async {
        // Act
        final result = await authService.getAccountDetails();

        // Assert
        expect(result, isA<ResultFailure<Map<String, dynamic>>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthenticationFailure>());
            expect(failure.message, 'No active session');
          },
          (details) => fail('Expected failure but got success'),
        );
      });

      test('should return Success with account details when session is valid', () async {
        // Arrange
        const sessionId = 'valid_session';
        const accountId = 123;
        const accountDetails = {
          'id': accountId,
          'username': 'testuser',
          'name': 'Test User',
        };
        
        authService.setSessionDetails(sessionId: sessionId, accountId: accountId);
        when(mockTMDbClient.getAccountDetails(sessionId))
            .thenAnswer((_) async => accountDetails);

        // Act
        final result = await authService.getAccountDetails();

        // Assert
        expect(result, isA<Success<Map<String, dynamic>>>());
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (details) {
            expect(details, accountDetails);
            expect(details['id'], accountId);
            expect(details['username'], 'testuser');
          },
        );
        verify(mockTMDbClient.getAccountDetails(sessionId)).called(1);
      });
    });

    group('setSessionDetails', () {
      test('should set session and account details correctly', () {
        // Arrange
        const sessionId = 'test_session';
        const accountId = 456;

        // Act
        authService.setSessionDetails(sessionId: sessionId, accountId: accountId);

        // Assert
        expect(authService.getCurrentSessionId(), sessionId);
        expect(authService.getCurrentAccountId(), accountId);
        expect(authService.isAuthenticated, true);
      });

      test('should handle null values correctly', () {
        // Arrange
        authService.setSessionDetails(sessionId: 'test', accountId: 123);
        expect(authService.isAuthenticated, true);

        // Act
        authService.setSessionDetails(sessionId: null, accountId: null);

        // Assert
        expect(authService.getCurrentSessionId(), null);
        expect(authService.getCurrentAccountId(), null);
        expect(authService.isAuthenticated, false);
      });
    });

    group('isAuthenticated', () {
      test('should return false when no session or account ID', () {
        // Assert
        expect(authService.isAuthenticated, false);
      });

      test('should return false when only session ID is set', () {
        // Act
        authService.setSessionDetails(sessionId: 'test_session', accountId: null);

        // Assert
        expect(authService.isAuthenticated, false);
      });

      test('should return false when only account ID is set', () {
        // Act
        authService.setSessionDetails(sessionId: null, accountId: 123);

        // Assert
        expect(authService.isAuthenticated, false);
      });

      test('should return true when both session ID and account ID are set', () {
        // Act
        authService.setSessionDetails(sessionId: 'test_session', accountId: 123);

        // Assert
        expect(authService.isAuthenticated, true);
      });
    });
  });
}