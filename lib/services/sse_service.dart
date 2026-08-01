import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

class SseService {
  final String baseUrl = 'https://tenant-api.saajsajja.in';
  StreamSubscription? _subscription;
  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();

  static final SseService _instance = SseService._internal();
  factory SseService() => _instance;
  SseService._internal();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  void startListening(String token) {
    stopListening();
    
    final url = '$baseUrl/api/v1/sse/device-events?token=$token';
    debugPrint('[SSE] Connecting to stream: $url');

    try {
      // Use dynamic to bypass the undefined SSERequestType error in this environment
      // method: 0 corresponds to GET in the package's internal structure
      _subscription = (SSEClient as dynamic).subscribeToSSE(
        method: 0, 
        url: url,
        header: {
          "Accept": "text/event-stream",
          "Cache-Control": "no-cache",
        },
      ).listen(
        (event) {
          // In some versions, 'event' might need to be cast to dynamic to access 'data'
          final String? data = (event as dynamic).data;
          debugPrint('[SSE Event] Data: $data');
          if (data != null && data.isNotEmpty) {
            try {
              final Map<String, dynamic> jsonData = jsonDecode(data);
              _eventController.add(jsonData);
            } catch (e) {
              debugPrint('[SSE Parsing Error] Failed to decode event data: $e');
            }
          }
        },
        onError: (error) {
          debugPrint('[SSE Error] $error');
        },
      );
    } catch (e) {
      debugPrint('[SSE Connection Error] $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('[SSE] Disconnected from device events.');
  }

  void dispose() {
    stopListening();
    _eventController.close();
  }
}
