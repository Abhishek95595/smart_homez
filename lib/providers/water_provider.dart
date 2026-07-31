import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/water_system.dart';

/// Water Pump Automation Engine client state (tank level, pump state,
/// auto/manual mode, dry-run/overflow protection per PRD).
class WaterProvider extends ChangeNotifier {
  final List<WaterTank> _tanks = MockData.demoTanks();

  List<WaterTank> get tanks => List.unmodifiable(_tanks);

  void setPumpMode(WaterTank tank, PumpMode mode) {
    tank.pumpMode = mode;
    notifyListeners();
  }

  void togglePumpManual(WaterTank tank) {
    if (tank.pumpMode != PumpMode.manual) return;
    if (tank.pumpState == PumpState.running) {
      _recordRun(tank);
      tank.pumpState = PumpState.stopped;
      tank.pumpStartedAt = null;
    } else {
      tank.pumpState = PumpState.running;
      tank.pumpStartedAt = DateTime.now();
    }
    notifyListeners();
  }

  /// Simulates the automation engine's decision, per PRD:
  /// low mark -> start pump; high mark -> stop pump.
  void simulateAutoTick(WaterTank tank) {
    if (tank.pumpMode != PumpMode.auto) return;
    if (tank.levelPercent <= tank.lowMark &&
        tank.pumpState != PumpState.running) {
      tank.pumpState = PumpState.running;
      tank.pumpStartedAt = DateTime.now();
    } else if (tank.levelPercent >= tank.highMark &&
        tank.pumpState == PumpState.running) {
      _recordRun(tank);
      tank.pumpState = PumpState.stopped;
      tank.pumpStartedAt = null;
    }
    notifyListeners();
  }

  void reportDryRun(WaterTank tank) {
    _recordRun(tank);
    tank.pumpState = PumpState.dryRunFault;
    tank.pumpStartedAt = null;
    tank.dryRunEventCount++;
    notifyListeners();
  }

  void _recordRun(WaterTank tank) {
    if (tank.pumpStartedAt == null) return;
    final duration = DateTime.now().difference(tank.pumpStartedAt!);
    tank.totalRunDuration += duration;
    tank.energyUsageKwh += duration.inSeconds / 3600 * 0.75;
  }
}
