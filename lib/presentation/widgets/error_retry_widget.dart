import 'package:flutter/material.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';

class ErrorRetryWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;
  final String? customMessage;
  final bool showRetryButton;

  const ErrorRetryWidget({
    super.key,
    required this.failure,
    required this.onRetry,
    this.customMessage,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ?? ErrorHandler.getErrorMessage(failure),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorSubtitle(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && ErrorHandler.isRetryableError(failure)) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return Icons.wifi_off;
      case AuthenticationFailure:
        return Icons.lock_outline;
      case ApiFailure:
        return Icons.cloud_off;
      case DataFailure:
        return Icons.error_outline;
      case CacheFailure:
        return Icons.storage;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorSubtitle() {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'Check your internet connection and try again';
      case AuthenticationFailure:
        return 'Please log in again to continue';
      case ApiFailure:
        return 'Our servers are having issues. Please try again later';
      case DataFailure:
        return 'The data received was invalid';
      case CacheFailure:
        return 'Unable to load saved data';
      default:
        return 'Something unexpected happened';
    }
  }
}

class ErrorSnackBar {
  static void show(BuildContext context, Failure failure, {VoidCallback? onRetry}) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    messenger.hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getErrorIcon(failure),
            color: theme.colorScheme.onError,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ErrorHandler.getErrorMessage(failure),
              style: TextStyle(color: theme.colorScheme.onError),
            ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.error,
      behavior: SnackBarBehavior.floating,
      action: onRetry != null && ErrorHandler.isRetryableError(failure)
          ? SnackBarAction(
              label: 'Retry',
              textColor: theme.colorScheme.onError,
              onPressed: onRetry,
            )
          : null,
      duration: const Duration(seconds: 4),
    );
    
    messenger.showSnackBar(snackBar);
  }

  static IconData _getErrorIcon(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return Icons.wifi_off;
      case AuthenticationFailure:
        return Icons.lock_outline;
      case ApiFailure:
        return Icons.cloud_off;
      case DataFailure:
        return Icons.error_outline;
      case CacheFailure:
        return Icons.storage;
      default:
        return Icons.error_outline;
    }
  }
}