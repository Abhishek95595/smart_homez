import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../models/routine_model.dart';
import '../services/routine_service.dart';
import 'device_provider.dart';

enum RoutineState {
  initial,
  loading,
  loaded,
  saving,
  executing,
  success,
  emptyDevices,
  error,
}

class RoutineProvider extends ChangeNotifier {
  RoutineProvider({
    RoutineService? routineService,
    DeviceProvider? deviceProvider,
  }) : _service = routineService ?? RoutineService(),
       _deviceProvider = deviceProvider {
    _startScheduler();
  }

  final RoutineService _service;
  DeviceProvider? _deviceProvider;

  final Map<String, Routine> _routines = {};
  String _activeRoutineId = 'good_morning'; // Default fallback

  RoutineState _state = RoutineState.initial;
  String? _errorMessage;
  String _selectedDay = _todayCode();

  Timer? _schedulerTimer;
  final Set<String> _triggeredKeys = {};
  final Set<String> _savingRoutineKeys = {};

  void setDeviceProvider(DeviceProvider? dp) {
    _deviceProvider = dp;
  }

  // ── Getters ──
  Routine? get routine => _routines[_activeRoutineId];
  RoutineState get state => _state;
  String? get errorMessage => _errorMessage;
  String get selectedDay => _selectedDay;
  String get activeRoutineId => _activeRoutineId;

  bool get isLoading => _state == RoutineState.loading;
  bool get isSaving => _state == RoutineState.saving;

  DaySchedule? get selectedDaySchedule => routine?.daySchedules[_selectedDay];

  List<ScheduleEntry> get selectedDayEntries =>
      selectedDaySchedule?.entries ?? [];

  /// Returns today's 3-letter day code
  static String _todayCode() {
    const codes = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return codes[DateTime.now().weekday];
  }

  // ══════════════════════════════════════════════
  // INIT / REFRESH
  // ══════════════════════════════════════════════

  Future<void> initOrRefresh(DeviceProvider deviceProvider) async {
    _deviceProvider = deviceProvider;
    _state = RoutineState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final types = ['good_morning', 'good_night', 'movie_time', 'away_mode'];
      final defaultNames = [
        'Good Morning Routine',
        'Good Night Routine',
        'Movie Time Routine',
        'Away Mode Routine',
      ];

      for (int i = 0; i < types.length; i++) {
        Routine? loaded = await _service.getRoutine(types[i], defaultNames[i]);
        loaded ??= Routine(
          id: '${types[i]}_routine_${DateTime.now().millisecondsSinceEpoch}',
          name: defaultNames[i],
          isEnabled: true,
          localKey: types[i],
        );
        if (loaded.localKey == null) {
          loaded = loaded.copyWith(localKey: types[i]);
        }
        _routines[types[i]] = loaded;
      }

      _state = RoutineState.loaded;
    } catch (e) {
      _state = RoutineState.error;
      _errorMessage = 'Failed to load routines: $e';
    } finally {
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════
  // ACTIVE ROUTINE & DAY SELECTION
  // ══════════════════════════════════════════════

  void setActiveRoutine(String routineId) {
    _activeRoutineId = routineId;
    notifyListeners();
  }

  void selectDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  // ══════════════════════════════════════════════
  // SCHEDULE ENTRY CRUD
  // ══════════════════════════════════════════════

  /// Add a new schedule entry for a specific day
  void addScheduleEntry(
    String day,
    ScheduleEntry entry, {
    DeviceProvider? deviceProvider,
  }) {
    if (routine == null) return;
    routine!.daySchedules.putIfAbsent(day, () => DaySchedule(day: day));
    routine!.daySchedules[day]!.entries.add(entry);
    _state = RoutineState.loaded;
    notifyListeners();
    _autoSave();
  }

  /// Update an existing schedule entry
  void updateScheduleEntry(String day, ScheduleEntry updated) {
    if (routine == null) return;
    final schedule = routine!.daySchedules[day];
    if (schedule == null) return;
    final idx = schedule.entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      schedule.entries[idx] = updated;
      notifyListeners();
      _autoSave();
    }
  }

  /// Remove a schedule entry
  void removeScheduleEntry(String day, String entryId) {
    if (routine == null) return;
    final schedule = routine!.daySchedules[day];
    if (schedule == null) return;
    schedule.entries.removeWhere((e) => e.id == entryId);
    notifyListeners();
    _autoSave();
  }

  /// Duplicate a schedule entry
  void duplicateScheduleEntry(String day, String entryId) {
    if (routine == null) return;
    final schedule = routine!.daySchedules[day];
    if (schedule == null) return;
    final source = schedule.entries.firstWhere(
      (e) => e.id == entryId,
      orElse: () => schedule.entries.first,
    );
    final clone = source.copyWith(
      id: '${day}_${source.deviceId}_${DateTime.now().millisecondsSinceEpoch}',
    );
    schedule.entries.add(clone);
    notifyListeners();
    _autoSave();
  }

  /// Toggle an entry's enabled state
  void toggleScheduleEntry(String day, String entryId, bool enabled) {
    if (routine == null) return;
    final schedule = routine!.daySchedules[day];
    if (schedule == null) return;
    final idx = schedule.entries.indexWhere((e) => e.id == entryId);
    if (idx != -1) {
      schedule.entries[idx].isEnabled = enabled;

      // Sync hardware immediately if routine is active and today matches
      if (routine!.isEnabled &&
          day == _todayCode() &&
          _deviceProvider != null) {
        _syncSingleEntryHardware(
          schedule.entries[idx],
          enabled && schedule.entries[idx].startAction == 'on',
          _deviceProvider,
        );
      }

      notifyListeners();
      _autoSave();
    }
  }

  /// Copy all entries from source day to selected target days
  void copyDayScheduleTo(String sourceDay, List<String> targetDays) {
    if (routine == null) return;
    final source = routine!.daySchedules[sourceDay];
    if (source == null || source.isEmpty) return;

    for (final targetDay in targetDays) {
      if (targetDay == sourceDay) continue;
      routine!.daySchedules[targetDay] = source.copyTo(targetDay);
    }
    notifyListeners();
    _autoSave();
  }

  // ══════════════════════════════════════════════
  // MASTER TOGGLE
  // ══════════════════════════════════════════════

  Future<Routine> _saveRoutineHelper(
    Routine targetRoutine,
    String routineType,
  ) async {
    final String key = targetRoutine.localKey ?? routineType;
    if (_savingRoutineKeys.contains(key)) {
      return targetRoutine;
    }

    _savingRoutineKeys.add(key);
    try {
      final saved = await _service.saveRoutine(targetRoutine, routineType);
      if (kDebugMode) {
        debugPrint(
          '[RoutineProvider] persisted backend automation id ${saved.id}',
        );
      }
      return saved;
    } finally {
      _savingRoutineKeys.remove(key);
    }
  }

  Future<void> toggleRoutineEnabled(
    bool isEnabled, {
    DeviceProvider? deviceProvider,
  }) async {
    if (routine == null) return;
    routine!.isEnabled = isEnabled;
    notifyListeners();

    try {
      // 1. Save and toggle first to ensure backend has the latest configured devices
      final saved = await _saveRoutineHelper(routine!, _activeRoutineId);
      _routines[_activeRoutineId] = saved;
      notifyListeners();

      await _service.toggleRoutine(saved.id, isEnabled, _activeRoutineId);

      final dp = deviceProvider ?? _deviceProvider;

      if (isEnabled && dp != null) {
        // Fallback to local execution as routing automations to scene activation is removed
        await _executeRoutineHardware(dp);
      } else if (dp != null) {
        // Turn OFF locally since there's no deactivated scene endpoint
        await _turnOffAllDevicesHardware(dp);
      }
    } catch (e) {
      debugPrint('[RoutineProvider] Toggle error: $e');
    }
  }

  // ══════════════════════════════════════════════
  // SAVE
  // ══════════════════════════════════════════════

  Future<bool> saveRoutine() async {
    if (routine == null) return false;

    _state = RoutineState.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final saved = await _saveRoutineHelper(routine!, _activeRoutineId);
      _routines[_activeRoutineId] = saved;
      _state = RoutineState.success;
      notifyListeners();

      // Reset to loaded after short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (_state == RoutineState.success) {
          _state = RoutineState.loaded;
          notifyListeners();
        }
      });
      return true;
    } catch (e) {
      _state = RoutineState.error;
      _errorMessage = 'Failed to save: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _autoSave() async {
    if (routine == null) return;
    try {
      final saved = await _saveRoutineHelper(routine!, _activeRoutineId);
      _routines[_activeRoutineId] = saved;
      notifyListeners();
    } catch (e) {
      debugPrint('[RoutineProvider] Auto-save error: $e');
    }
  }

  // ══════════════════════════════════════════════
  // HARDWARE SYNC HELPERS
  // ══════════════════════════════════════════════

  Future<void> _syncSingleEntryHardware(
    ScheduleEntry entry,
    bool turnOn, [
    DeviceProvider? dpParam,
  ]) async {
    final dp = dpParam ?? _deviceProvider;
    if (dp == null) return;
    final device = _findOrCreateDevice(dp, entry);
    final success = await dp.setDevicePower(device, turnOn);
    if (success && turnOn && entry.deviceType == DeviceType.light) {
      // Wait a tiny bit before sending dim command to let the device process the power command
      await Future.delayed(const Duration(milliseconds: 300));
      await dp.setDimLevel(device, entry.brightness.toDouble());
    }
  }

  Future<void> _turnOffAllDevicesHardware(DeviceProvider dp) async {
    if (routine == null) return;
    // Collect all unique device IDs across all days
    final seen = <String>{};
    for (final ds in routine!.daySchedules.values) {
      for (final entry in ds.entries) {
        if (entry.isEnabled && seen.add(entry.deviceId)) {
          await _syncSingleEntryHardware(entry, false, dp);
        }
      }
    }
  }

  Future<void> _executeRoutineHardware(DeviceProvider dp) async {
    if (routine == null) return;

    final seen = <String>{};
    final today = _todayCode();

    // Helper to process entries sequentially to avoid API rate limits
    Future<void> processEntries(Iterable<ScheduleEntry> entries) async {
      for (final entry in entries) {
        if (entry.isEnabled && seen.add(entry.deviceId)) {
          final isTurnOn = entry.startAction == 'on';
          await _syncSingleEntryHardware(entry, isTurnOn, dp);
        }
      }
    }

    // 1. Prefer today's schedule if available
    if (routine!.daySchedules[today] != null) {
      await processEntries(routine!.daySchedules[today]!.entries);
    }

    // 2. Fallback to other days for any devices not scheduled for today
    for (final ds in routine!.daySchedules.values) {
      if (ds.day != today) {
        await processEntries(ds.entries);
      }
    }
  }

  Device _findOrCreateDevice(DeviceProvider dp, ScheduleEntry entry) {
    return dp.devices.firstWhere(
      (d) => d.deviceId == entry.deviceId,
      orElse: () => Device(
        deviceId: entry.deviceId,
        type: entry.deviceType,
        name: entry.deviceName,
        firmwareVersion: '1.0',
        macAddress: '00:00:00:00',
        tenantId: 't1',
        buildingId: 'b1',
        zone: entry.roomName,
        status: DeviceStatus.online,
        isOn: false,
        lastHeartbeat: DateTime.now(),
        configThresholds: {},
      ),
    );
  }

  // ══════════════════════════════════════════════
  // AVAILABLE DEVICES (for Add Device picker)
  // ══════════════════════════════════════════════

  /// Returns all devices from DeviceProvider
  List<Device> get availableDevices {
    return _deviceProvider?.devices
            .where((d) => d.type.isControllable)
            .toList() ??
        [];
  }

  // ══════════════════════════════════════════════
  // SCHEDULER ENGINE (Multi-Routine)
  // ══════════════════════════════════════════════

  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkScheduleTrigger();
    });
  }

  void _checkScheduleTrigger() {
    if (_routines.isEmpty) return;
    final dp = _deviceProvider;
    if (dp == null) return;

    final now = DateTime.now();
    final currentDay = _todayCode();
    final currentMinutes = now.hour * 60 + now.minute;
    final todayKey = '${now.year}-${now.month}-${now.day}';

    for (final MapEntry<String, Routine> r in _routines.entries) {
      final routineType = r.key;
      final rt = r.value;

      if (!rt.isEnabled) continue;

      final schedule = rt.daySchedules[currentDay];
      if (schedule == null || schedule.isEmpty) continue;

      for (final entry in schedule.entries) {
        if (!entry.isEnabled) continue;

        // Check ON time
        final onMin = _parseTimeToMinutes(entry.onTime);
        if (onMin != null && currentMinutes == onMin) {
          final key = '$todayKey-$routineType-${entry.id}-ON';
          if (!_triggeredKeys.contains(key)) {
            _triggeredKeys.add(key);
            _executeTriggerOn(entry, dp);
          }
        }

        // Check OFF time
        final offMin = _parseTimeToMinutes(entry.offTime);
        if (offMin != null && currentMinutes == offMin) {
          final key = '$todayKey-$routineType-${entry.id}-OFF';
          if (!_triggeredKeys.contains(key)) {
            _triggeredKeys.add(key);
            _executeTriggerOff(entry, dp);
          }
        }
      }
    }

    // Bound set size
    if (_triggeredKeys.length > 500) {
      _triggeredKeys.removeWhere((k) => !k.startsWith(todayKey));
    }
  }

  void _executeTriggerOn(ScheduleEntry entry, DeviceProvider dp) {
    debugPrint('[Scheduler] ⏰ ON: ${entry.deviceName} at ${entry.onTime}');
    _syncSingleEntryHardware(entry, true, dp);
    notifyListeners();
  }

  void _executeTriggerOff(ScheduleEntry entry, DeviceProvider dp) {
    debugPrint('[Scheduler] ⏰ OFF: ${entry.deviceName} at ${entry.offTime}');
    _syncSingleEntryHardware(entry, false, dp);
    notifyListeners();
  }

  int? _parseTimeToMinutes(String timeStr) {
    try {
      final trimmed = timeStr.trim().toUpperCase();
      final isPM = trimmed.contains('PM');
      final isAM = trimmed.contains('AM');
      final clean = trimmed.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = clean.split(':');
      if (parts.length < 2) return null;
      int hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    super.dispose();
  }
}
