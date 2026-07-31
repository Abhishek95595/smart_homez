import 'package:flutter/material.dart';
import '../models/automation_rule.dart';
import '../services/tenant_api_repository.dart';

class AutomationProvider extends ChangeNotifier {
  final TenantApiRepository _apiRepo = TenantApiRepository();
  final List<AutomationRule> _rules = [];
  bool _isLoading = false;

  AutomationProvider() {
    // We could initial fetch here, but usually MainShell or the screen will trigger it
  }

  List<AutomationRule> get rules => List.unmodifiable(_rules);
  int get enabledCount => _rules.where((r) => r.enabled).length;
  bool get isLoading => _isLoading;
  bool get loading => _isLoading; // Compatibility alias

  Future<void> fetchRules() async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiRules = await _apiRepo.getAutomations();
      _rules.clear();
      for (final r in apiRules) {
        _rules.add(AutomationRule(
          id: r.id,
          name: r.name,
          trigger: 'Time/Sensor', // Placeholder for complex mapping
          action: 'Run command',   // Placeholder
          repeat: 'Custom',        // Placeholder
          scene: 'Attached Scene', // Placeholder
          enabled: r.isActive,
        ));
      }
    } catch (e) {
      debugPrint('Error fetching automations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRule(AutomationRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index == -1) return;

    final newState = !rule.enabled;
    final success = await _apiRepo.toggleAutomation(rule.id, newState);

    if (success) {
      _rules[index] = rule.copyWith(enabled: newState);
      notifyListeners();
    }
  }

  void addRule(AutomationRule rule) {
    _rules.add(rule);
    notifyListeners();
  }

  void deleteRule(String id) {
    _rules.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
