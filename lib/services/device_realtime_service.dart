import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device_model.dart';
import 'device_service.dart';

/// Polling-based real-time synchronization.
///
/// The backend SSE event schema has not yet been confirmed, so this service
/// reliably refreshes devices from the API at a short interval. It updates
/// the app when a device is changed from Tinxy, another app, or a wall switch.
class RealtimeService {
  RealtimeService._internal();

  static final RealtimeService instance = RealtimeService._internal();

  final DeviceService _deviceService = DeviceService();

  final StreamController<List<DeviceModel>> _deviceController =
      StreamController<List<DeviceModel>>.broadcast();

  Timer? _refreshTimer;
  String? _clientId;

  bool _requestInProgress = false;
  bool _isRunning = false;

  int _consecutiveErrors = 0;

  Stream<List<DeviceModel>> get deviceStream => _deviceController.stream;

  bool get isRunning => _isRunning;

  Future<void> start({
    required String clientId,
    Duration refreshInterval = const Duration(milliseconds: 500),
  }) async {
    final String cleanClientId = clientId.trim();

    if (cleanClientId.isEmpty) {
      debugPrint(
        '[RealtimeService] Cannot start: '
        'client ID is empty.',
      );
      return;
    }

    _clientId = cleanClientId;
    _isRunning = true;
    _consecutiveErrors = 0;

    _refreshTimer?.cancel();

    await refreshNow();

    _refreshTimer = Timer.periodic(refreshInterval, (_) => refreshNow());

    debugPrint(
      '[RealtimeService] Started polling every '
      '${refreshInterval.inSeconds}s.',
    );
  }

  Future<void> refreshNow() async {
    final String? clientId = _clientId;

    if (!_isRunning ||
        clientId == null ||
        clientId.isEmpty ||
        _requestInProgress) {
      return;
    }

    _requestInProgress = true;

    try {
      final List<DeviceModel> devices = await _deviceService.getDevices(
        clientId,
      );

      _consecutiveErrors = 0;

      if (!_deviceController.isClosed) {
        _deviceController.add(devices);
      }

      debugPrint(
        '[RealtimeService] Refreshed '
        '${devices.length} devices.',
      );
    } catch (error) {
      _consecutiveErrors++;
      debugPrint(
        '[RealtimeService] Refresh notice ($_consecutiveErrors): $error',
      );

      if (_consecutiveErrors >= 3) {
        debugPrint(
          '[RealtimeService] Pausing polling due to API access permissions.',
        );
        stop();
      }
    } finally {
      _requestInProgress = false;
    }
  }

  void stop() {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    _isRunning = false;
    _clientId = null;
    _requestInProgress = false;

    debugPrint('[RealtimeService] Stopped.');
  }

  Future<void> dispose() async {
    stop();

    if (!_deviceController.isClosed) {
      await _deviceController.close();
    }
  }
}
