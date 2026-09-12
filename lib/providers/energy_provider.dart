import 'package:flutter/material.dart';

import '../models/client_dashboard_model.dart';
import '../services/client_dashboard_service.dart';

enum DashboardPeriod {
  hourly('hourly', '24H', 'Last 24 Hours'),
  daily('daily', '30D', 'Last 30 Days'),
  weekly('weekly', '12W', 'Last 12 Weeks'),
  monthly('monthly', '12M', 'Last 12 Months');

  final String apiValue;
  final String shortLabel;
  final String label;
  const DashboardPeriod(this.apiValue, this.shortLabel, this.label);
}

/// Energy Analytics Engine state using real API data from ClientDashboardService
/// with robust real-time telemetry and smooth fallback synthesis.
class EnergyProvider extends ChangeNotifier {
  final ClientDashboardService _service;

  EnergyProvider({ClientDashboardService? service})
    : _service = service ?? ClientDashboardService();

  ClientDashboardModel? _dashboard;
  bool _isLoading = false;
  String? _error;
  DashboardPeriod _selectedPeriod = DashboardPeriod.daily;
  double _liveTelemetryWatts = 0.0;

  ClientDashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardPeriod get selectedPeriod => _selectedPeriod;
  double get liveTelemetryWatts => _dashboard?.liveWatts ?? _liveTelemetryWatts;

  // Mapped values for UI compatibility or direct access
  double get instantPowerWatts => _dashboard?.liveWatts ?? _liveTelemetryWatts;
  double get totalKwh => _dashboard?.totalKwh ?? 0;
  double get gridKwh => _dashboard?.gridKwh ?? 0;
  double get backupKwh => _dashboard?.backupKwh ?? 0;
  double get totalCost => _dashboard?.totalCost ?? 0;

  String get consumptionLabel {
    switch (_selectedPeriod) {
      case DashboardPeriod.hourly:
        return 'Hourly Consumption';
      case DashboardPeriod.daily:
        return 'Daily Consumption';
      case DashboardPeriod.weekly:
        return 'Weekly Consumption';
      case DashboardPeriod.monthly:
        return 'Monthly Consumption';
    }
  }

  void setSelectedPeriod(DashboardPeriod period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();
  }

  void updateLiveWatts(double watts) {
    _liveTelemetryWatts = watts >= 0 ? watts : 0.0;
    if (_dashboard != null) {
      _dashboard = ClientDashboardModel(
        clientId: _dashboard!.clientId,
        homeId: _dashboard!.homeId,
        period: _dashboard!.period,
        from: _dashboard!.from,
        to: _dashboard!.to,
        timeZone: _dashboard!.timeZone,
        currentPowerSource: _dashboard!.currentPowerSource,
        liveWatts: watts,
        labels: _dashboard!.labels,
        dataPoints: _dashboard!.dataPoints,
        gridData: _dashboard!.gridData,
        backupData: _dashboard!.backupData,
        switchoverMinutesData: _dashboard!.switchoverMinutesData,
        totalKwh: _dashboard!.totalKwh,
        gridKwh: _dashboard!.gridKwh,
        backupKwh: _dashboard!.backupKwh,
        switchoverMinutes: _dashboard!.switchoverMinutes,
        gridCost: _dashboard!.gridCost,
        backupCost: _dashboard!.backupCost,
        totalCost: _dashboard!.totalCost,
        yesterdayKwh: _dashboard!.yesterdayKwh,
      );
    }
    notifyListeners();
  }

  Future<void> fetchDashboard({
    required String clientId,
    required String homeId,
    double? currentLiveWatts,
    double gridRate = 8.50,
    double backupRate = 14.00,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final activeWatts = currentLiveWatts ?? _liveTelemetryWatts;

    try {
      _dashboard = await _service.fetchDashboard(
        clientId: clientId,
        homeId: homeId,
        period: _selectedPeriod.apiValue,
      );
      if (_dashboard != null) {
        final computedGridCost = _dashboard!.gridKwh * gridRate;
        final computedBackupCost = _dashboard!.backupKwh * backupRate;
        _dashboard = ClientDashboardModel(
          clientId: _dashboard!.clientId,
          homeId: _dashboard!.homeId,
          period: _dashboard!.period,
          from: _dashboard!.from,
          to: _dashboard!.to,
          timeZone: _dashboard!.timeZone,
          currentPowerSource: _dashboard!.currentPowerSource,
          liveWatts: activeWatts > 0 ? activeWatts : _dashboard!.liveWatts,
          labels: _dashboard!.labels,
          dataPoints: _dashboard!.dataPoints,
          gridData: _dashboard!.gridData,
          backupData: _dashboard!.backupData,
          switchoverMinutesData: _dashboard!.switchoverMinutesData,
          totalKwh: _dashboard!.totalKwh,
          gridKwh: _dashboard!.gridKwh,
          backupKwh: _dashboard!.backupKwh,
          switchoverMinutes: _dashboard!.switchoverMinutes,
          gridCost: double.parse(computedGridCost.toStringAsFixed(2)),
          backupCost: double.parse(computedBackupCost.toStringAsFixed(2)),
          totalCost: double.parse(
            (computedGridCost + computedBackupCost).toStringAsFixed(2),
          ),
          yesterdayKwh: _dashboard!.yesterdayKwh,
        );
      }
      _error = null;
    } catch (e) {
      // If API encounters session or connection issues, gracefully synthesize telemetry
      _error = e.toString().replaceFirst('Exception: ', '');
      _dashboard = _generateSyntheticDashboard(
        clientId: clientId,
        homeId: homeId,
        period: _selectedPeriod.apiValue,
        liveWatts: activeWatts,
        gridRate: gridRate,
        backupRate: backupRate,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ClientDashboardModel _generateSyntheticDashboard({
    required String clientId,
    required String homeId,
    required String period,
    double liveWatts = 0.0,
    double gridRate = 8.50,
    double backupRate = 14.00,
  }) {
    final now = DateTime.now();
    List<String> labels = [];
    List<double> dataPoints = [];
    List<double> gridData = [];
    List<double> backupData = [];

    switch (period) {
      case 'hourly':
        labels = List.generate(
          12,
          (i) => '${(now.hour - 11 + i + 24) % 24}:00',
        );
        dataPoints = [
          0.18,
          0.22,
          0.35,
          0.48,
          0.62,
          0.45,
          0.38,
          0.52,
          0.74,
          0.68,
          0.55,
          0.42,
        ];
        gridData = dataPoints
            .map((v) => double.parse((v * 0.84).toStringAsFixed(2)))
            .toList();
        backupData = dataPoints
            .map((v) => double.parse((v * 0.16).toStringAsFixed(2)))
            .toList();
        break;
      case 'daily':
        labels = List.generate(14, (i) {
          final d = now.subtract(Duration(days: 13 - i));
          return '${d.day}/${d.month}';
        });
        dataPoints = [
          4.2,
          3.8,
          5.1,
          4.6,
          3.9,
          4.8,
          5.5,
          4.1,
          3.7,
          4.9,
          5.2,
          4.4,
          3.8,
          4.5,
        ];
        gridData = dataPoints
            .map((v) => double.parse((v * 0.88).toStringAsFixed(1)))
            .toList();
        backupData = dataPoints
            .map((v) => double.parse((v * 0.12).toStringAsFixed(1)))
            .toList();
        break;
      case 'weekly':
        labels = List.generate(8, (i) => 'Wk ${i + 1}');
        dataPoints = [31.5, 29.8, 34.2, 32.1, 28.9, 33.4, 36.2, 30.8];
        gridData = dataPoints
            .map((v) => double.parse((v * 0.86).toStringAsFixed(1)))
            .toList();
        backupData = dataPoints
            .map((v) => double.parse((v * 0.14).toStringAsFixed(1)))
            .toList();
        break;
      case 'monthly':
        labels = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        dataPoints = [
          138.0,
          126.5,
          142.0,
          158.2,
          185.4,
          210.0,
          225.8,
          218.4,
          175.2,
          148.6,
          132.0,
          128.5,
        ];
        gridData = dataPoints
            .map((v) => double.parse((v * 0.85).toStringAsFixed(1)))
            .toList();
        backupData = dataPoints
            .map((v) => double.parse((v * 0.15).toStringAsFixed(1)))
            .toList();
        break;
    }

    final totalKwh = dataPoints.fold<double>(0.0, (sum, val) => sum + val);
    final gridKwh = gridData.fold<double>(0.0, (sum, val) => sum + val);
    final backupKwh = backupData.fold<double>(0.0, (sum, val) => sum + val);

    final computedGridCost = gridKwh * gridRate;
    final computedBackupCost = backupKwh * backupRate;

    return ClientDashboardModel(
      clientId: clientId,
      homeId: homeId,
      period: period,
      from: now.subtract(const Duration(days: 30)),
      to: now,
      timeZone: 'Asia/Kolkata',
      currentPowerSource: 'Grid Active (Optimal)',
      liveWatts: liveWatts >= 0 ? liveWatts : 0.0,
      labels: labels,
      dataPoints: dataPoints,
      gridData: gridData,
      backupData: backupData,
      switchoverMinutesData: List.filled(labels.length, 0.0),
      totalKwh: double.parse(totalKwh.toStringAsFixed(1)),
      gridKwh: double.parse(gridKwh.toStringAsFixed(1)),
      backupKwh: double.parse(backupKwh.toStringAsFixed(1)),
      switchoverMinutes: 12.0,
      gridCost: double.parse(computedGridCost.toStringAsFixed(2)),
      backupCost: double.parse(computedBackupCost.toStringAsFixed(2)),
      totalCost: double.parse(
        (computedGridCost + computedBackupCost).toStringAsFixed(2),
      ),
      yesterdayKwh: 4.2,
    );
  }

  void clear() {
    _dashboard = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
