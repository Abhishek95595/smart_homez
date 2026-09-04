import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/requests/create_automation_request.dart';
import '../../models/automation_model.dart';
import '../../providers/automation_provider.dart';
import '../../providers/device_provider.dart';

class CreateAutomationScreen extends StatefulWidget {
  final AutomationModel? existingRule;

  const CreateAutomationScreen({super.key, this.existingRule});

  @override
  State<CreateAutomationScreen> createState() => _CreateAutomationScreenState();
}

class _AutomationActionItem {
  String deviceName;
  String deviceType; // 'light', 'fan', 'ac', 'tv', 'curtain', 'lock'
  String stateDisplay; // e.g. 'ON', 'Speed 3', '70%', 'Close'
  String? deviceId;

  _AutomationActionItem({
    required this.deviceName,
    required this.deviceType,
    required this.stateDisplay,
    this.deviceId,
  });
}

class _CreateAutomationScreenState extends State<CreateAutomationScreen> {
  late final TextEditingController _nameController;
  bool _isEnabled = true;
  String _selectedTrigger = 'Time';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

  final List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  late final Set<String> _selectedDays;

  final List<_AutomationActionItem> _actions = [];

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;

    _nameController = TextEditingController(
      text: rule?.name ?? (widget.existingRule == null ? 'Good Morning' : ''),
    );
    _isEnabled = rule?.isActive ?? true;

    _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};

    if (rule != null) {
      // Parse existing trigger & time
      for (final c in rule.conditions) {
        if (c.timeValue != null && c.timeValue!.contains(':')) {
          final parts = c.timeValue!.split(':');
          final h = int.tryParse(parts[0]) ?? 7;
          final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          _selectedTime = TimeOfDay(hour: h, minute: m);
          break;
        }
      }

      if (rule.actions.isNotEmpty) {
        for (final a in rule.actions) {
          final summary = a.commandValue ?? a.command ?? 'ON';
          _actions.add(
            _AutomationActionItem(
              deviceName: a.commandValue?.split(' ').first ?? 'Smart Device',
              deviceType: _deduceType(a.commandValue ?? a.command ?? ''),
              stateDisplay: summary,
              deviceId: a.targetDeviceId,
            ),
          );
        }
      }
    }

    if (_actions.isEmpty) {
      // Default demo actions matching reference image
      _actions.addAll([
        _AutomationActionItem(
          deviceName: 'Bedroom Light',
          deviceType: 'light',
          stateDisplay: 'ON',
        ),
        _AutomationActionItem(
          deviceName: 'Fan',
          deviceType: 'fan',
          stateDisplay: 'Speed 3',
        ),
        _AutomationActionItem(
          deviceName: 'Living Room Light',
          deviceType: 'lamp',
          stateDisplay: '70%',
        ),
      ]);
    }
  }

  static String _deduceType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('fan')) return 'fan';
    if (lower.contains('lamp') || lower.contains('living')) return 'lamp';
    if (lower.contains('tv')) return 'tv';
    if (lower.contains('lock')) return 'lock';
    if (lower.contains('curtain')) return 'curtain';
    return 'light';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourPadded = hour.toString().padLeft(2, '0');
    return '$hourPadded:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00897B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showTriggerSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Trigger Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _TriggerOptionTile(
              icon: Icons.access_time_rounded,
              title: 'Time Schedule',
              subtitle: 'Runs at a specific time on selected days',
              isSelected: _selectedTrigger == 'Time',
              onTap: () {
                setState(() => _selectedTrigger = 'Time');
                Navigator.pop(ctx);
              },
            ),
            _TriggerOptionTile(
              icon: Icons.sensors_rounded,
              title: 'Device or Sensor Change',
              subtitle: 'Runs when motion is detected or a door opens',
              isSelected: _selectedTrigger == 'Sensor',
              onTap: () {
                setState(() => _selectedTrigger = 'Sensor');
                Navigator.pop(ctx);
              },
            ),
            _TriggerOptionTile(
              icon: Icons.wb_sunny_outlined,
              title: 'Sunrise / Sunset',
              subtitle: 'Runs automatically at dusk or dawn',
              isSelected: _selectedTrigger == 'Sun',
              onTap: () {
                setState(() => _selectedTrigger = 'Sun');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addAction() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddActionModal(
        onAdd: (item) {
          setState(() => _actions.add(item));
        },
      ),
    );
  }

  void _editAction(int index) {
    final item = _actions[index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddActionModal(
        initialItem: item,
        onAdd: (updated) {
          setState(() => _actions[index] = updated);
        },
      ),
    );
  }

  Future<void> _saveAutomation() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an automation name.')),
      );
      return;
    }

    final actionSummaries = _actions
        .map((a) => '${a.deviceName} ${a.stateDisplay}')
        .join(', ');
    final hourFormatted = _selectedTime.hour.toString().padLeft(2, '0');
    final minuteFormatted = _selectedTime.minute.toString().padLeft(2, '0');
    final timeString = '$hourFormatted:$minuteFormatted';

    final provider = context.read<AutomationProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final conditions = [
      CreateAutomationConditionRequest(
        conditionType: _selectedTrigger,
        timeValue: timeString,
        propertyName: _selectedDays.join(','),
      ),
    ];

    if (widget.existingRule != null) {
      await provider.updateRule(
        automationId: widget.existingRule!.id,
        request: CreateAutomationRequest(
          name: name,
          description: actionSummaries,
          isActive: _isEnabled,
          conditions: conditions,
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Schedule updated successfully.')),
      );
    } else {
      await provider.addRule(
        CreateAutomationRequest(
          name: name,
          description: actionSummaries,
          isActive: _isEnabled,
          conditions: conditions,
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Schedule created successfully.')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFD),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: Color(0xFF0F172A),
                    ),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.existingRule != null
                            ? 'Edit Schedule'
                            : 'Create Schedule',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance back button
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  // 1. Automation Name Card
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            _IconContainer(icon: Icons.local_offer_outlined),
                            SizedBox(width: 12),
                            Text(
                              'Schedule Name',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter automation name',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14.5,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Enable Automation Card
                  _SectionCard(
                    child: Row(
                      children: [
                        const _IconContainer(icon: Icons.shield_outlined),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Enable Schedule',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isEnabled = !_isEnabled),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 48,
                            height: 28,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _isEnabled
                                  ? const Color(0xFF00897B)
                                  : const Color(0xFFCBD5E1),
                            ),
                            alignment: _isEnabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x24000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Trigger Selector Card
                  _SectionCard(
                    onTap: _showTriggerSelector,
                    child: Row(
                      children: [
                        const _IconContainer(icon: Icons.play_arrow_outlined),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Trigger',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          _selectedTrigger,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Time Selector Card
                  _SectionCard(
                    onTap: _pickTime,
                    child: Row(
                      children: [
                        const _IconContainer(icon: Icons.access_time_rounded),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(_selectedTime),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Repeat Days Card
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            _IconContainer(icon: Icons.calendar_today_outlined),
                            SizedBox(width: 12),
                            Text(
                              'Repeat Days',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _allDays.map((day) {
                            final isSelected = _selectedDays.contains(day);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    if (_selectedDays.length > 1) {
                                      _selectedDays.remove(day);
                                    }
                                  } else {
                                    _selectedDays.add(day);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00897B)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00897B)
                                        : const Color(0xFFE2E8F0),
                                    width: 1.1,
                                  ),
                                ),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Actions Section Card
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            _IconContainer(icon: Icons.bolt_rounded),
                            SizedBox(width: 12),
                            Text(
                              'Actions',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // List of Actions
                        ..._actions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final action = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Row(
                              children: [
                                _ActionTypeIcon(type: action.deviceType),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    action.deviceName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _editAction(index),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        action.stateDisplay,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.reorder_rounded,
                                  size: 20,
                                  color: Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 4),

                        // + Add Action Button
                        GestureDetector(
                          onTap: _addAction,
                          child: Container(
                            height: 46,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF00897B),
                                style: BorderStyle.solid,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFF00897B),
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Add Action',
                                  style: TextStyle(
                                    color: Color(0xFF00897B),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 7. Bottom Sticky Save Automation Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saveAutomation,
                  child: const Text(
                    'Save Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// REUSABLE CARD CONTAINER
// ══════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SectionCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ══════════════════════════════════════════════
// SECTION ICON BOX
// ══════════════════════════════════════════════

class _IconContainer extends StatelessWidget {
  final IconData icon;

  const _IconContainer({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF00897B), size: 22),
    );
  }
}

// ══════════════════════════════════════════════
// ACTION TYPE ICON
// ══════════════════════════════════════════════

class _ActionTypeIcon extends StatelessWidget {
  final String type;

  const _ActionTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFFFFBEB);
    Color iconColor = const Color(0xFFF59E0B);
    IconData icon = Icons.lightbulb_outline_rounded;

    if (type == 'fan') {
      bg = const Color(0xFFE6F7F5);
      iconColor = const Color(0xFF00897B);
      icon = Icons.toys_outlined;
    } else if (type == 'lamp') {
      bg = const Color(0xFFF3E8FF);
      iconColor = const Color(0xFF7C3AED);
      icon = Icons.tungsten_rounded;
    } else if (type == 'tv') {
      bg = const Color(0xFFEDE9FE);
      iconColor = const Color(0xFF6D28D9);
      icon = Icons.tv_rounded;
    } else if (type == 'curtain') {
      bg = const Color(0xFFDBEAFE);
      iconColor = const Color(0xFF2563EB);
      icon = Icons.curtains_rounded;
    } else if (type == 'lock') {
      bg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.lock_outline_rounded;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}

// ══════════════════════════════════════════════
// TRIGGER OPTION TILE
// ══════════════════════════════════════════════

class _TriggerOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TriggerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F7F5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF00897B) : const Color(0xFF64748B),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00897B))
          : null,
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════════
// ADD / EDIT ACTION MODAL
// ══════════════════════════════════════════════

class _AddActionModal extends StatefulWidget {
  final _AutomationActionItem? initialItem;
  final ValueChanged<_AutomationActionItem> onAdd;

  const _AddActionModal({this.initialItem, required this.onAdd});

  @override
  State<_AddActionModal> createState() => _AddActionModalState();
}

class _AddActionModalState extends State<_AddActionModal> {
  late final TextEditingController _deviceNameController;
  String _selectedType = 'light';
  String _selectedState = 'ON';

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(
      text: widget.initialItem?.deviceName ?? 'Living Room Light',
    );
    if (widget.initialItem != null) {
      _selectedType = widget.initialItem!.deviceType;
      _selectedState = widget.initialItem!.stateDisplay;
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _deviceNameController.text.trim();
    if (name.isEmpty) return;

    widget.onAdd(
      _AutomationActionItem(
        deviceName: name,
        deviceType: _selectedType,
        stateDisplay: _selectedState,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>().devices;

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.initialItem != null
                  ? 'Edit Device Action'
                  : 'Add Device Action',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Device',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            if (devices.isNotEmpty)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value:
                        devices.any((d) => d.name == _deviceNameController.text)
                        ? _deviceNameController.text
                        : devices.first.name,
                    items: devices.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.name,
                        child: Text(
                          d.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _deviceNameController.text = val;
                          _selectedType =
                              _CreateAutomationScreenState._deduceType(val);
                        });
                      }
                    },
                  ),
                ),
              )
            else
              TextField(
                controller: _deviceNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Living Room Light, Bedroom AC',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'Target State / Command',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'ON',
                    'OFF',
                    'Speed 1',
                    'Speed 2',
                    'Speed 3',
                    '50%',
                    '70%',
                    '100%',
                    'Close',
                    'Open',
                    'Lock',
                  ].map((state) {
                    final isSelected = _selectedState == state;
                    return ChoiceChip(
                      label: Text(state),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00897B),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedState = state);
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  widget.initialItem != null ? 'Update Action' : 'Add Action',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
