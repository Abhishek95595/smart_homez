import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SseService {
  SseService._internal();

  static final SseService _instance = SseService._internal();

  factory SseService() {
    return _instance;
  }

  static const String _baseUrl = 'https://tenant-api.saajsajja.in';

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  http.Client? _client;
  StreamSubscription<String>? _streamSubscription;
  Timer? _reconnectTimer;

  bool _shouldReconnect = true;
  bool _reconnectScheduled = false;
  bool _isConnecting = false;

  int _retryCount = 0;
  String? _activeToken;

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  bool get isListening => _client != null || _streamSubscription != null;

  /// Starts listening to device events.
  ///
  /// Calling this method again safely replaces the existing connection.
  void startListening(String token) {
    final String cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      debugPrint('[SSE] Connection not started because token is empty.');
      return;
    }

    _activeToken = cleanToken;
    _shouldReconnect = true;
    _retryCount = 0;
    _reconnectScheduled = false;

    unawaited(_connect(cleanToken));
  }

  Future<void> _connect(String token) async {
    if (!_shouldReconnect || _isConnecting) {
      return;
    }

    _isConnecting = true;

    await _closeCurrentConnection(cancelReconnectTimer: false);

    if (!_shouldReconnect) {
      _isConnecting = false;
      return;
    }

    final Uri url = Uri.parse(
      '$_baseUrl/api/v1/sse/device-events'
      '?token=${Uri.encodeQueryComponent(token)}',
    );

    debugPrint(
      '[SSE] Connecting to stream: '
      '$_baseUrl... (Token Hidden)',
    );

    try {
      final http.Client client = http.Client();
      _client = client;

      final http.Request request = http.Request('GET', url);

      request.headers.addAll(const <String, String>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      });

      final http.StreamedResponse response = await client.send(request);

      if (!_shouldReconnect) {
        client.close();
        _client = null;
        return;
      }

      if (response.statusCode != 200) {
        debugPrint(
          '[SSE Error] Connection failed with status: '
          '${response.statusCode}',
        );

        await response.stream.drain<void>();
        _handleReconnect(token);
        return;
      }

      _retryCount = 0;
      _reconnectScheduled = false;

      debugPrint('[SSE] Stream connected successfully.');

      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('[SSE Error] Stream error: $error');
              debugPrintStack(stackTrace: stackTrace);
              _handleReconnect(token);
            },
            onDone: () {
              debugPrint('[SSE] Stream closed by server.');
              _handleReconnect(token);
            },
            cancelOnError: true,
          );
    } catch (error, stackTrace) {
      debugPrint('[SSE Connection Error] $error');
      debugPrintStack(stackTrace: stackTrace);
      _handleReconnect(token);
    } finally {
      _isConnecting = false;
    }
  }

  void _handleLine(String line) {
    final String trimmedLine = line.trim();

    if (trimmedLine.isEmpty ||
        trimmedLine.startsWith(':') ||
        !trimmedLine.startsWith('data:')) {
      return;
    }

    final String data = trimmedLine.substring('data:'.length).trim();

    if (data.isEmpty) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(data);
      _emitDecodedEvent(decoded);
    } on FormatException catch (error) {
      debugPrint('[SSE Error] Invalid JSON received: $error');
      debugPrint('[SSE Error] Raw data: $data');
    } catch (error, stackTrace) {
      debugPrint('[SSE Error] Parsing JSON failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _emitDecodedEvent(dynamic decoded) {
    if (decoded is Map) {
      _addEvent(Map<String, dynamic>.from(decoded));
      return;
    }

    if (decoded is List) {
      for (final dynamic item in decoded) {
        if (item is Map) {
          _addEvent(Map<String, dynamic>.from(item));
        } else {
          debugPrint(
            '[SSE] Ignored non-object item in event list: '
            '${item.runtimeType}',
          );
        }
      }

      return;
    }

    debugPrint(
      '[SSE] Ignored unsupported event payload type: '
      '${decoded.runtimeType}',
    );
  }

  void _addEvent(Map<String, dynamic> event) {
    if (_eventController.isClosed) {
      return;
    }

    _eventController.add(event);
  }

  void _handleReconnect(String token) {
    if (!_shouldReconnect || _reconnectScheduled) {
      return;
    }

    _reconnectScheduled = true;

    final int delaySeconds = (_retryCount == 0 ? 2 : _retryCount * 2).clamp(
      2,
      30,
    );

    _retryCount++;

    debugPrint('[SSE] Reconnecting in $delaySeconds seconds...');

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectScheduled = false;

      if (_shouldReconnect) {
        unawaited(_connect(token));
      }
    });
  }

  Future<void> stopListening({bool reconnect = false}) async {
    if (!reconnect) {
      _shouldReconnect = false;
      _activeToken = null;
    }

    _reconnectScheduled = false;

    await _closeCurrentConnection(cancelReconnectTimer: true);

    debugPrint('[SSE] Connection terminated.');
  }

  Future<void> _closeCurrentConnection({
    required bool cancelReconnectTimer,
  }) async {
    if (cancelReconnectTimer) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }

    await _streamSubscription?.cancel();
    _streamSubscription = null;

    _client?.close();
    _client = null;
  }

  Future<void> reconnect() async {
    final String? token = _activeToken;

    if (token == null || token.isEmpty) {
      debugPrint('[SSE] Reconnect skipped because no active token exists.');
      return;
    }

    _shouldReconnect = true;
    _retryCount = 0;
    _reconnectScheduled = false;

    await _connect(token);
  }

  Future<void> dispose() async {
    await stopListening();

    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }
}
