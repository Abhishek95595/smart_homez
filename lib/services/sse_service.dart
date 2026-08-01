import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SseService {
  final String baseUrl = 'https://tenant-api.saajsajja.in';
  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();
  
  http.Client? _client;
  bool _shouldReconnect = true;
  int _retryCount = 0;
  Timer? _reconnectTimer;

  static final SseService _instance = SseService._internal();
  factory SseService() => _instance;
  SseService._internal();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  /// Robust implementation using http.Client and manual stream parsing (Phase 11)
  void startListening(String token) {
    _shouldReconnect = true;
    _retryCount = 0;
    _connect(token);
  }

  Future<void> _connect(String token) async {
    if (!_shouldReconnect) return;
    
    stopListening(reconnect: true);
    
    final url = Uri.parse('$baseUrl/api/v1/sse/device-events?token=$token');
    debugPrint('[SSE] Connecting to stream: $baseUrl... (Token Hidden)');

    try {
      _client = http.Client();
      final request = http.Request('GET', url);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        _retryCount = 0; // Reset on success
        debugPrint('[SSE] Stream connected successfully.');
        
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (line.startsWith('data:')) {
              final data = line.substring(5).trim();
              if (data.isNotEmpty) {
                try {
                  final jsonData = jsonDecode(data);
                  _eventController.add(jsonData);
                } catch (e) {
                  debugPrint('[SSE Error] Parsing JSON failed: $e');
                }
              }
            }
          },
          onError: (error) {
            debugPrint('[SSE Error] Stream error: $error');
            _handleReconnect(token);
          },
          onDone: () {
            debugPrint('[SSE] Stream closed by server.');
            _handleReconnect(token);
          },
          cancelOnError: true,
        );
      } else {
        debugPrint('[SSE Error] Connection failed with status: ${response.statusCode}');
        _handleReconnect(token);
      }
    } catch (e) {
      debugPrint('[SSE Connection Error] $e');
      _handleReconnect(token);
    }
  }

  void _handleReconnect(String token) {
    if (!_shouldReconnect) return;
    
    // Exponential backoff
    final delay = Duration(seconds: (_retryCount * 2).clamp(2, 30));
    _retryCount++;
    
    debugPrint('[SSE] Reconnecting in ${delay.inSeconds} seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => _connect(token));
  }

  void stopListening({bool reconnect = false}) {
    if (!reconnect) _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _client?.close();
    _client = null;
    debugPrint('[SSE] Connection terminated.');
  }

  void dispose() {
    stopListening();
    _eventController.close();
  }
}
