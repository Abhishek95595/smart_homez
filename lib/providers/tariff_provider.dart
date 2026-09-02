import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing electricity tariff rates:
/// 1. Normal Electricity / Grid Charge (₹/kWh)
/// 2. Backup / Generator Charge (₹/kWh)
class TariffProvider extends ChangeNotifier {
  static const String _gridRateKey = 'tariff_grid_rate_per_kwh';
  static const String _backupRateKey = 'tariff_backup_rate_per_kwh';
  static const String _currencyKey = 'tariff_currency_symbol';

  double _gridRate = 8.50; // Default normal electricity grid charge
  double _backupRate = 14.00; // Default backup/generator charge
  String _currencySymbol = '₹';
  bool _isLoaded = false;

  double get gridRate => _gridRate;
  double get backupRate => _backupRate;
  String get currencySymbol => _currencySymbol;
  bool get isLoaded => _isLoaded;

  TariffProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gridRate = prefs.getDouble(_gridRateKey) ?? 8.50;
      _backupRate = prefs.getDouble(_backupRateKey) ?? 14.00;
      _currencySymbol = prefs.getString(_currencyKey) ?? '₹';
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[TariffProvider] Load error: $e');
    }
  }

  Future<void> setRates({
    required double gridRate,
    required double backupRate,
    String? currencySymbol,
  }) async {
    _gridRate = gridRate > 0 ? gridRate : 8.50;
    _backupRate = backupRate > 0 ? backupRate : 14.00;
    if (currencySymbol != null && currencySymbol.isNotEmpty) {
      _currencySymbol = currencySymbol;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_gridRateKey, _gridRate);
      await prefs.setDouble(_backupRateKey, _backupRate);
      await prefs.setString(_currencyKey, _currencySymbol);
    } catch (e) {
      debugPrint('[TariffProvider] Save error: $e');
    }
  }

  double calculateGridCost(double kwh) => kwh * _gridRate;
  double calculateBackupCost(double kwh) => kwh * _backupRate;
  double calculateTotalCost(double gridKwh, double backupKwh) =>
      (gridKwh * _gridRate) + (backupKwh * _backupRate);
}
