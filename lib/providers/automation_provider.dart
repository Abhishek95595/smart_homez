import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/automation_rule.dart';

class AutomationProvider extends ChangeNotifier {
  static const _boxName = 'smart_homz_automations';
  static const _rulesKey = 'rules_v1';

  final List<AutomationRule> _rules = [];
  bool _loading = true;

  AutomationProvider() {
    _load();
  }

  List<AutomationRule> get rules => List.unmodifiable(_rules);
  bool get loading => _loading;
  int get enabledCount => _rules.where((rule) => rule.enabled).length;

  Future<void> _load() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final stored = box.get(_rulesKey);
      if (stored != null) {
        final list = jsonDecode(stored) as List<dynamic>;
        _rules.addAll(
          list.map(
            (item) =>
                AutomationRule.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      }
    } on HiveError {
      // The app remains usable with session data if storage is unavailable.
    }
    if (_rules.isEmpty) _seedDefaults();
    _loading = false;
    notifyListeners();
  }

  void _seedDefaults() {
    _rules.addAll(const [
      AutomationRule(
        id: 'morning_scene',
        name: 'Good Morning',
        trigger: '07:00',
        action: 'Open curtains · Lights 45% · Pump auto',
        repeat: 'Daily',
        scene: 'Morning',
      ),
      AutomationRule(
        id: 'away_scene',
        name: 'Away Protection',
        trigger: 'When everyone leaves',
        action: 'Lock doors · Turn off lights · Arm sensors',
        repeat: 'Always',
        scene: 'Away',
      ),
      AutomationRule(
        id: 'night_scene',
        name: 'Night Safety',
        trigger: '22:30',
        action: 'Lock doors · Night lights · Safety monitoring',
        repeat: 'Daily',
        scene: 'Night',
      ),
    ]);
  }

  Future<void> addRule({
    required String name,
    required String trigger,
    required String action,
    required String repeat,
    required String scene,
  }) async {
    _rules.add(
      AutomationRule(
        id: const Uuid().v4(),
        name: name.trim(),
        trigger: trigger,
        action: action.trim(),
        repeat: repeat,
        scene: scene,
      ),
    );
    await _saveAndNotify();
  }

  Future<void> toggleRule(String id, bool enabled) async {
    final index = _rules.indexWhere((rule) => rule.id == id);
    if (index == -1) return;
    _rules[index] = _rules[index].copyWith(enabled: enabled);
    await _saveAndNotify();
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((rule) => rule.id == id);
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(
        _rulesKey,
        jsonEncode(_rules.map((rule) => rule.toJson()).toList()),
      );
    } on HiveError {
      // Keep the in-memory state and continue.
    }
    notifyListeners();
  }
}
