import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/alert.dart';
import '../services/realtime_service.dart';

/// Alert Engine client-side state. Prioritizes CRITICAL/HIGH alerts,
/// tracks acknowledgment as per the PRD's Safety Alert Engine workflow.
class AlertProvider extends ChangeNotifier {
  final List<AppAlert> _alerts = MockData.demoAlerts();
  StreamSubscription<AppAlert>? _sub;

  List<AppAlert> get alerts => List.unmodifiable(
    _alerts..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
  );

  List<AppAlert> get activeAlerts => _alerts.where((a) => !a.resolved).toList()
    ..sort(
      (a, b) => _severityRank(b.severity).compareTo(_severityRank(a.severity)),
    );

  List<AppAlert> get priorityAlerts =>
      List<AppAlert>.from(_alerts)..sort((a, b) {
        final severityCompare = _severityRank(
          b.severity,
        ).compareTo(_severityRank(a.severity));
        if (severityCompare != 0) return severityCompare;
        if (a.acknowledged != b.acknowledged) {
          return a.acknowledged ? 1 : -1;
        }
        return b.timestamp.compareTo(a.timestamp);
      });

  List<AppAlert> get activeSafetyAlerts => activeAlerts
      .where(
        (alert) =>
            alert.alertType == AlertType.smoke ||
            alert.alertType == AlertType.gasLeak,
      )
      .toList();

  List<AppAlert> get fireAndSmokeAlerts => alerts
      .where(
        (alert) =>
            alert.alertType == AlertType.smoke ||
            alert.alertType == AlertType.gasLeak,
      )
      .toList();

  int get criticalActiveCount => _alerts
      .where((a) => !a.resolved && a.severity == AlertSeverity.critical)
      .length;

  int get activeSmokeCount => activeSafetyAlerts
      .where((alert) => alert.alertType == AlertType.smoke)
      .length;

  int get activeGasLeakCount => activeSafetyAlerts
      .where((alert) => alert.alertType == AlertType.gasLeak)
      .length;

  int get activeHighCount => _alerts
      .where((a) => !a.resolved && a.severity == AlertSeverity.high)
      .length;

  int get acknowledgedCount =>
      _alerts.where((alert) => alert.acknowledged).length;

  int _severityRank(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 4;
      case AlertSeverity.high:
        return 3;
      case AlertSeverity.medium:
        return 2;
      case AlertSeverity.low:
        return 1;
    }
  }

  void listenRealtime() {
    _sub = RealtimeService.instance.alertStream.listen((alert) {
      _alerts.insert(0, alert);
      notifyListeners();
    });
  }

  void acknowledge(AppAlert alert, String byUser) {
    alert.acknowledged = true;
    alert.acknowledgedBy = byUser;
    alert.acknowledgedAt = DateTime.now();
    notifyListeners();
  }

  void resolve(AppAlert alert, String byUser) {
    alert.acknowledged = true;
    alert.acknowledgedBy ??= byUser;
    alert.acknowledgedAt ??= DateTime.now();
    alert.resolved = true;
    alert.resolvedBy = byUser;
    alert.resolvedAt = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
