enum AlertSeverity { low, medium, high, critical }

extension AlertSeverityX on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.low:
        return 'LOW';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.critical:
        return 'CRITICAL';
    }
  }
}

enum AlertType {
  smoke,
  gasLeak,
  waterOverflow,
  pumpDryRun,
  highLoad,
  deviceOffline,
  general,
}

extension AlertTypeX on AlertType {
  String get label {
    switch (this) {
      case AlertType.smoke:
        return 'Smoke Detected';
      case AlertType.gasLeak:
        return 'Gas Leak';
      case AlertType.waterOverflow:
        return 'Water Overflow';
      case AlertType.pumpDryRun:
        return 'Pump Dry-Run';
      case AlertType.highLoad:
        return 'High Load';
      case AlertType.deviceOffline:
        return 'Device Offline';
      case AlertType.general:
        return 'General';
    }
  }
}

/// Mirrors the alert MQTT payload from the PRD:
/// {
///   "alert_type": "gas_leak", "severity": "CRITICAL",
///   "location": "Tower A / Basement", "device_id": "dev_009",
///   "value": 780, "threshold": 500, "timestamp": "..."
/// }
class AppAlert {
  final String id;
  final AlertType alertType;
  final AlertSeverity severity;
  final String location;
  final String deviceId;
  final double? value;
  final double? threshold;
  final DateTime timestamp;
  bool acknowledged;
  String? acknowledgedBy;
  DateTime? acknowledgedAt;
  bool resolved;
  String? resolvedBy;
  DateTime? resolvedAt;

  AppAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.location,
    required this.deviceId,
    this.value,
    this.threshold,
    required this.timestamp,
    this.acknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolved = false,
    this.resolvedBy,
    this.resolvedAt,
  });
}
