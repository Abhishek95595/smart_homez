import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/network/api_exception.dart';
import '../models/device_model.dart';

class DeviceService {
  DeviceService({dynamic apiClient});

  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      );

  /// GET devices via Firebase Callable Functions.
  Future<List<DeviceModel>> getDevices(
    String clientId, {
    String? homeId,
    String? roomId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(
        message: 'Unauthenticated. Log in with Firebase first.',
        statusCode: 401,
      );
    }

    try {
      final callable = _functions.httpsCallable('getDevices');
      final result = await callable.call();
      return _parseDevices(result.data);
    } catch (error) {
      debugPrint('[DeviceService] Callable getDevices error: $error');
      rethrow;
    }
  }

  /// Sends a command to a device via Firebase Callable Functions.
  Future<bool> sendCommand(
    String clientId,
    String deviceId,
    String command, [
    dynamic value,
  ]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(
        message: 'Unauthenticated. Log in with Firebase first.',
        statusCode: 401,
      );
    }

    final String cleanDeviceId = deviceId.trim();
    final String cleanCommand = command.trim().toLowerCase();

    if (cleanDeviceId.isEmpty || cleanCommand.isEmpty) {
      debugPrint(
        '[DeviceService] Command rejected because required values are empty.',
      );
      return false;
    }

    try {
      final callable = _functions.httpsCallable('sendDeviceCommand');
      final result = await callable.call(<String, dynamic>{
        'deviceId': cleanDeviceId,
        'command': cleanCommand,
        'value': value,
      });

      return result.data != null && result.data['success'] == true;
    } catch (error) {
      debugPrint('[DeviceService] Callable sendCommand error: $error');
      return false;
    }
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
