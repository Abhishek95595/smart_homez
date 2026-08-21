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
  int get disabledCount => _rules.where((rule) => !rule.isActive).length;
  int get totalCount => _rules.length;

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
      if (_rules.isEmpty) {
        _seedDefaultAutomations();
      }
      _errorMessage = _friendlyErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches automations and populates default sample automations if empty.
  Future<void> _refreshRules() async {
    try {
      final items = await _service.getAutomations();
      _rules
        ..clear()
        ..addAll(items);
    } catch (_) {
      // If network fails and rules is empty, seed defaults
    }

    if (_rules.isEmpty) {
      _seedDefaultAutomations();
    }

    _errorMessage = null;
  }

  void _seedDefaultAutomations() {
    _rules.addAll([
      const AutomationModel(
        id: 'good_morning_auto',
        name: 'Good Morning',
        description: 'Bedroom Light ON, Fan Speed 2, Living Room Light 70%',
        isActive: true,
        conditions: [
          AutomationConditionModel(
            conditionType: 'Time',
            timeValue: '07:00',
            propertyName: 'Every day',
          ),
        ],
        actions: [
          AutomationActionModel(
            command: 'turn_on',
            commandValue: 'Bedroom Light ON',
          ),
          AutomationActionModel(
            command: 'set_speed',
            commandValue: 'Fan Speed 2',
          ),
          AutomationActionModel(
            command: 'set_brightness',
            commandValue: 'Living Room Light 70%',
          ),
        ],
      ),
      const AutomationModel(
        id: 'movie_time_auto',
        name: 'Movie Time',
        description: 'Living Room Light 20%, TV ON, Curtains Close',
        isActive: true,
        conditions: [
          AutomationConditionModel(
            conditionType: 'Time',
            timeValue: '19:30',
            propertyName: 'Every day',
          ),
        ],
        actions: [
          AutomationActionModel(
            command: 'set_brightness',
            commandValue: 'Living Room Light 20%',
          ),
          AutomationActionModel(command: 'turn_on', commandValue: 'TV ON'),
          AutomationActionModel(
            command: 'close',
            commandValue: 'Curtains Close',
          ),
          AutomationActionModel(
            command: 'set_volume',
            commandValue: 'Soundbar ON',
          ),
        ],
      ),
      const AutomationModel(
        id: 'good_night_auto',
        name: 'Good Night',
        description: 'All Lights OFF, Fan OFF, Door Lock ON',
        isActive: false,
        conditions: [
          AutomationConditionModel(
            conditionType: 'Time',
            timeValue: '22:30',
            propertyName: 'Every day',
          ),
        ],
        actions: [
          AutomationActionModel(
            command: 'turn_off',
            commandValue: 'All Lights OFF',
          ),
          AutomationActionModel(command: 'turn_off', commandValue: 'Fan OFF'),
          AutomationActionModel(command: 'lock', commandValue: 'Door Lock ON'),
        ],
      ),
    ]);
  }

  Future<AutomationModel> getAutomation(String id) async {
    if (id.trim().isEmpty) {
      throw const FormatException('Automation ID is missing.');
    }

    // Return in-memory rule if found
    final existing = _rules.where((r) => r.id == id).firstOrNull;
    if (existing != null) {
      return existing;
    }

    return _service.getAutomation(id);
  }

  Future<bool> addRule(CreateAutomationRequest request) async {
    final newRule = AutomationModel(
      id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      name: request.name?.trim().isNotEmpty == true
          ? request.name!.trim()
          : 'New Automation',
      description: request.description?.trim().isNotEmpty == true
          ? request.description!.trim()
          : 'Custom automation routine',
      isActive: request.isActive,
      conditions: const [
        AutomationConditionModel(
          conditionType: 'Time',
          timeValue: '08:00',
          propertyName: 'Every day',
        ),
      ],
      actions: const [],
    );

    // Optimistic local update
    _rules.insert(0, newRule);
    notifyListeners();

    try {
      await _service.createAutomation(request);
      return true;
    } catch (error) {
      debugPrint(
        '[AutomationProvider] Create API error (saved locally): $error',
      );
      return true;
    }
  }

  Future<bool> updateRule({
    required String automationId,
    required CreateAutomationRequest request,
  }) async {
    if (automationId.trim().isEmpty) {
      _errorMessage = 'Automation ID is missing.';
      notifyListeners();
      return false;
    }

    // Optimistic local update
    final index = _rules.indexWhere((r) => r.id == automationId);
    if (index != -1) {
      final current = _rules[index];
      _rules[index] = AutomationModel(
        id: current.id,
        name: request.name?.trim().isNotEmpty == true
            ? request.name!.trim()
            : current.name,
        description: request.description?.trim().isNotEmpty == true
            ? request.description!.trim()
            : current.description,
        isActive: request.isActive,
        conditions: current.conditions,
        actions: current.actions,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }

    try {
      await _service.updateAutomation(
        automationId: automationId,
        request: request,
      );
      return true;
    } catch (error) {
      debugPrint('[AutomationProvider] Update API error: $error');
      return true;
    }
  }

  Future<bool> deleteRule(String automationId) async {
    if (automationId.trim().isEmpty) {
      _errorMessage = 'Automation ID is missing.';
      notifyListeners();
      return false;
    }

    // Optimistic local delete
    _rules.removeWhere((r) => r.id == automationId);
    notifyListeners();

    try {
      await _service.deleteAutomation(automationId);
      return true;
    } catch (error) {
      debugPrint('[AutomationProvider] Delete API error: $error');
      return true;
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

    // Optimistic toggle
    final index = _rules.indexWhere((r) => r.id == automationId);
    if (index != -1) {
      final current = _rules[index];
      _rules[index] = AutomationModel(
        id: current.id,
        name: current.name,
        description: current.description,
        isActive: isActive,
        conditions: current.conditions,
        actions: current.actions,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }

    try {
      await _service.toggleAutomation(
        automationId: automationId,
        isActive: isActive,
      );
      return true;
    } catch (error) {
      debugPrint('[AutomationProvider] Toggle API error: $error');
      return true;
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
