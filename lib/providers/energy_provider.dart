import 'dart:math';

import 'package:flutter/material.dart';

import '../models/telemetry.dart';

/// Energy Analytics Engine client state: instant power, daily/monthly
/// trends, appliance-wise ranking and cost estimation (per PRD).
class EnergyProvider extends ChangeNotifier {
  static const double costPerKwh = 8.0; // INR per kWh, configurable

  double instantPowerWatts = 1120;
  double todayKwh = 6.4;
  double monthKwh = 148.2;

  final Map<String, double> applianceUsageKwh = {
    'AC': 62.4,
    'Fridge': 34.1,
    'Lights': 18.7,
    'Fan': 12.2,
    'Water Pump': 20.8,
  };

  List<EnergyUsagePoint> weeklyUsage() {
    final now = DateTime.now();
    final rnd = Random(7);
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return EnergyUsagePoint(time: day, kwh: 5 + rnd.nextDouble() * 6);
    });
  }

  List<EnergyUsagePoint> hourlyToday() {
    final now = DateTime.now();
    final rnd = Random(3);
    return List.generate(12, (i) {
      final hour = now.subtract(Duration(hours: (11 - i) * 2));
      return EnergyUsagePoint(time: hour, kwh: 0.2 + rnd.nextDouble() * 1.1);
    });
  }

  double estimatedMonthlyCost() => monthKwh * costPerKwh;

  List<MapEntry<String, double>> get topConsumers {
    final entries = applianceUsageKwh.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  void updateInstantPower(double watts) {
    instantPowerWatts = watts;
    notifyListeners();
  }
}
