enum PumpMode { auto, manual }

enum PumpState { running, stopped, dryRunFault, maintenanceLockout }

/// Represents a tank + pump automation pair (per PRD Water Pump Automation Engine).
class WaterTank {
  final String id;
  final String name; // e.g. "Overhead Tank - Tower A"
  double levelPercent;
  final double lowMark;
  final double highMark;
  PumpMode pumpMode;
  PumpState pumpState;
  DateTime? pumpStartedAt;
  int dryRunEventCount;
  int overflowEventCount;
  Duration totalRunDuration;
  double energyUsageKwh;
  bool overflowProtectionEnabled;

  WaterTank({
    required this.id,
    required this.name,
    required this.levelPercent,
    this.lowMark = 25,
    this.highMark = 95,
    this.pumpMode = PumpMode.auto,
    this.pumpState = PumpState.stopped,
    this.pumpStartedAt,
    this.dryRunEventCount = 0,
    this.overflowEventCount = 0,
    this.totalRunDuration = Duration.zero,
    this.energyUsageKwh = 0,
    this.overflowProtectionEnabled = true,
  });

  Duration get currentRunDuration {
    if (pumpState != PumpState.running || pumpStartedAt == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(pumpStartedAt!);
  }

  Duration get displayedRunDuration => totalRunDuration + currentRunDuration;
}
