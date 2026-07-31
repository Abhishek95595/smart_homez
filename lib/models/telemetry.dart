/// Mirrors the telemetry MQTT payload from the PRD:
/// {
///   "device_id": "dev_001", "timestamp": "...",
///   "temperature": 31.4, "gas_ppm": 420, "smoke": 0,
///   "voltage": 229.8, "current": 4.7, "power": 1021,
///   "tank_level_percent": 68
/// }
class Telemetry {
  final String deviceId;
  final DateTime timestamp;
  final double? temperature;
  final double? gasPpm;
  final int? smoke; // 0/1 flag
  final double? voltage;
  final double? current;
  final double? power; // watts
  final double? tankLevelPercent;

  const Telemetry({
    required this.deviceId,
    required this.timestamp,
    this.temperature,
    this.gasPpm,
    this.smoke,
    this.voltage,
    this.current,
    this.power,
    this.tankLevelPercent,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    if (temperature != null) 'temperature': temperature,
    if (gasPpm != null) 'gas_ppm': gasPpm,
    if (smoke != null) 'smoke': smoke,
    if (voltage != null) 'voltage': voltage,
    if (current != null) 'current': current,
    if (power != null) 'power': power,
    if (tankLevelPercent != null) 'tank_level_percent': tankLevelPercent,
  };
}

/// A single point for energy usage history (used for charts).
class EnergyUsagePoint {
  final DateTime time;
  final double kwh;

  const EnergyUsagePoint({required this.time, required this.kwh});
}
