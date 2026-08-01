import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/automation_rule.dart';
import '../../providers/automation_provider.dart';
import '../../theme/app_theme.dart';

class AutomationsScreen extends StatelessWidget {
  const AutomationsScreen({super.key});

  Future<void> _addAutomation(BuildContext context) async {
    final result = await showModalBottomSheet<_AutomationDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AutomationForm(),
    );
    if (result == null || !context.mounted) return;
    context.read<AutomationProvider>().addRule(
      AutomationRule(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: result.name,
        trigger: result.trigger,
        action: result.action,
        repeat: result.repeat,
        scene: result.scene,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Automations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAutomation(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New automation'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _AutomationHero(
                  active: provider.enabledCount,
                  total: provider.rules.length,
                ),
                const SizedBox(height: 22),
                const Text(
                  'UPCOMING & ACTIVE',
                  style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 11.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (provider.rules.isEmpty)
                  _EmptyAutomation(onAdd: () => _addAutomation(context))
                else
                  ...provider.rules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _AutomationCard(rule: rule),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AutomationHero extends StatelessWidget {
  final int active;
  final int total;

  const _AutomationHero({required this.active, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sideBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart routines',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$active of $total automations are active',
                  style: const TextStyle(
                    color: AppColors.sideText,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: AppColors.warning),
        ],
      ),
    );
  }
}

class _AutomationCard extends StatelessWidget {
  final AutomationRule rule;

  const _AutomationCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final color = _sceneColor(rule.scene);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_sceneIcon(rule.scene), color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rule.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Switch(
                        value: rule.enabled,
                        onChanged: (value) =>
                            context.read<AutomationProvider>().toggleRule(rule),
                      ),
                    ],
                  ),
                  Text(
                    '${rule.trigger} · ${rule.repeat}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    rule.action,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          '${rule.scene} scene',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Delete automation',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context
                            .read<AutomationProvider>()
                            .deleteRule(rule.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.textFaint,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _sceneIcon(String scene) {
    switch (scene) {
      case 'Morning':
        return Icons.wb_sunny_outlined;
      case 'Night':
        return Icons.nightlight_outlined;
      case 'Away':
        return Icons.shield_outlined;
      default:
        return Icons.tune_rounded;
    }
  }

  static Color _sceneColor(String scene) {
    switch (scene) {
      case 'Morning':
        return AppColors.warning;
      case 'Night':
        return AppColors.accentTeal;
      case 'Away':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.primary;
    }
  }
}

class _EmptyAutomation extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyAutomation({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: AppColors.textFaint,
            ),
            const SizedBox(height: 12),
            const Text(
              'No automations yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a schedule, timer, or scene for your devices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAdd, child: const Text('Create one')),
          ],
        ),
      ),
    );
  }
}

class _AutomationForm extends StatefulWidget {
  const _AutomationForm();

  @override
  State<_AutomationForm> createState() => _AutomationFormState();
}

class _AutomationFormState extends State<_AutomationForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _action = TextEditingController();
  String _trigger = '08:00';
  String _repeat = 'Daily';
  String _scene = 'Custom';

  @override
  void dispose() {
    _name.dispose();
    _action.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _trigger =
          '${selected.hour.toString().padLeft(2, '0')}:'
          '${selected.minute.toString().padLeft(2, '0')}';
    });
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      _AutomationDraft(
        name: _name.text,
        trigger: _trigger,
        action: _action.text,
        repeat: _repeat,
        scene: _scene,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New automation',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose when it runs and what it should do.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Automation name',
                  hintText: 'e.g. Weekday wake-up',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 2 ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start time',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  child: Text(_trigger),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _repeat,
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
                items: const ['Daily', 'Weekdays', 'Weekends', 'Custom']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _repeat = value ?? _repeat),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _scene,
                decoration: const InputDecoration(
                  labelText: 'Scene',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                ),
                items: const ['Morning', 'Night', 'Away', 'Custom']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _scene = value ?? _scene),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _action,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Actions',
                  hintText: 'Turn on hallway lights and set brightness to 40%',
                  prefixIcon: Icon(Icons.bolt_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.trim().length ?? 0) < 4
                    ? 'Describe the action'
                    : null,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create automation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutomationDraft {
  final String name;
  final String trigger;
  final String action;
  final String repeat;
  final String scene;

  const _AutomationDraft({
    required this.name,
    required this.trigger,
    required this.action,
    required this.repeat,
    required this.scene,
  });
}
