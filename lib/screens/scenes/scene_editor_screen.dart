import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device.dart';
import '../../models/scene_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/scene_provider.dart';

class SceneEditorScreen extends StatefulWidget {
  final SceneModel? scene;

  const SceneEditorScreen({super.key, this.scene});

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _DeviceDraft {
  bool included;
  bool isOn;
  double brightness;
  double speed;
  double position;
  double temp;

  _DeviceDraft({
    this.included = false,
    bool? isOn,
    double? brightness,
    double? speed,
    double? position,
    double? temp,
  }) : isOn = isOn ?? true,
       brightness = brightness ?? 70,
       speed = speed ?? 2,
       position = position ?? 0,
       temp = temp ?? 22;

  _DeviceDraft clone() => _DeviceDraft(
    included: included,
    isOn: isOn,
    brightness: brightness,
    speed: speed,
    position: position,
    temp: temp,
  );
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late bool _isFavorite;
  late String _trigger; // 'manual' or 'scheduled'
  late String _scheduledTime; // "HH:mm"
  late Set<int> _selectedDayIndices; // 0..6 for Mon..Sun

  final Map<String, _DeviceDraft> _deviceDrafts = {};

  bool _isDeleting = false;

  static const List<Map<String, dynamic>> _icons = [
    {'id': 'moon', 'icon': Icons.nightlight_round},
    {'id': 'sun', 'icon': Icons.wb_sunny_rounded},
    {'id': 'film', 'icon': Icons.movie_rounded},
    {'id': 'coffee', 'icon': Icons.local_cafe_rounded},
    {'id': 'briefcase', 'icon': Icons.work_rounded},
    {'id': 'bed', 'icon': Icons.bed_rounded},
    {'id': 'home', 'icon': Icons.home_rounded},
  ];

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final existing = widget.scene;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _selectedIcon = existing?.icon ?? 'moon';
    _isFavorite = existing?.isFavorite ?? false;
    _trigger = (existing?.isScheduleEnabled == true) ? 'scheduled' : 'manual';
    _scheduledTime = existing?.scheduledTime ?? '19:30';

    _selectedDayIndices = {};
    if (existing != null && existing.recurrenceDays > 0) {
      for (int i = 0; i < 7; i++) {
        if ((existing.recurrenceDays & (1 << i)) != 0) {
          _selectedDayIndices.add(i);
        }
      }
    } else {
      _selectedDayIndices = {0, 1, 2, 3, 4, 5, 6};
    }

    _initDeviceDrafts();

    _nameController.addListener(() {
      setState(() {});
    });
  }

  void _initDeviceDrafts() {
    final existing = widget.scene;
    if (existing != null && existing.actions.isNotEmpty) {
      for (final action in existing.actions) {
        final d = _DeviceDraft(included: true);
        final cmd = action.command.toLowerCase();
        if (cmd == 'on') {
          d.isOn = true;
        } else if (cmd == 'off') {
          d.isOn = false;
        } else if (cmd == 'brightness') {
          d.isOn = true;
          final val = num.tryParse(action.commandValue?.toString() ?? '70');
          if (val != null) d.brightness = val.toDouble().clamp(1, 100);
        } else if (cmd == 'speed') {
          d.isOn = true;
          final val = num.tryParse(action.commandValue?.toString() ?? '2');
          if (val != null) d.speed = val.toDouble().clamp(1, 5);
        } else if (cmd == 'position') {
          final val = num.tryParse(action.commandValue?.toString() ?? '0');
          if (val != null) d.position = val.toDouble().clamp(0, 100);
        } else if (cmd == 'temp' || cmd == 'temperature') {
          d.isOn = true;
          final val = num.tryParse(action.commandValue?.toString() ?? '22');
          if (val != null) d.temp = val.toDouble().clamp(16, 30);
        }
        _deviceDrafts[action.deviceId] = d;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _includedCount {
    return _deviceDrafts.values.where((d) => d.included).length;
  }

  bool get _isValid {
    return _nameController.text.trim().isNotEmpty && _includedCount > 0;
  }

  bool get _hasChanges {
    final existing = widget.scene;
    if (existing == null) {
      return _nameController.text.trim().isNotEmpty || _includedCount > 0;
    }
    return _nameController.text.trim() != existing.name ||
        _selectedIcon != (existing.icon ?? 'moon') ||
        _isFavorite != existing.isFavorite;
  }

  IconData _getIconData(String iconId) {
    return _icons.firstWhere(
          (item) => item['id'] == iconId,
          orElse: () => _icons[0],
        )['icon']
        as IconData;
  }

  String? _getClientId() {
    final auth = context.read<AuthProvider>();
    final property = context.read<PropertyProvider>();
    final id = property.clientId ?? auth.resolvedClientUuid;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  int _calculateRecurrenceDaysBitmask() {
    int mask = 0;
    for (final index in _selectedDayIndices) {
      mask |= (1 << index);
    }
    return mask;
  }

  List<SceneActionModel> _buildSceneActions() {
    final List<SceneActionModel> actions = [];
    int sortOrder = 0;

    _deviceDrafts.forEach((deviceId, draft) {
      if (!draft.included) return;

      if (!draft.isOn) {
        actions.add(
          SceneActionModel(
            deviceId: deviceId,
            command: 'off',
            commandValue: null,
            sortOrder: sortOrder++,
          ),
        );
      } else {
        actions.add(
          SceneActionModel(
            deviceId: deviceId,
            command: 'on',
            commandValue: null,
            sortOrder: sortOrder++,
          ),
        );
        if (draft.brightness != 70) {
          actions.add(
            SceneActionModel(
              deviceId: deviceId,
              command: 'brightness',
              commandValue: draft.brightness.toInt(),
              sortOrder: sortOrder++,
            ),
          );
        }
      }
    });

    return actions;
  }

  Future<void> _saveScene() async {
    if (!_isValid) return;

    final clientId = _getClientId();
    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine active client.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final actions = _buildSceneActions();
    final isSchedule = _trigger == 'scheduled';
    final recurrenceDays = isSchedule ? _calculateRecurrenceDaysBitmask() : 0;
    final scheduledTime = isSchedule ? _scheduledTime : null;
    final tzOffset = DateTime.now().timeZoneOffset.inMinutes;

    final provider = context.read<SceneProvider>();

    SceneModel? result;
    if (widget.scene == null) {
      result = await provider.createScene(
        clientId,
        name: name,
        icon: _selectedIcon,
        isFavorite: _isFavorite,
        actions: actions,
        isScheduleEnabled: isSchedule,
        scheduledTime: scheduledTime,
        recurrenceDays: recurrenceDays,
        timezoneOffsetMinutes: tzOffset,
      );
    } else {
      result = await provider.updateScene(
        clientId,
        sceneId: widget.scene!.id,
        name: name,
        icon: _selectedIcon,
        isFavorite: _isFavorite,
        actions: actions,
        isScheduleEnabled: isSchedule,
        scheduledTime: scheduledTime,
        recurrenceDays: recurrenceDays,
        timezoneOffsetMinutes: tzOffset,
      );
    }

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.scene == null
                ? 'Scene created successfully'
                : 'Scene updated successfully',
          ),
          backgroundColor: const Color(0xFF00897B),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save scene'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final scene = widget.scene;
    if (scene == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scene?'),
        content: Text('Are you sure you want to delete “${scene.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final clientId = _getClientId();
    setState(() => _isDeleting = true);
    final provider = context.read<SceneProvider>();
    final success = await provider.deleteScene(clientId, scene.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“${scene.name}” deleted successfully'),
          backgroundColor: const Color(0xFF00897B),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to delete scene'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Map<String, List<Device>> _groupDevicesByRoom(List<Device> devices) {
    final Map<String, List<Device>> grouped = {};
    for (final device in devices) {
      final room = (device.roomName?.isNotEmpty == true)
          ? device.roomName!
          : (device.zone.isNotEmpty == true ? device.zone : 'General Room');
      grouped.putIfAbsent(room, () => []).add(device);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deviceProvider = context.watch<DeviceProvider>();
    final controllableDevices = deviceProvider.controllableDevices.isNotEmpty
        ? deviceProvider.controllableDevices
        : deviceProvider.devices;

    final groupedDevices = _groupDevicesByRoom(controllableDevices);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasChanges) {
          Navigator.of(context).pop();
          return;
        }

        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes that will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Discard'),
              ),
            ],
          ),
        );

        if (discard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SCENE SETUP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                widget.scene == null ? 'Create Scene' : 'Edit Scene',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: [
            if (widget.scene != null)
              IconButton(
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                onPressed: _isDeleting ? null : _confirmDelete,
                tooltip: 'Delete Scene',
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Identity
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            _getIconData(_selectedIcon),
                            color: colorScheme.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            maxLength: 28,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Name this scene',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              counterText: '',
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: colorScheme.outline,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Horizontal Icon Picker
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _icons.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = _icons[index];
                          final id = item['id'] as String;
                          final isSelected = _selectedIcon == id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIcon = id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 20,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Choose Devices Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Choose devices',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$_includedCount selected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Turn on only the devices this scene should control. Their settings appear automatically.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (groupedDevices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          'No devices found in home.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ...groupedDevices.entries.expand((entry) {
                        final roomName = entry.key;
                        final roomDevices = entry.value;
                        return [
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 6),
                            child: Text(
                              roomName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          ...roomDevices.map(
                            (device) => _buildDeviceCard(device),
                          ),
                        ];
                      }),

                    const SizedBox(height: 24),

                    // 3. Trigger Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'When should it run?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _trigger = 'manual'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _trigger == 'manual'
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surface,
                              side: BorderSide(
                                color: _trigger == 'manual'
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Manual tap',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _trigger == 'manual'
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _trigger = 'scheduled'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _trigger == 'scheduled'
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surface,
                              side: BorderSide(
                                color: _trigger == 'scheduled'
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Schedule',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _trigger == 'scheduled'
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_trigger == 'scheduled') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Run at',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final parts = _scheduledTime.split(':');
                                    final initialHour = parts.isNotEmpty
                                        ? (int.tryParse(parts[0]) ?? 19)
                                        : 19;
                                    final initialMinute = parts.length > 1
                                        ? (int.tryParse(parts[1]) ?? 30)
                                        : 30;

                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: initialHour,
                                        minute: initialMinute,
                                      ),
                                    );

                                    if (picked != null) {
                                      final hh = picked.hour.toString().padLeft(
                                        2,
                                        '0',
                                      );
                                      final mm = picked.minute
                                          .toString()
                                          .padLeft(2, '0');
                                      setState(
                                        () => _scheduledTime = '$hh:$mm',
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _scheduledTime,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (index) {
                                final isSelected = _selectedDayIndices.contains(
                                  index,
                                );
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedDayIndices.remove(index);
                                      } else {
                                        _selectedDayIndices.add(index);
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primaryContainer
                                          : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _dayLabels[index],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 4. Quick Scenes Toggle Option
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add to Quick Scenes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Show this scene on your dashboard for one-tap access.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isFavorite,
                            activeTrackColor: colorScheme.primary,
                            onChanged: (val) =>
                                setState(() => _isFavorite = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Save Footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isValid ? _saveScene : null,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          widget.scene == null ? 'Save Scene' : 'Update Scene',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor:
                              colorScheme.surfaceContainerHighest,
                          disabledForegroundColor: colorScheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Enter a scene name'
                          : (_includedCount == 0
                                ? 'Choose at least one device'
                                : '${_nameController.text.trim()} · $_includedCount device${_includedCount == 1 ? '' : 's'}'),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final draft = _deviceDrafts.putIfAbsent(
      device.deviceId,
      () => _DeviceDraft(),
    );

    String summary = 'Not included';
    if (draft.included) {
      if (device.type == DeviceType.light) {
        summary = draft.isOn ? 'ON · ${draft.brightness.toInt()}%' : 'OFF';
      } else if (device.type == DeviceType.fan) {
        summary = draft.isOn ? 'ON · Speed ${draft.speed.toInt()}' : 'OFF';
      } else if (device.type == DeviceType.ac) {
        summary = draft.isOn ? 'ON · ${draft.temp.toInt()}°C' : 'OFF';
      } else {
        summary = draft.isOn ? 'ON' : 'OFF';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: draft.included
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: draft.included ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: draft.included
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getDeviceIcon(device.type),
                    size: 18,
                    color: draft.included
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: draft.included,
                  activeTrackColor: colorScheme.primary,
                  onChanged: (val) {
                    setState(() => draft.included = val);
                  },
                ),
              ],
            ),
          ),

          // Exposed Controls when included
          if (draft.included) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => draft.isOn = true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: draft.isOn
                                ? colorScheme.primaryContainer
                                : colorScheme.surface,
                            side: BorderSide(
                              color: draft.isOn
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Turn on',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: draft.isOn
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => draft.isOn = false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !draft.isOn
                                ? colorScheme.primaryContainer
                                : colorScheme.surface,
                            side: BorderSide(
                              color: !draft.isOn
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Turn off',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !draft.isOn
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (draft.isOn && device.type == DeviceType.light) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Brightness',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${draft.brightness.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: draft.brightness,
                      min: 1,
                      max: 100,
                      activeColor: colorScheme.primary,
                      onChanged: (val) =>
                          setState(() => draft.brightness = val),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return Icons.lightbulb_outline_rounded;
      case DeviceType.fan:
        return Icons.mode_fan_off_rounded;
      case DeviceType.ac:
        return Icons.ac_unit_rounded;
      case DeviceType.pump:
        return Icons.water_drop_rounded;
      default:
        return Icons.power_rounded;
    }
  }
}
