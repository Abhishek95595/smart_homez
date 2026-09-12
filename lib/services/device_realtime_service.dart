import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device_model.dart';
import 'device_service.dart';

/// Polling-based real-time synchronization.
///
/// Refreshes devices from the API at a safe 10-second interval. It updates
/// the app when a device state is changed externally.
class RealtimeService {
  RealtimeService._internal();

  static final RealtimeService instance = RealtimeService._internal();

  final DeviceService _deviceService = DeviceService();

  final StreamController<List<DeviceModel>> _deviceController =
      StreamController<List<DeviceModel>>.broadcast();

  Timer? _refreshTimer;
  String? _clientId;

  bool _isRefreshing = false;
  bool _isRunning = false;

  int _consecutiveErrors = 0;

  Stream<List<DeviceModel>> get deviceStream => _deviceController.stream;

  bool get isRunning => _isRunning;

  Future<void> start({
    required String clientId,
    Duration refreshInterval = const Duration(seconds: 10),
  }) async {
    final String cleanClientId = clientId.trim();

    if (cleanClientId.isEmpty) {
      debugPrint('[RealtimeService] Cannot start: client ID is empty.');
      return;
    }

    // Prevent duplicate timers if already running with the exact same client ID
    if (_isRunning &&
        _clientId == cleanClientId &&
        _refreshTimer != null &&
        _refreshTimer!.isActive) {
      debugPrint(
        '[RealtimeService] Already running with active timer for client: $cleanClientId',
      );
      return;
    }

    _refreshTimer?.cancel();
    _refreshTimer = null;

    _clientId = cleanClientId;
    _isRunning = true;
    _consecutiveErrors = 0;

    // Initial safe refresh
    await refreshNow();

    if (!_isRunning || _clientId != cleanClientId) {
      return;
    }

    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      if (_isRunning && _clientId == cleanClientId) {
        refreshNow();
      }
    });

    debugPrint(
      '[RealtimeService] Started with ${refreshInterval.inSeconds}s interval',
    );
  }

  Future<void> refreshNow() async {
    final String? clientId = _clientId;

    if (!_isRunning || clientId == null || clientId.isEmpty) {
      return;
    }

    if (_isRefreshing) {
      debugPrint(
        '[RealtimeService] Refresh skipped: previous request still running',
      );
      return;
    }

    _isRefreshing = true;

    try {
      final List<DeviceModel> devices = await _deviceService.getDevices(
        clientId,
      );

      _consecutiveErrors = 0;

      if (!_deviceController.isClosed) {
        _deviceController.add(devices);
      }

      debugPrint('[RealtimeService] Refreshed ${devices.length} devices.');
    } catch (error) {
      _consecutiveErrors++;
      debugPrint(
        '[RealtimeService] Refresh notice ($_consecutiveErrors): $error',
      );

      if (_consecutiveErrors >= 3) {
        debugPrint(
          '[RealtimeService] Pausing polling due to repeated errors or rate limits.',
        );
        stop();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void stop() {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    _isRunning = false;
    _clientId = null;
    _isRefreshing = false;

    debugPrint('[RealtimeService] Stopped.');
  }

  Future<void> dispose() async {
    stop();

    if (!_deviceController.isClosed) {
      await _deviceController.close();
    }
  }
}
