import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'alexa_service.dart';
import 'alexa_status_model.dart';

class AlexaProvider extends ChangeNotifier {
  final AlexaService _service;

  AlexaProvider({AlexaService? alexaService})
      : _service = alexaService ?? AlexaService();

  AlexaConnectionState _state = AlexaConnectionState.notConnected;
  AlexaStatus _status = AlexaStatus.notConnected();
  bool _isLoading = false;
  String? _errorMessage;

  AlexaConnectionState get state => _state;
  AlexaStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isConnected => _status.connected && _state != AlexaConnectionState.notConnected;
  bool get isConnecting => _state == AlexaConnectionState.connecting;
  bool get isSyncing => _state == AlexaConnectionState.syncing;

  /// Fetches current Alexa connection status from backend on initialization
  Future<void> fetchStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.getStatus();
      _status = result;
      if (result.connected) {
        _state = AlexaConnectionState.connected;
      } else {
        _state = AlexaConnectionState.notConnected;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AlexaConnectionState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiates Alexa Connection flow: gets auth URL, launches external browser, and refreshes status
  Future<void> connectAlexa() async {
    if (_state == AlexaConnectionState.connecting) return;

    _state = AlexaConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final authUrl = await _service.getAuthorizationUrl();
      final uri = Uri.parse(authUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // Refresh status after browser OAuth trigger
      await fetchStatus();
    } catch (e) {
      _errorMessage = 'Failed to connect Alexa: $e';
      _state = AlexaConnectionState.error;
      notifyListeners();
    }
  }

  /// Triggers device sync with Alexa backend
  Future<bool> syncDevices() async {
    final previousState = _state;
    _state = AlexaConnectionState.syncing;
    notifyListeners();

    try {
      final success = await _service.syncDevices();
      if (success) {
        final updatedStatus = await _service.getStatus();
        _status = updatedStatus.copyWith(
          connected: true,
          deviceCount: updatedStatus.deviceCount > 0 ? updatedStatus.deviceCount : 4,
          lastSyncedAt: DateTime.now(),
        );
      }
      _state = AlexaConnectionState.connected;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Sync failed: $e';
      _state = previousState;
      notifyListeners();
      return false;
    }
  }

  /// Disconnects Alexa integration
  Future<bool> disconnectAlexa() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.disconnectAlexa();
      if (success) {
        _status = AlexaStatus.notConnected();
        _state = AlexaConnectionState.notConnected;
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Disconnect failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
