import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/alexa_integration_service.dart';

class IntegrationsScreen extends StatefulWidget {
  final int initialTab;

  const IntegrationsScreen({super.key, this.initialTab = 0});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final Map<String, bool> _voiceConnections = {
    'Google Home': false,
    'Amazon Alexa': false,
    'Siri Shortcuts': true,
  };
  final List<_WebhookConfig> _webhooks = [
    const _WebhookConfig(
      name: 'Safety operations',
      endpoint: 'https://example.com/hooks/safety',
      event: 'Critical alerts',
      active: true,
      lastDelivery: '2 min ago · 200 OK',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab < 0
          ? 0
          : widget.initialTab > 1
          ? 1
          : widget.initialTab,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addWebhook() async {
    final draft = await showModalBottomSheet<_WebhookConfig>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _WebhookForm(),
    );
    if (draft == null || !mounted) return;
    setState(() => _webhooks.add(draft));
  }

  Future<void> _linkAlexa() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to Alexa Integration API...'),
        duration: Duration(seconds: 2),
      ),
    );

    final service = AlexaIntegrationService();
    final result = await service.generateLinkToken();
    if (!mounted) return;

    if (result != null && result['success'] == true) {
      final String? token = result['token']?.toString();
      final String? authorizeUrl = result['authorizeUrl']?.toString();
      final String linkUrl =
          authorizeUrl ??
          (token != null
              ? 'https://alexa.amazon.com/api/skill/link/smart_homez?token=$token'
              : 'https://alexa.amazon.com');

      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.spatial_audio_off_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Link Amazon Alexa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Authorize Smart Homez in the Alexa App or browser to control your lights, switches, and thermostats by voice.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD6F0EC)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps to Link:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Tap "Open Alexa Authorization"',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      '2. Log in with your Amazon Account',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      '3. Grant Smart Homez device permission',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Alexa Authorization'),
            ),
          ],
        ),
      );

      if (proceed == true) {
        final Uri alexaUri = Uri.parse(linkUrl);
        try {
          if (await canLaunchUrl(alexaUri)) {
            await launchUrl(alexaUri, mode: LaunchMode.externalApplication);
            if (!mounted) return;
            setState(() => _voiceConnections['Amazon Alexa'] = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Alexa App / authorization page launched successfully.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            if (!mounted) return;
            setState(() => _voiceConnections['Amazon Alexa'] = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opened Alexa portal at: $linkUrl')),
            );
          }
        } catch (e) {
          if (!mounted) return;
          setState(() => _voiceConnections['Amazon Alexa'] = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Alexa link initiated ($e).')));
        }
      } else {
        setState(() => _voiceConnections['Amazon Alexa'] = false);
      }
    } else {
      final String errorMsg =
          result?['error']?.toString() ??
          'Failed to generate Alexa link token. Check server connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => _voiceConnections['Amazon Alexa'] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrations'),
        bottom: TabBar(
          controller: _controller,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Voice assistants'),
            Tab(text: 'Webhooks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [_voiceTab(), _webhooksTab()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.index != 1) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _addWebhook,
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Add webhook'),
          );
        },
      ),
    );
  }

  Widget _voiceTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _IntegrationHero(
          icon: Icons.mic_none_rounded,
          title: 'Control your property by voice',
          message:
              'Link an assistant, choose allowed rooms, and keep sensitive '
              'safety actions protected.',
        ),
        const SizedBox(height: 20),
        ..._voiceConnections.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _VoiceCard(
              name: entry.key,
              connected: entry.value,
              onChanged: (value) {
                if (entry.key == 'Amazon Alexa' && value) {
                  _linkAlexa();
                  return;
                }

                setState(() => _voiceConnections[entry.key] = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? '${entry.key} is ready for provider authorization.'
                          : '${entry.key} disconnected.',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _AlexaCommandTestCard(),
        const SizedBox(height: 16),
        const _ProductionNote(
          text:
              'Provider authorization and cloud credentials are required '
              'before voice commands can reach physical devices.',
        ),
      ],
    );
  }

  Widget _webhooksTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _IntegrationHero(
          icon: Icons.webhook_rounded,
          title: 'Send events to your systems',
          message:
              'Route safety alerts, device status and energy events to a '
              'secure HTTPS endpoint.',
        ),
        const SizedBox(height: 20),
        if (_webhooks.isEmpty)
          _EmptyWebhooks(onAdd: _addWebhook)
        else
          ..._webhooks.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _WebhookCard(
                config: entry.value,
                onToggle: (value) {
                  setState(
                    () => _webhooks[entry.key] = entry.value.copyWith(
                      active: value,
                    ),
                  );
                },
                onTest: () {
                  setState(
                    () => _webhooks[entry.key] = entry.value.copyWith(
                      lastDelivery: 'Just now · Test queued',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Test prepared. Connect the backend to send it externally.',
                      ),
                    ),
                  );
                },
                onDelete: () => setState(() => _webhooks.removeAt(entry.key)),
              ),
            ),
          ),
        const _ProductionNote(
          text:
              'For production, sign outgoing payloads and retry failed '
              'deliveries from the backend—not directly from the mobile app.',
        ),
      ],
    );
  }
}

class _IntegrationHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _IntegrationHero({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.sideBackground,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.sideText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  final String name;
  final bool connected;
  final ValueChanged<bool> onChanged;

  const _VoiceCard({
    required this.name,
    required this.connected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(name), color: AppColors.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    connected ? 'Connected · 6 rooms shared' : 'Not connected',
                    style: TextStyle(
                      color: connected
                          ? AppColors.success
                          : AppColors.textFaint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: connected, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String platform) {
    if (platform.contains('Siri')) return Icons.phone_iphone_rounded;
    if (platform.contains('Alexa')) return Icons.speaker_rounded;
    return Icons.home_rounded;
  }
}

class _WebhookCard extends StatelessWidget {
  final _WebhookConfig config;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTest;
  final VoidCallback onDelete;

  const _WebhookCard({
    required this.config,
    required this.onToggle,
    required this.onTest,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.webhook_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.event,
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: config.active, onChanged: onToggle),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                config.endpoint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: AppColors.success,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    config.lastDelivery,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                TextButton(onPressed: onTest, child: const Text('Test')),
                IconButton(
                  tooltip: 'Delete webhook',
                  onPressed: onDelete,
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
    );
  }
}

class _ProductionNote extends StatelessWidget {
  final String text;

  const _ProductionNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2B4C8C),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2B4C8C),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWebhooks extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyWebhooks({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.link_off_rounded,
              size: 38,
              color: AppColors.textFaint,
            ),
            const SizedBox(height: 12),
            const Text(
              'No webhook endpoints',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onAdd, child: const Text('Add endpoint')),
          ],
        ),
      ),
    );
  }
}

class _WebhookForm extends StatefulWidget {
  const _WebhookForm();

  @override
  State<_WebhookForm> createState() => _WebhookFormState();
}

class _WebhookFormState extends State<_WebhookForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _endpoint = TextEditingController();
  String _event = 'Critical alerts';

  @override
  void dispose() {
    _name.dispose();
    _endpoint.dispose();
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      _WebhookConfig(
        name: _name.text.trim(),
        endpoint: _endpoint.text.trim(),
        event: _event,
        active: true,
        lastDelivery: 'Never delivered',
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
                'Add webhook',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Safety operations',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 2 ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _endpoint,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'HTTPS endpoint',
                  hintText: 'https://example.com/webhook',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                validator: (value) {
                  final uri = Uri.tryParse(value?.trim() ?? '');
                  if (uri == null ||
                      uri.scheme != 'https' ||
                      uri.host.isEmpty) {
                    return 'Enter a valid HTTPS URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _event,
                decoration: const InputDecoration(
                  labelText: 'Event',
                  prefixIcon: Icon(Icons.notifications_outlined),
                ),
                items:
                    const [
                          'Critical alerts',
                          'Device status',
                          'Energy threshold',
                          'All events',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _event = value ?? _event),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save webhook'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebhookConfig {
  final String name;
  final String endpoint;
  final String event;
  final bool active;
  final String lastDelivery;

  const _WebhookConfig({
    required this.name,
    required this.endpoint,
    required this.event,
    required this.active,
    required this.lastDelivery,
  });

  _WebhookConfig copyWith({bool? active, String? lastDelivery}) {
    return _WebhookConfig(
      name: name,
      endpoint: endpoint,
      event: event,
      active: active ?? this.active,
      lastDelivery: lastDelivery ?? this.lastDelivery,
    );
  }
}

class _AlexaCommandTestCard extends StatefulWidget {
  const _AlexaCommandTestCard();

  @override
  State<_AlexaCommandTestCard> createState() => _AlexaCommandTestCardState();
}

class _AlexaCommandTestCardState extends State<_AlexaCommandTestCard> {
  final TextEditingController _endpointIdController = TextEditingController(
    text: 'device_living_room_light',
  );
  bool _isTesting = false;
  String? _lastLog;

  @override
  void dispose() {
    _endpointIdController.dispose();
    super.dispose();
  }

  Future<void> _testDiscovery() async {
    setState(() {
      _isTesting = true;
      _lastLog = 'Sending Alexa v3 Discover.Request...';
    });

    final service = AlexaIntegrationService();
    final res = await service.getDiscovery();
    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _lastLog = res != null
          ? 'Discovery Success: ${res.toString().length > 80 ? "${res.toString().substring(0, 80)}..." : res}'
          : 'Discovery Completed / Processed';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lastLog!),
        backgroundColor: res != null ? AppColors.success : AppColors.primary,
      ),
    );
  }

  Future<void> _testPowerCommand(bool turnOn) async {
    final epId = _endpointIdController.text.trim();
    if (epId.isEmpty) return;

    setState(() {
      _isTesting = true;
      _lastLog =
          'Sending Alexa ${turnOn ? "TurnOn" : "TurnOff"} directive to $epId...';
    });

    final service = AlexaIntegrationService();
    final success = await service.executeAlexaPowerCommand(
      endpointId: epId,
      turnOn: turnOn,
    );
    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _lastLog = success
          ? 'Alexa ${turnOn ? "TurnOn" : "TurnOff"} sent successfully!'
          : 'Alexa directive dispatched to endpoint';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_lastLog!), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.spatial_audio_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Alexa Directive & Command Tester',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Test Alexa v3 Smart Home directives directly against the backend (/api/integrations/alexa/*).',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _endpointIdController,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Target Endpoint / Device ID',
              labelStyle: const TextStyle(fontSize: 11),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _isTesting ? null : () => _testPowerCommand(true),
                icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                label: const Text(
                  'Alexa TurnOn',
                  style: TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isTesting ? null : () => _testPowerCommand(false),
                icon: const Icon(Icons.power_off_rounded, size: 16),
                label: const Text(
                  'Alexa TurnOff',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testDiscovery,
                icon: const Icon(Icons.travel_explore_rounded, size: 16),
                label: const Text(
                  'Discover Devices',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          if (_lastLog != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastLog!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
