import 'dart:async';
import 'dart:math';

import '../models/alert.dart';
import '../models/device.dart';
import '../models/telemetry.dart';

/// Simulates a real-time MQTT-like data feed (telemetry + alerts + heartbeats).
///
/// Interface is intentionally minimal (streams of domain objects) so that in
/// production this class can be replaced by a real MQTT client
/// (subscribing to anvya/{tenant}/{building}/{device}/telemetry etc.)
/// without any change to UI/provider code.
class RealtimeService {
  RealtimeService._internal();
  static final RealtimeService instance = RealtimeService._internal();

  final _telemetryController = StreamController<Telemetry>.broadcast();
  final _alertController = StreamController<AppAlert>.broadcast();
  final _random = Random();
  Timer? _timer;
  List<Device> _devices = [];
  int _tick = 0;

  Stream<Telemetry> get telemetryStream => _telemetryController.stream;
  Stream<AppAlert> get alertStream => _alertController.stream;

  void start(List<Device> devices) {
    _devices = devices;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tickSimulate());
  }

  void stop() {
    _timer?.cancel();
  }

  void _tickSimulate() {
    _tick++;
    for (final device in _devices) {
      switch (device.type) {
        case DeviceType.energyMeter:
          _telemetryController.add(
            Telemetry(
              deviceId: device.deviceId,
              timestamp: DateTime.now(),
              voltage: 225 + _random.nextDouble() * 10,
              current: 2 + _random.nextDouble() * 6,
              power: 400 + _random.nextDouble() * 1400,
            ),
          );
          break;
        case DeviceType.gasSensor:
          final ppm = 200 + _random.nextInt(150);
          _telemetryController.add(
            Telemetry(
              deviceId: device.deviceId,
              timestamp: DateTime.now(),
              gasPpm: ppm.toDouble(),
            ),
          );
          break;
        case DeviceType.smokeSensor:
          _telemetryController.add(
            Telemetry(
              deviceId: device.deviceId,
              timestamp: DateTime.now(),
              smoke: 0,
              temperature: 28 + _random.nextDouble() * 5,
            ),
          );
          break;
        default:
          break;
      }
    }

    // Occasionally simulate a random low-severity alert for demo liveliness.
    if (_tick % 15 == 0 && _devices.isNotEmpty) {
      final device = _devices[_random.nextInt(_devices.length)];
      _alertController.add(
        AppAlert(
          id: 'alert_sim_${DateTime.now().millisecondsSinceEpoch}',
          alertType: AlertType.deviceOffline,
          severity: AlertSeverity.low,
          location: device.zone,
          deviceId: device.deviceId,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void dispose() {
    _timer?.cancel();
    _telemetryController.close();
    _alertController.close();
  }
}
