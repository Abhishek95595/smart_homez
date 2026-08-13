import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../models/device_model.dart';

class DeviceService {
  DeviceService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// GET /api/v1/clients/{clientId}/devices
  Future<List<DeviceModel>> getDevices(
    String clientId, {
    String? homeId,
    String? roomId,
  }) async {
    final String cleanClientId = clientId.trim();

    if (cleanClientId.isEmpty) {
      throw const FormatException('Client ID is missing.');
    }

    try {
      final Map<String, dynamic> queryParameters = <String, dynamic>{};

      if (homeId != null && homeId.trim().isNotEmpty) {
        queryParameters['homeId'] = homeId.trim();
      }

      if (roomId != null && roomId.trim().isNotEmpty) {
        queryParameters['roomId'] = roomId.trim();
      }

      final Response<dynamic> response = await _api.get(
        ApiEndpoints.clientDevices(cleanClientId),
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      debugPrint('[DeviceService] GET devices status: ${response.statusCode}');

      return _parseDevices(response.data);
    } on ApiException catch (error) {
      debugPrint(
        '[DeviceService] GET devices API error '
        '${error.statusCode}: ${error.message}',
      );
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[DeviceService] GET devices error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sends a command to a device.
  ///
  /// First tries:
  /// POST /api/v1/clients/{clientId}/devices/{deviceId}/command
  ///
  /// If that returns 404, it falls back to:
  /// POST /api/v1/devices/{deviceId}/command
  Future<bool> sendCommand(
    String clientId,
    String deviceId,
    String command, [
    dynamic value,
  ]) async {
    final String cleanClientId = clientId.trim();
    final String cleanDeviceId = deviceId.trim();
    final String cleanCommand = command.trim().toLowerCase();

    if (cleanClientId.isEmpty ||
        cleanDeviceId.isEmpty ||
        cleanCommand.isEmpty) {
      debugPrint(
        '[DeviceService] Command rejected because required values are empty.',
      );
      return false;
    }

    final Map<String, dynamic> requestBody = <String, dynamic>{
      'command': cleanCommand,
      'value': value,
    };

    final String clientScopedEndpoint = ApiEndpoints.deviceCommand(
      cleanClientId,
      cleanDeviceId,
    );

    try {
      return await _postCommand(
        endpoint: clientScopedEndpoint,
        deviceId: cleanDeviceId,
        requestBody: requestBody,
      );
    } on ApiException catch (error) {
      if (error.statusCode != 404) {
        debugPrint(
          '[DeviceService] Client-scoped command failed with status '
          '${error.statusCode}: ${error.message}',
        );
        return false;
      }

      debugPrint(
        '[DeviceService] Client-scoped endpoint returned 404. '
        'Trying global device command endpoint.',
      );

      final String globalEndpoint = ApiEndpoints.globalDeviceCommand(
        cleanDeviceId,
      );

      try {
        return await _postCommand(
          endpoint: globalEndpoint,
          deviceId: cleanDeviceId,
          requestBody: requestBody,
        );
      } on ApiException catch (fallbackError) {
        debugPrint(
          '[DeviceService] Global command failed with status '
          '${fallbackError.statusCode}: '
          '${fallbackError.message}',
        );

        debugPrint(
          '[DeviceService] Global response data: '
          '${fallbackError.data}',
        );

        return false;
      } catch (fallbackError, stackTrace) {
        debugPrint('[DeviceService] Global command error: $fallbackError');
        debugPrintStack(stackTrace: stackTrace);
        return false;
      }
    } catch (error, stackTrace) {
      debugPrint('[DeviceService] Device command error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> _postCommand({
    required String endpoint,
    required String deviceId,
    required Map<String, dynamic> requestBody,
  }) async {
    debugPrint('========== DEVICE COMMAND ==========');
    debugPrint('Endpoint : $endpoint');
    debugPrint('Device ID: $deviceId');
    debugPrint('Body     : $requestBody');

    final Response<dynamic> response = await _api.post(
      endpoint,
      data: requestBody,
    );

    final int statusCode = response.statusCode ?? 0;

    debugPrint('Status   : $statusCode');
    debugPrint('Response : ${response.data}');
    debugPrint('====================================');

    if (statusCode < 200 || statusCode >= 300) {
      return false;
    }

    final dynamic responseData = response.data;

    if (responseData is Map) {
      final Map<String, dynamic> body = Map<String, dynamic>.from(responseData);

      if (body['success'] == false) {
        debugPrint(
          '[DeviceService] Command rejected: '
          '${_extractErrorMessage(body['error'])}',
        );
        return false;
      }
    }

    return true;
  }

  Future<bool> turnOn(String clientId, String deviceId) {
    return sendCommand(clientId, deviceId, 'on', null);
  }

  Future<bool> turnOff(String clientId, String deviceId) {
    return sendCommand(clientId, deviceId, 'off', null);
  }

  Future<bool> toggle(String clientId, String deviceId) {
    return sendCommand(clientId, deviceId, 'toggle', null);
  }

  Future<bool> setBrightness(String clientId, String deviceId, int brightness) {
    final int safeBrightness = brightness.clamp(0, 100);

    return sendCommand(clientId, deviceId, 'brightness', safeBrightness);
  }

  Future<bool> setFanSpeed(String clientId, String deviceId, int speed) {
    if (speed < 1) {
      throw ArgumentError.value(
        speed,
        'speed',
        'Fan speed must be at least 1.',
      );
    }

    return sendCommand(clientId, deviceId, 'speed', speed);
  }

  Future<bool> setTemperature(
    String clientId,
    String deviceId,
    num temperature,
  ) {
    return sendCommand(clientId, deviceId, 'temperature', temperature);
  }

  Future<bool> setColor(String clientId, String deviceId, String color) {
    return sendCommand(clientId, deviceId, 'color', color.trim());
  }

  List<DeviceModel> _parseDevices(dynamic responseData) {
    dynamic items = responseData;

    if (responseData is Map) {
      final Map<String, dynamic> body = Map<String, dynamic>.from(responseData);

      if (body['success'] == false) {
        throw Exception(
          _extractErrorMessage(
            body['error'],
            fallback: 'Unable to load devices.',
          ),
        );
      }

      items = body['data'];
    }

    if (items is! List) {
      return <DeviceModel>[];
    }

    return items
        .whereType<Map>()
        .map((item) => DeviceModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  String _extractErrorMessage(
    dynamic error, {
    String fallback = 'Request failed.',
  }) {
    if (error is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(error);

      return map['message']?.toString() ?? map['code']?.toString() ?? fallback;
    }

    final String message = error?.toString().trim() ?? '';

    return message.isEmpty ? fallback : message;
  }
}
