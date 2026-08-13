import 'package:flutter/foundation.dart';

import '../data/models/requests/create_automation_request.dart';
import '../models/automation_model.dart';
import '../services/automation_service.dart';

class AutomationProvider extends ChangeNotifier {
  AutomationProvider({AutomationService? service})
    : _service = service ?? AutomationService() {
    fetchRules();
  }

  final AutomationService _service;

  final List<AutomationModel> _rules = [];
  final Set<String> _updatingRuleIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<AutomationModel> get rules => List.unmodifiable(_rules);

  int get enabledCount => _rules.where((rule) => rule.isActive).length;

  bool get isLoading => _isLoading;
  bool get loading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isRuleUpdating(String ruleId) {
    return _updatingRuleIds.contains(ruleId);
  }

  Future<void> fetchRules() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _refreshRules();
    } catch (error, stackTrace) {
      debugPrint('[AutomationProvider] Fetch error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches automations without changing the global loading state.
  ///
  /// This is used after create, update, delete, and toggle operations so
  /// the list can refresh even while the provider is already processing
  /// another operation.
  Future<void> _refreshRules() async {
    final items = await _service.getAutomations();

    _rules
      ..clear()
      ..addAll(items);

    _errorMessage = null;
  }

  Future<AutomationModel> getAutomation(String id) async {
    if (id.trim().isEmpty) {
      throw const FormatException('Automation ID is missing.');
    }

    return _service.getAutomation(id);
  }

  Future<bool> addRule(CreateAutomationRequest request) async {
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createAutomation(request);
      await _refreshRules();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AutomationProvider] Create error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyErrorMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRule({
    required String automationId,
    required CreateAutomationRequest request,
  }) async {
    if (_isLoading) {
      return false;
    }

    if (automationId.trim().isEmpty) {
      _errorMessage = 'Automation ID is missing.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateAutomation(
        automationId: automationId,
        request: request,
      );

      await _refreshRules();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AutomationProvider] Update error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyErrorMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRule(String automationId) async {
    if (automationId.trim().isEmpty) {
      _errorMessage = 'Automation ID is missing.';
      notifyListeners();
      return false;
    }

    if (_updatingRuleIds.contains(automationId)) {
      return false;
    }

    _updatingRuleIds.add(automationId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteAutomation(automationId);
      await _refreshRules();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AutomationProvider] Delete error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyErrorMessage(error);
      return false;
    } finally {
      _updatingRuleIds.remove(automationId);
      notifyListeners();
    }
  }

  Future<bool> toggleRule({
    required String automationId,
    required bool isActive,
  }) async {
    if (automationId.trim().isEmpty) {
      _errorMessage = 'Automation ID is missing.';
      notifyListeners();
      return false;
    }

    if (_updatingRuleIds.contains(automationId)) {
      return false;
    }

    _updatingRuleIds.add(automationId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.toggleAutomation(
        automationId: automationId,
        isActive: isActive,
      );

      await _refreshRules();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AutomationProvider] Toggle error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyErrorMessage(error);
      return false;
    } finally {
      _updatingRuleIds.remove(automationId);
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyErrorMessage(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');

    if (message.contains('401')) {
      return 'Session expired. Please authenticate again.';
    }

    if (message.contains('403')) {
      return 'You do not have permission to manage automations.';
    }

    if (message.contains('404')) {
      return 'Automation was not found.';
    }

    if (message.contains('409')) {
      return 'This automation conflicts with existing data.';
    }

    if (message.contains('500')) {
      return 'The automation service is currently unavailable.';
    }

    if (message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('socket')) {
      return 'Unable to connect to the server. Check your internet connection.';
    }

    return message.isEmpty
        ? 'An unexpected automation error occurred.'
        : message;
  }
}
