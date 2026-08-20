import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/requests/create_automation_request.dart';
import '../models/routine_model.dart';
import 'automation_service.dart';

class RoutineService {
  RoutineService({AutomationService? automationService})
    : _automationService = automationService ?? AutomationService();

  final AutomationService _automationService;
  static const String _routineBoxName = 'smart_routines_cache';

  /// Fetches a Routine by type from backend / local cache
  Future<Routine?> getRoutine(String routineType, String defaultName) async {
    try {
      final automations = await _automationService.getAutomations();
      final automation = automations.firstWhere(
        (a) =>
            a.name.toLowerCase().contains(routineType.replaceAll('_', ' ')) ||
            a.name.toLowerCase().contains(defaultName.toLowerCase()),
        orElse: () => automations.firstWhere(
          (a) => a.id == '${routineType}_routine',
          orElse: () => throw Exception('Not found'),
        ),
      );

      final cachedRoutine = await _readFromCache(routineType);
      if (cachedRoutine != null) {
        return cachedRoutine.copyWith(
          id: automation.id,
          name: automation.name,
          isEnabled: automation.isActive,
        );
      }

      return Routine(
        id: automation.id,
        name: automation.name,
        isEnabled: automation.isActive,
      );
    } catch (e) {
      debugPrint('[RoutineService] Fetch from backend info ($routineType): $e');
      return _readFromCache(routineType);
    }
  }

  /// Saves or updates the Routine in backend and local cache
  Future<Routine> saveRoutine(Routine routine, String routineType) async {
    try {
      final activeDayCount = routine.activeDays.length;
      final totalEntries = routine.totalEntryCount;
      final request = CreateAutomationRequest(
        name: routine.name,
        isActive: routine.isEnabled,
        description:
            'Per-day schedule: $totalEntries entries across $activeDayCount days',
      );

      if (routine.id.isNotEmpty && !routine.id.startsWith('temp_')) {
        try {
          await _automationService.updateAutomation(
            automationId: routine.id,
            request: request,
          );
        } catch (_) {
          final created = await _automationService.createAutomation(request);
          routine = routine.copyWith(id: created.id);
        }
      } else {
        final created = await _automationService.createAutomation(request);
        routine = routine.copyWith(id: created.id);
      }
    } catch (e) {
      debugPrint('[RoutineService] Backend save note ($routineType): $e');
    }

    final updated = routine.copyWith(updatedAt: DateTime.now());
    await _writeToCache(updated, routineType);
    return updated;
  }

  /// Toggles routine enabled state on backend
  Future<void> toggleRoutine(
    String routineId,
    bool isEnabled,
    String routineType,
  ) async {
    try {
      if (routineId.isNotEmpty && !routineId.startsWith('temp_')) {
        await _automationService.toggleAutomation(
          automationId: routineId,
          isActive: isEnabled,
        );
      }
    } catch (e) {
      debugPrint('[RoutineService] Toggle backend error: $e');
    }

    final cached = await _readFromCache(routineType);
    if (cached != null) {
      await _writeToCache(cached.copyWith(isEnabled: isEnabled), routineType);
    }
  }

  /// Activates a Quick Scene via the backend Scene API
  Future<bool> activateScene(String sceneId) async {
    try {
      if (sceneId.isNotEmpty && !sceneId.startsWith('temp_')) {
        return await _automationService.activateScene(sceneId);
      }
    } catch (e) {
      debugPrint('[RoutineService] Activate scene backend error: $e');
    }
    return false;
  }

  // ================= Cache Helpers =================
  Future<Routine?> _readFromCache(String routineType) async {
    try {
      final box = await Hive.openBox(_routineBoxName);
      final raw = box.get(routineType);
      if (raw != null) {
        if (raw is String) {
          return Routine.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        } else if (raw is Map) {
          return Routine.fromJson(Map<String, dynamic>.from(raw));
        }
      }
    } catch (e) {
      debugPrint('[RoutineService] Cache read error: $e');
    }
    return null;
  }

  Future<void> _writeToCache(Routine routine, String routineType) async {
    try {
      final box = await Hive.openBox(_routineBoxName);
      await box.put(routineType, jsonEncode(routine.toJson()));
    } catch (e) {
      debugPrint('[RoutineService] Cache write error: $e');
    }
  }
}
