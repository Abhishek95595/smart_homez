import 'package:flutter/foundation.dart';

import '../models/client_dashboard_model.dart';
import '../services/client_dashboard_service.dart';

class ClientDashboardProvider extends ChangeNotifier {
  ClientDashboardProvider({ClientDashboardService? service})
    : _service = service ?? ClientDashboardService();

  final ClientDashboardService _service;

  ClientDashboardModel? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;
  String _period = 'daily';
  String? _homeId;

  ClientDashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get period => _period;
  String? get homeId => _homeId;

  Future<void> load({
    required String clientId,
    required String homeId,
    String? period,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _homeId = homeId;
    if (period != null) _period = period;
    notifyListeners();

    try {
      _dashboard = await _service.fetchDashboard(
        clientId: clientId,
        homeId: homeId,
        period: _period,
      );
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _dashboard = null;
    _errorMessage = null;
    _homeId = null;
    _period = 'daily';
    notifyListeners();
  }
}
