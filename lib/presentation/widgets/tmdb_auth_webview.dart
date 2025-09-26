import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/auth_provider.dart';

/// WebView widget for TMDb authentication flow
class TMDbAuthWebView extends StatefulWidget {
  final String requestToken;
  final AuthProvider authProvider;

  const TMDbAuthWebView({
    super.key,
    required this.requestToken,
    required this.authProvider,
  });

  @override
  State<TMDbAuthWebView> createState() => _TMDbAuthWebViewState();
}

class _TMDbAuthWebViewState extends State<TMDbAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final authUrl = widget.authProvider.getAuthenticationUrl(widget.requestToken);
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Check if user has approved the token
            if (url.contains('allow') || url.contains('approved')) {
              _completeAuthentication();
            } else if (url.contains('deny') || url.contains('denied')) {
              _handleAuthenticationDenied();
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation for TMDb authentication
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));
  }

  Future<void> _completeAuthentication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.authProvider.completeAuthentication(widget.requestToken);
      if (mounted) {
        Navigator.of(context).pop(success);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to complete authentication: $e';
      });
    }
  }

  void _handleAuthenticationDenied() {
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TMDb Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (_hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retry,
              tooltip: 'Retry',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError)
            WebViewWidget(controller: _controller)
          else
            _buildErrorView(),
          
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading TMDb authentication...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Authentication Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load authentication page',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}