import 'package:flutter/material.dart';
import '../../core/network/connectivity_service.dart';

class OfflineIndicator extends StatefulWidget {
  final Widget child;
  final bool showWhenOffline;

  const OfflineIndicator({
    super.key,
    required this.child,
    this.showWhenOffline = true,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    _isOnline = await _connectivityService.isConnected;
    
    _connectivityService.connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isOnline && widget.showWhenOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'You\'re offline. Showing cached content.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            size: 20,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No internet connection',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Showing cached content when available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}