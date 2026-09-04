import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Full-screen in-app WebView that loads the Alexa OAuth authorize URL.
///
/// When the WebView detects a navigation to the app's custom-scheme redirect
/// URI (e.g. `hasomi.com.homeautomation://alexa-callback`), it intercepts the
/// redirect, closes itself, and returns the callback URI to the caller.
class AlexaWebViewScreen extends StatefulWidget {
  final Uri authorizeUri;
  final String? bearerToken;
  final String redirectScheme;

  const AlexaWebViewScreen({
    super.key,
    required this.authorizeUri,
    this.bearerToken,
    this.redirectScheme = 'hasomi.com.homeautomation',
  });

  @override
  State<AlexaWebViewScreen> createState() => _AlexaWebViewScreenState();
}

class _AlexaWebViewScreenState extends State<AlexaWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  // Chrome-like user agent to prevent server-side WebView blocking
  static const String _chromeUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0.6478.122 Mobile Safari/537.36';

  String? _lastUrl;

  @override
  void initState() {
    super.initState();

    final Uri effectiveUri =
        (widget.authorizeUri.host == 'tenant-api-qa.omnihome.in' ||
            widget.authorizeUri.host == 'tenant-api.omnihome.in')
        ? widget.authorizeUri.replace(host: 'omnihome.in')
        : widget.authorizeUri;

    _lastUrl = effectiveUri.toString();

    final bool hasToken =
        widget.bearerToken != null && widget.bearerToken!.isNotEmpty;
    debugPrint('[AlexaWebView] Platform JWT available: $hasToken');
    debugPrint('[AlexaWebView] Bearer token available: $hasToken');

    final Map<String, String> requestHeaders = {
      if (hasToken) 'Authorization': 'Bearer ${widget.bearerToken}',
    };

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_chromeUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url;
            _lastUrl = url;
            final bool isInitial = url == effectiveUri.toString();
            debugPrint(
              '[AlexaWebView] Navigation Request: url=$url (Is initial request: $isInitial)',
            );

            final uri = Uri.tryParse(url);
            final String scheme = uri?.scheme.toLowerCase() ?? '';
            final String host = uri?.host.toLowerCase() ?? '';
            final String path = uri?.path.toLowerCase() ?? '';
            final String lowerUrl = url.toLowerCase();

            final bool isCustomScheme =
                scheme.isNotEmpty &&
                scheme != 'http' &&
                scheme != 'https' &&
                scheme != 'about' &&
                scheme != 'data' &&
                scheme != 'javascript';

            final bool isCallback =
                scheme == widget.redirectScheme.toLowerCase() ||
                scheme == 'hasomi.com.homeautomation' ||
                scheme == 'omnihome.in.homeautomation' ||
                scheme == 'app1' ||
                host == 'alexa-callback' ||
                path.contains('alexa-callback') ||
                host == 'alexa-link' ||
                path.contains('alexa-link') ||
                lowerUrl.contains('alexa-callback') ||
                lowerUrl.contains('alexa-link') ||
                lowerUrl.contains('omnihome.in.homeautomation') ||
                lowerUrl.contains('hasomi.com.homeautomation');

            if (isCustomScheme || isCallback) {
              debugPrint(
                '[AlexaWebView] Intercepted callback / custom scheme: $url',
              );
              if (mounted) {
                Navigator.pop(context, uri ?? Uri.parse(url));
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            _lastUrl = url;
            final bool isInitial = url == effectiveUri.toString();
            debugPrint(
              '[AlexaWebView] Page Load Started: url=$url (Is initial request: $isInitial)',
            );
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            _lastUrl = url;
            final bool isInitial = url == effectiveUri.toString();
            debugPrint(
              '[AlexaWebView] Page Load Finished: url=$url (Is initial request: $isInitial)',
            );
            if (mounted) {
              setState(() {
                _isLoading = false;
                // Clear error if main page loads successfully
                if (isInitial) _errorMessage = null;
              });
            }
          },
          onHttpError: (HttpResponseError error) {
            final int? statusCode = error.response?.statusCode;
            final String url =
                error.request?.uri.toString() ?? _lastUrl ?? 'unknown';
            final bool isInitial = url == effectiveUri.toString();
            debugPrint(
              '[AlexaWebView] HTTP Error: code=$statusCode, url=$url (Is initial request: $isInitial)',
            );

            if (mounted) {
              setState(() {
                _isLoading = false;
                if (statusCode == 400) {
                  _errorMessage =
                      'Bad Request (400) from authorization server.';
                } else if (statusCode == 401) {
                  _errorMessage = 'Session Expired or Unauthorized (401).';
                } else if (statusCode == 403) {
                  _errorMessage = 'Access Denied / Forbidden (403).';
                } else if (statusCode != null && statusCode >= 500) {
                  _errorMessage =
                      'Server Error ($statusCode) from authorization server.';
                } else {
                  _errorMessage =
                      'HTTP Error $statusCode from authorization server.';
                }
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            final String url = _lastUrl ?? 'unknown';
            final bool isInitial = url == effectiveUri.toString();
            debugPrint(
              '[AlexaWebView] Web Resource Error: code=${error.errorCode}, description=${error.description}, url=$url (Is initial request: $isInitial)',
            );

            final uri = Uri.tryParse(url);
            final String scheme = uri?.scheme.toLowerCase() ?? '';
            final String host = uri?.host.toLowerCase() ?? '';
            final String path = uri?.path.toLowerCase() ?? '';
            final String lowerUrl = url.toLowerCase();

            final bool isCallback =
                scheme == widget.redirectScheme.toLowerCase() ||
                scheme == 'hasomi.com.homeautomation' ||
                scheme == 'omnihome.in.homeautomation' ||
                scheme == 'app1' ||
                host == 'alexa-callback' ||
                path.contains('alexa-callback') ||
                host == 'alexa-link' ||
                path.contains('alexa-link') ||
                lowerUrl.contains('alexa-callback') ||
                lowerUrl.contains('alexa-link') ||
                lowerUrl.contains('omnihome.in.homeautomation') ||
                lowerUrl.contains('hasomi.com.homeautomation');

            if (isCallback) {
              debugPrint(
                '[AlexaWebView] Rescued callback from WebResourceError: $url',
              );
              if (mounted) {
                Navigator.pop(context, uri ?? Uri.parse(url));
              }
              return;
            }

            // Only display main frame loading failures
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      'WebView navigation failure (${error.errorCode}): ${error.description}\nURL: $url';
                });
              }
            }
          },
        ),
      )
      ..loadRequest(effectiveUri, headers: requestHeaders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Close',
        ),
        title: const Text(
          'Alexa Authorization',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        final Map<String, String> requestHeaders = {
                          if (widget.bearerToken != null &&
                              widget.bearerToken!.isNotEmpty)
                            'Authorization': 'Bearer ${widget.bearerToken}',
                        };
                        _controller.loadRequest(
                          widget.authorizeUri,
                          headers: requestHeaders,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00897B)),
            ),
        ],
      ),
    );
  }
}
