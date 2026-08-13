import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device.dart';
import '../../models/routine_model.dart';
import '../../providers/device_provider.dart';
import '../../providers/routine_provider.dart';
import '../../theme/app_theme.dart';

const Map<String, String> _dayShortLabels = {
  'MON': 'Mon',
  'TUE': 'Tue',
  'WED': 'Wed',
  'THU': 'Thu',
  'FRI': 'Fri',
  'SAT': 'Sat',
  'SUN': 'Sun',
};

const Map<String, String> _dayLabels = {
  'MON': 'Monday',
  'TUE': 'Tuesday',
  'WED': 'Wednesday',
  'THU': 'Thursday',
  'FRI': 'Friday',
  'SAT': 'Saturday',
  'SUN': 'Sunday',
};

class RoutineThemeData {
  final String routineId;
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color primarySoft;
  final String imagePath;

  const RoutineThemeData({
    required this.routineId,
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.primarySoft,
    required this.imagePath,
  });
}

const Color _kTextDark = AppColors.textPrimary;
const Color _kTextMuted = AppColors.textSecondary;

class RoutineSceneScreen extends StatefulWidget {
  final RoutineThemeData themeData;

  const RoutineSceneScreen({super.key, required this.themeData});

  @override
  State<RoutineSceneScreen> createState() => _RoutineSceneScreenState();
}

class _RoutineSceneScreenState extends State<RoutineSceneScreen> {
  RoutineThemeData get theme => widget.themeData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().setActiveRoutine(widget.themeData.routineId);
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final dp = context.read<DeviceProvider>();
    final rp = context.read<RoutineProvider>();
    await rp.initOrRefresh(dp);
  }

  static TimeOfDay parseTime(String s) {
    try {
      final parts = s.trim().split(' ');
      final tp = parts[0].split(':');
      int h = int.parse(tp[0]);
      final m = int.parse(tp[1]);
      if (parts.length > 1) {
        final p = parts[1].toUpperCase();
        if (p == 'PM' && h < 12) h += 12;
        if (p == 'AM' && h == 12) h = 0;
      }
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  static String formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  void _openAddDevice(RoutineProvider rp, String day) {
    final devices = rp.availableDevices;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No controllable devices available',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditEntrySheet(
        theme: theme,
        day: day,
        availableDevices: devices,
        onSave: (entry) => rp.addScheduleEntry(day, entry),
      ),
    );
  }

  void _openEditEntry(RoutineProvider rp, String day, ScheduleEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditEntrySheet(
        theme: theme,
        day: day,
        existingEntry: entry,
        availableDevices: rp.availableDevices,
        onSave: (updated) => rp.updateScheduleEntry(day, updated),
      ),
    );
  }

  void _openCopyDay(RoutineProvider rp, String sourceDay) {
    showDialog(
      context: context,
      builder: (_) => _CopyDayDialog(
        theme: theme,
        sourceDay: sourceDay,
        onCopy: (targets) => rp.copyDayScheduleTo(sourceDay, targets),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RoutineProvider>();
    final routine = rp.routine;
    final hasEntries = rp.selectedDayEntries.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFEFFFFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kTextDark, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          theme.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _kTextDark,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: rp.isLoading ? null : _refreshData,
            icon: rp.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: theme.gradientEnd,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: _kTextDark, size: 28),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDF8F6), Color(0xFFF7FCFC)],
          ),
        ),
        child: routine == null || rp.isLoading
            ? Center(
                child: CircularProgressIndicator(color: theme.gradientEnd),
              )
            : SafeArea(
                top: false,
                child: Stack(
                  children: [
                    ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, hasEntries ? 126 : 24),
                      children: [
                        _RoutineHeroCard(
                          theme: theme,
                          routine: routine,
                          onToggle: (val) async {
                            final dp = context.read<DeviceProvider>();
                            await rp.toggleRoutineEnabled(val, deviceProvider: dp);
                          },
                        ),
                        const SizedBox(height: 18),
                        _DaySelectorRow(
                          theme: theme,
                          selectedDay: rp.selectedDay,
                          daySchedules: routine.daySchedules,
                          onSelect: rp.selectDay,
                        ),
                        const SizedBox(height: 18),
                        if (!hasEntries) ...[
                          _DayHeaderBlock(day: rp.selectedDay),
                          const SizedBox(height: 12),
                          _EmptyRoutineStateCard(
                            theme: theme,
                            onAdd: () => _openAddDevice(rp, rp.selectedDay),
                            onSave: () async {
                              final success = await rp.saveRoutine();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success ? 'Routine saved successfully.' : 'Failed to save routine.',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  backgroundColor: success ? theme.gradientEnd : AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                            },
                            isSaving: rp.isSaving,
                          ),
                        ] else ...[
                          _SectionLabel(title: 'Actions'),
                          const SizedBox(height: 10),
                          _ActionsCard(
                            theme: theme,
                            entries: rp.selectedDayEntries,
                            onAddAction: () => _openAddDevice(rp, rp.selectedDay),
                            onEdit: (entry) => _openEditEntry(rp, rp.selectedDay, entry),
                            onToggle: (entry, value) => rp.toggleScheduleEntry(rp.selectedDay, entry.id, value),
                            onDuplicate: (entry) => rp.duplicateScheduleEntry(rp.selectedDay, entry.id),
                            onDelete: (entry) => rp.removeScheduleEntry(rp.selectedDay, entry.id),
                          ),
                          const SizedBox(height: 18),
                          _SectionLabel(title: 'Conditions'),
                          const SizedBox(height: 10),
                          _ConditionCard(
                            theme: theme,
                            selectedDay: rp.selectedDay,
                            routine: routine,
                            onTap: () => _openCopyDay(rp, rp.selectedDay),
                          ),
                        ],
                      ],
                    ),
                    if (hasEntries)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 12,
                        child: _FloatingBottomBar(
                          theme: theme,
                          onAddDevice: () => _openAddDevice(rp, rp.selectedDay),
                          onSave: () async {
                            final success = await rp.saveRoutine();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success ? 'Routine saved successfully.' : 'Failed to save routine.',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: success ? theme.gradientEnd : AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          },
                          isSaving: rp.isSaving,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RoutineHeroCard extends StatelessWidget {
  final RoutineThemeData theme;
  final Routine routine;
  final ValueChanged<bool> onToggle;

  const _RoutineHeroCard({
    required this.theme,
    required this.routine,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = routine.isEnabled;
    final badgeColor = theme.gradientEnd.withValues(alpha: 0.1);
    final showCompactStats = routine.configuredDeviceCount == 0 && routine.activeDays.isEmpty;
    final repeatText = routine.activeDays.length >= 7
        ? 'Every day'
        : routine.activeDays.isEmpty
            ? 'No schedule'
            : '${routine.activeDays.length} day${routine.activeDays.length == 1 ? '' : 's'} active';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.gradientEnd.withValues(alpha: 0.15),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(theme.imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _formatHeroTitle(routine.name),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 16),
          if (showCompactStats)
            Text(
              '${routine.configuredDeviceCount} devices  •  ${routine.activeDays.length} days active',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kTextMuted,
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text(
                  '${routine.configuredDeviceCount} device${routine.configuredDeviceCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
                _Dot(color: theme.gradientEnd),
                Text(
                  isOn ? 'Active' : 'Paused',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.gradientEnd,
                  ),
                ),
                _Dot(color: theme.gradientEnd),
                Text(
                  repeatText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: () => onToggle(!isOn),
            child: Container(
              height: 84,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                gradient: isOn
                    ? LinearGradient(
                        colors: [theme.gradientStart, theme.gradientEnd],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isOn ? null : const Color(0xFFE2EAEE),
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: theme.gradientEnd.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      isOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isOn ? Colors.white : _kTextMuted,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: isOn ? theme.gradientEnd : _kTextMuted,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelectorRow extends StatelessWidget {
  final RoutineThemeData theme;
  final String selectedDay;
  final Map<String, DaySchedule> daySchedules;
  final ValueChanged<String> onSelect;

  const _DaySelectorRow({
    required this.theme,
    required this.selectedDay,
    required this.daySchedules,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kAllDays.map((day) {
          final isSelected = day == selectedDay;
          final hasEntries = (daySchedules[day]?.entries.isNotEmpty ?? false);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onSelect(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 72,
                height: 62,
                decoration: BoxDecoration(
                  color: isSelected ? theme.primarySoft : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? theme.gradientEnd.withValues(alpha: 0.15)
                        : Colors.white,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayShortLabels[day] ?? day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? theme.gradientEnd : _kTextDark,
                        ),
                      ),
                      if (hasEntries) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? theme.gradientEnd : AppColors.textFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayHeaderBlock extends StatelessWidget {
  final String day;

  const _DayHeaderBlock({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nothing planned',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutineStateCard extends StatelessWidget {
  final RoutineThemeData theme;
  final VoidCallback onAdd;
  final VoidCallback onSave;
  final bool isSaving;

  const _EmptyRoutineStateCard({
    required this.theme,
    required this.onAdd,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primarySoft,
            ),
            child: Icon(Icons.notifications_off_rounded, color: theme.gradientEnd, size: 42),
          ),
          const SizedBox(height: 20),
          const Text(
            'Zero Routines',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You don’t have any routines scheduled for this day.\nCreate a routine to automate your devices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: _kTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF0F4F5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text(
                        'Add Device',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _kTextDark,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 22),
                      label: Text(
                        isSaving ? 'Saving...' : 'Save Routine',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.gradientEnd,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFB8E4DE))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '+  Add Rule',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.gradientEnd,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFB8E4DE))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final RoutineThemeData theme;
  final List<ScheduleEntry> entries;
  final VoidCallback onAddAction;
  final ValueChanged<ScheduleEntry> onEdit;
  final void Function(ScheduleEntry entry, bool value) onToggle;
  final ValueChanged<ScheduleEntry> onDuplicate;
  final ValueChanged<ScheduleEntry> onDelete;

  const _ActionsCard({
    required this.theme,
    required this.entries,
    required this.onAddAction,
    required this.onEdit,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: _cardDecoration,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primarySoft,
              ),
              child: Icon(Icons.auto_mode_rounded, color: theme.gradientEnd, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'No actions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your first routine action for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kTextMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAddAction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Action'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            _ActionTile(
              theme: theme,
              entry: entries[i],
              onTap: () => onEdit(entries[i]),
              onToggle: (value) => onToggle(entries[i], value),
              onDuplicate: () => onDuplicate(entries[i]),
              onDelete: () => onDelete(entries[i]),
            ),
            if (i != entries.length - 1)
              const Divider(height: 18, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );
}

class _ActionTile extends StatelessWidget {
  final RoutineThemeData theme;
  final ScheduleEntry entry;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ActionTile({
    required this.theme,
    required this.entry,
    required this.onTap,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: theme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForEntry(entry), color: theme.gradientEnd, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.deviceName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kTextDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleForEntry(entry),
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.onTime,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.gradientEnd,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textFaint),
                      onSelected: (val) {
                        if (val == 'dup') onDuplicate();
                        if (val == 'del') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'dup',
                          child: Text('Duplicate', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        PopupMenuItem<String>(
                          value: 'del',
                          child: Text('Delete', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: entry.isEnabled,
                      onChanged: onToggle,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final RoutineThemeData theme;
  final String selectedDay;
  final Routine routine;
  final VoidCallback? onTap;

  const _ConditionCard({
    required this.theme,
    required this.selectedDay,
    required this.routine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = routine.daySchedules[selectedDay];
    final entries = schedule?.entries ?? const <ScheduleEntry>[];
    final sortedTimes = entries
        .map<TimeOfDay>((e) => _RoutineSceneScreenState.parseTime(e.onTime))
        .toList()
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );

    final startText = sortedTimes.isEmpty
        ? 'Add an action to configure'
        : 'Starts at ${_RoutineSceneScreenState.formatTime(sortedTimes.first)}';

    final activeDays = routine.activeDays.isEmpty
        ? 'Only ${_dayLabels[selectedDay] ?? selectedDay}'
        : routine.activeDays.map((d) => _dayShortLabels[d] ?? d).join(', ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primarySoft,
                ),
                child: Icon(Icons.schedule_rounded, color: theme.gradientEnd, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start time',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kTextDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startText • $activeDays',
                      style: const TextStyle(fontSize: 14, color: _kTextMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: onTap == null ? AppColors.textFaint : AppColors.textSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatHeroTitle(String name) {
  final normalized = name.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.contains('ROUTINE')) {
    return normalized.replaceFirst(' ROUTINE', '\nROUTINE');
  }
  final words = normalized.split(' ');
  if (words.length <= 2) return '$normalized\nROUTINE';
  return '${words.take(words.length - 1).join(' ')}\n${words.last}';
}

IconData _iconForEntry(ScheduleEntry entry) {
  final name = entry.deviceName.toLowerCase();
  if (entry.deviceType == DeviceType.light || name.contains('light')) return Icons.lightbulb_rounded;
  if (name.contains('curtain') || name.contains('blind')) return Icons.blinds_rounded;
  if (name.contains('speaker')) return Icons.volume_up_rounded;
  if (entry.deviceType == DeviceType.fan) return Icons.mode_fan_off_rounded;
  if (entry.deviceType == DeviceType.ac) return Icons.ac_unit_rounded;
  return Icons.devices_rounded;
}

String _subtitleForEntry(ScheduleEntry entry) {
  final name = entry.deviceName.toLowerCase();
  if (entry.startAction == 'off') return 'Turn off';
  if (name.contains('curtain') || name.contains('blind')) return 'Open';
  if (name.contains('speaker')) return 'Play Morning Playlist';
  return 'Turn on';
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _AddEditEntrySheet extends StatefulWidget {
  final RoutineThemeData theme;
  final String day;
  final ScheduleEntry? existingEntry;
  final List<Device> availableDevices;
  final ValueChanged<ScheduleEntry> onSave;

  const _AddEditEntrySheet({
    required this.theme,
    required this.day,
    this.existingEntry,
    required this.availableDevices,
    required this.onSave,
  });

  @override
  State<_AddEditEntrySheet> createState() => _AddEditEntrySheetState();
}

class _AddEditEntrySheetState extends State<_AddEditEntrySheet> {
  Device? _selectedDevice;
  late String _onTime;
  late String _offTime;
  late String _startAction;
  late double _brightness;
  late int _fanSpeed;
  late int _targetTemp;
  late String _warmth;

  bool get isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    if (e != null) {
      _selectedDevice = widget.availableDevices.firstWhere(
        (d) => d.deviceId == e.deviceId,
        orElse: () => widget.availableDevices.first,
      );
      _onTime = e.onTime;
      _offTime = e.offTime;
      _startAction = e.startAction;
      _brightness = e.brightness.toDouble();
      _fanSpeed = e.fanSpeed;
      _targetTemp = e.targetTemp;
      _warmth = e.warmth;
    } else {
      _onTime = '07:00 AM';
      _offTime = '09:30 AM';
      _startAction = 'on';
      _brightness = 80;
      _fanSpeed = 3;
      _targetTemp = 24;
      _warmth = 'Warm 2700K';
    }
  }

  Future<void> _pickTime(bool isOn) async {
    final current = _RoutineSceneScreenState.parseTime(isOn ? _onTime : _offTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: widget.theme.gradientEnd),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOn) {
          _onTime = _RoutineSceneScreenState.formatTime(picked);
        } else {
          _offTime = _RoutineSceneScreenState.formatTime(picked);
        }
      });
    }
  }

  void _save() {
    if (_selectedDevice == null) return;
    final d = _selectedDevice!;
    final room = d.roomName ?? (d.zone.isNotEmpty ? d.zone : 'Living Room');
    final settings = <String, dynamic>{
      'brightness': _brightness.round(),
      'speed': _fanSpeed,
      'temperature': _targetTemp,
      'warmth': _warmth,
    };
    final entry = widget.existingEntry?.copyWith(
          deviceId: d.deviceId,
          deviceName: d.name,
          roomId: 'room_${room.toLowerCase().replaceAll(' ', '_')}',
          roomName: room,
          deviceType: d.type,
          onTime: _onTime,
          offTime: _offTime,
          startAction: _startAction,
          customSettings: settings,
        ) ??
        ScheduleEntry(
          id: '${widget.day}_${d.deviceId}_${DateTime.now().millisecondsSinceEpoch}',
          deviceId: d.deviceId,
          deviceName: d.name,
          roomId: 'room_${room.toLowerCase().replaceAll(' ', '_')}',
          roomName: room,
          deviceType: d.type,
          onTime: _onTime,
          offTime: _offTime,
          startAction: _startAction,
          customSettings: settings,
        );
    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _selectedDevice?.type == DeviceType.light;
    final isFan = _selectedDevice?.type == DeviceType.fan;
    final isAc = _selectedDevice?.type == DeviceType.ac;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isEditing ? 'UPDATE ACTION' : 'ADD ACTION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: widget.theme.gradientEnd,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_dayLabels[widget.day]} Schedule',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _kTextDark),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Device>(
                  value: _selectedDevice,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded, color: _kTextDark),
                  borderRadius: BorderRadius.circular(20),
                  hint: const Text(
                    'Pick a device...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextMuted),
                  ),
                  items: widget.availableDevices.map((d) {
                    final room = d.roomName ?? (d.zone.isNotEmpty ? d.zone : 'Room');
                    return DropdownMenuItem<Device>(
                      value: d,
                      child: Text(
                        '${d.name} • $room',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextDark),
                      ),
                    );
                  }).toList(),
                  onChanged: (d) => setState(() => _selectedDevice = d),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _buildActionPill('Power ON', true, _startAction == 'on', () => setState(() => _startAction = 'on')),
                const SizedBox(width: 12),
                _buildActionPill('Power OFF', false, _startAction == 'off', () => setState(() => _startAction = 'off')),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: _buildTimePickerTile('START', _onTime, widget.theme.gradientEnd, Icons.wb_sunny_rounded, () => _pickTime(true))),
                const SizedBox(width: 12),
                Expanded(child: _buildTimePickerTile('END', _offTime, AppColors.textSecondary, Icons.nights_stay_rounded, () => _pickTime(false))),
              ],
            ),
            const SizedBox(height: 28),
            if (_selectedDevice != null && _startAction == 'on') ...[
              if (isLight) ...[
                _buildSlider('Brightness', _brightness, '${_brightness.round()}%', 10, 100, 9, (v) => setState(() => _brightness = v)),
                const SizedBox(height: 22),
              ],
              if (isFan) ...[
                _buildSlider('Fan Speed', _fanSpeed.toDouble(), 'Lv $_fanSpeed', 1, 5, 4, (v) => setState(() => _fanSpeed = v.round())),
                const SizedBox(height: 22),
              ],
              if (isAc) ...[
                _buildSlider('Temperature', _targetTemp.toDouble(), '$_targetTemp°C', 18, 28, 10, (v) => setState(() => _targetTemp = v.round())),
                const SizedBox(height: 22),
              ],
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.gradientEnd,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Confirm Action',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill(String label, bool isOnAction, bool isSelected, VoidCallback onTap) {
    final color = isOnAction ? widget.theme.gradientEnd : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? (isOnAction ? widget.theme.primarySoft : AppColors.divider.withValues(alpha: 0.45)) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: 1.4),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected ? color : _kTextMuted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerTile(String label, String time, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kTextDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, String suffix, double min, double max, int div, ValueChanged<double> onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kTextDark)),
            Text(suffix, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: widget.theme.gradientEnd)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.theme.gradientEnd,
            inactiveTrackColor: const Color(0xFFF1F5F9),
            thumbColor: widget.theme.gradientEnd,
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayColor: widget.theme.gradientEnd.withValues(alpha: 0.18),
          ),
          child: Slider(value: value, min: min, max: max, divisions: div, onChanged: onChange),
        ),
      ],
    );
  }
}

class _CopyDayDialog extends StatefulWidget {
  final RoutineThemeData theme;
  final String sourceDay;
  final ValueChanged<List<String>> onCopy;

  const _CopyDayDialog({
    required this.theme,
    required this.sourceDay,
    required this.onCopy,
  });

  @override
  State<_CopyDayDialog> createState() => _CopyDayDialogState();
}

class _CopyDayDialogState extends State<_CopyDayDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final otherDays = kAllDays.where((d) => d != widget.sourceDay).toList();
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        'Clone ${_dayLabels[widget.sourceDay]}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kTextDark),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: otherDays.map((day) {
          final isSelected = _selected.contains(day);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              _dayLabels[day] ?? day,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextDark),
            ),
            value: isSelected,
            activeColor: widget.theme.gradientEnd,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selected.add(day);
                } else {
                  _selected.remove(day);
                }
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  widget.onCopy(_selected.toList());
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.gradientEnd,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Clone'),
        ),
      ],
    );
  }
}

class _FloatingBottomBar extends StatelessWidget {
  final RoutineThemeData theme;
  final VoidCallback onAddDevice;
  final VoidCallback onSave;
  final bool isSaving;

  const _FloatingBottomBar({
    required this.theme,
    required this.onAddDevice,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onAddDevice,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Add Action', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kTextDark,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 22),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Routine',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.gradientEnd,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
