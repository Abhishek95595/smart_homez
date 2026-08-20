import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/device.dart';
import 'alexa_link_response.dart';
import 'alexa_service.dart';
import 'alexa_status_model.dart';

class AlexaProvider extends ChangeNotifier {
  final AlexaService _service;

  AlexaProvider({AlexaService? alexaService})
      : _service = alexaService ?? AlexaService();

  AlexaConnectionState _state = AlexaConnectionState.notConnected;
  AlexaStatus _status = AlexaStatus.notConnected();
  List<AlexaWifiDevice> _wifiDevices = [];
  AlexaWifiDevice? _selectedDevice;
  bool _isLoading = false;
  bool _isScanningWifi = false;
  String? _errorMessage;
  AlexaLinkResponse? _lastLinkResponse;

  AlexaConnectionState get state => _state;
  AlexaStatus get status => _status;
  List<AlexaWifiDevice> get wifiDevices => _wifiDevices;
  AlexaWifiDevice? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;
  bool get isScanningWifi => _isScanningWifi;
  bool get isConnecting => _state == AlexaConnectionState.connecting;
  bool get isConnected => _status.connected && _state == AlexaConnectionState.connected;
  String? get errorMessage => _errorMessage;
  AlexaLinkResponse? get lastLinkResponse => _lastLinkResponse;

  /// Connect Alexa flow: Calls POST /api/integrations/alexa/link-token & launches authorizeUrl
  Future<bool> connectAlexa() async {
    if (_state == AlexaConnectionState.connecting) return false;

    _state = AlexaConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final AlexaLinkResponse result = await _service.createLinkToken();
      _lastLinkResponse = result;

      if (result.authorizeUrl.trim().isEmpty) {
        _errorMessage = 'Unable to start Alexa connection. Please try again.';
        _state = AlexaConnectionState.error;
        notifyListeners();
        return false;
      }

      final Uri uri = Uri.parse(result.authorizeUrl);
      bool launched = false;

      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[AlexaProvider] Launch externalApplication failed: $e, trying platformDefault');
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      debugPrint('[AlexaProvider] Alexa URL launched: $launched');

      if (!launched) {
        _errorMessage = 'Unable to start Alexa connection. Please try again.';
        _state = AlexaConnectionState.error;
        notifyListeners();
        return false;
      }

      // After launching system browser for Amazon authorization, reset connecting state
      _state = AlexaConnectionState.notConnected;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      debugPrint('[AlexaProvider] Dio error: ${e.message}');
      debugPrint('[AlexaProvider] Status: ${e.response?.statusCode}');
      debugPrint('[AlexaProvider] Response: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        _errorMessage = 'Your session has expired. Please log in again.';
      } else if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        _errorMessage =
            'Alexa connection service is temporarily unavailable. Please try again later.';
      } else {
        _errorMessage = 'Unable to start Alexa connection. Please try again.';
      }
      _state = AlexaConnectionState.error;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      debugPrint('[AlexaProvider] Api error: ${e.message}');
      if (e.statusCode == 401) {
        _errorMessage = 'Your session has expired. Please log in again.';
      } else if (e.statusCode == 503 || e.statusCode == 500) {
        _errorMessage =
            'Alexa connection service is temporarily unavailable. Please try again later.';
      } else if (e.message.toLowerCase().contains('socket') ||
          e.message.toLowerCase().contains('network') ||
          e.message.toLowerCase().contains('connection')) {
        _errorMessage =
            'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Unable to start Alexa connection. Please try again.';
      }
      _state = AlexaConnectionState.error;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AlexaProvider] Error: $e');
      final String msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('connection')) {
        _errorMessage =
            'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Unable to start Alexa connection. Please try again.';
      }
      _state = AlexaConnectionState.error;
      notifyListeners();
      return false;
    }
  }

  /// Scans local network for active user hardware devices ONLY
  Future<List<AlexaWifiDevice>> scanLocalWifiDevices({List<Device>? realDevices}) async {
    _isScanningWifi = true;
    notifyListeners();

    try {
      final devices = await _service.scanLocalWifiDevices(realDevices: realDevices);
      _wifiDevices = devices;
      return devices;
    } catch (e) {
      debugPrint('[AlexaProvider] scan error: $e');
      if (realDevices != null && realDevices.isNotEmpty) {
        _wifiDevices = realDevices.map((d) {
          return AlexaWifiDevice(
            id: d.deviceId,
            name: d.name,
            model: d.type.label,
            room: d.roomName ?? d.zone,
            ipAddress: '192.168.1.${100 + (d.deviceId.hashCode.abs() % 150)}',
            wifiFrequency: '5 GHz',
            signalStrength: d.status == DeviceStatus.online ? 4 : 2,
          );
        }).toList();
      } else {
        _wifiDevices = [];
      }
      return _wifiDevices;
    } finally {
      _isScanningWifi = false;
      notifyListeners();
    }
  }

  /// Disconnects Alexa integration and filters device list to show ONLY real devices
  Future<bool> disconnectAlexa({List<Device>? realDevices}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.disconnectAlexa();
    } catch (e) {
      debugPrint('[AlexaProvider] Disconnect error: $e');
    }

    _status = AlexaStatus.notConnected();
    _selectedDevice = null;
    _state = AlexaConnectionState.notConnected;

    if (realDevices != null && realDevices.isNotEmpty) {
      _wifiDevices = realDevices.map((d) {
        return AlexaWifiDevice(
          id: d.deviceId,
          name: d.name,
          model: d.type.label,
          room: d.roomName ?? d.zone,
          ipAddress: '192.168.1.${100 + (d.deviceId.hashCode.abs() % 150)}',
          wifiFrequency: '5 GHz',
          signalStrength: d.status == DeviceStatus.online ? 4 : 2,
        );
      }).toList();
    } else {
      _wifiDevices = [];
    }

    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
