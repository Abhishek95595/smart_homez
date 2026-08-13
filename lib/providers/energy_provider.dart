import 'package:flutter/material.dart';

import '../models/client_dashboard_model.dart';
import '../services/client_dashboard_service.dart';

enum DashboardPeriod {
  hourly('hourly', 'Last 24 Hours'),
  daily('daily', 'Last 30 Days'),
  weekly('weekly', 'Last 12 Weeks'),
  monthly('monthly', 'Last 12 Months');

  final String apiValue;
  final String label;
  const DashboardPeriod(this.apiValue, this.label);
}

/// Energy Analytics Engine state using real API data from ClientDashboardService.
class EnergyProvider extends ChangeNotifier {
  final ClientDashboardService _service;

  EnergyProvider({ClientDashboardService? service})
    : _service = service ?? ClientDashboardService();

  ClientDashboardModel? _dashboard;
  bool _isLoading = false;
  String? _error;
  DashboardPeriod _selectedPeriod = DashboardPeriod.daily;

  ClientDashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardPeriod get selectedPeriod => _selectedPeriod;

  // Mapped values for UI compatibility or direct access
  double get instantPowerWatts => _dashboard?.liveWatts ?? 0;
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

  Future<void> fetchDashboard({
    required String clientId,
    required String homeId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _service.fetchDashboard(
        clientId: clientId,
        homeId: homeId,
        period: _selectedPeriod.apiValue,
      );
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _dashboard = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _dashboard = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
