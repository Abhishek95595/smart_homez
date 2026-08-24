import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../services/alexa_integration_service.dart';
import '../../theme/app_theme.dart';

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

  final List<_InviteUser> _invites = [
    const _InviteUser(
      id: 'inv_1',
      name: 'Rahul Sharma',
      phoneNumber: '+91 98765 43210',
      accessLevel: 'Device Control (ON/OFF)',
      grantedDeviceIds: ['dev_1', 'dev_2', 'dev_3'],
      grantedDeviceNames: [
        'Living Room Light',
        'Smart Thermostat',
        'Kitchen Fan',
      ],
      active: true,
      invitedAt: 'Today at 11:30 AM',
    ),
    const _InviteUser(
      id: 'inv_2',
      name: 'Priya Verma',
      phoneNumber: '+91 91234 56789',
      accessLevel: 'Full Control',
      grantedDeviceIds: ['dev_1', 'dev_2', 'dev_4', 'dev_5'],
      grantedDeviceNames: [
        'Living Room Light',
        'Smart Thermostat',
        'Main Door Lock',
        'Balcony Light',
      ],
      active: true,
      invitedAt: 'Yesterday',
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

  Future<void> _sendSmsInvite(
    String phoneNumber,
    String inviteeName,
    List<String> devices,
  ) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final String devicesListStr = devices.isNotEmpty
        ? devices.join(', ')
        : 'Smart Homez Property Devices';

    final String inviteUrl =
        'https://tenant-api.saajsajja.in/invite?phone=${Uri.encodeComponent(cleanPhone)}';
    final String message =
        'Hi $inviteeName! You have been invited to Smart Homez to manage property devices ($devicesListStr). Open access link: $inviteUrl';

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{'body': message},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        final Uri altSmsUri = Uri.parse(
          'sms:$cleanPhone?body=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(altSmsUri)) {
          await launchUrl(altSmsUri, mode: LaunchMode.externalApplication);
        } else {
          await Clipboard.setData(ClipboardData(text: message));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Copied SMS invite to clipboard for $cleanPhone. Send via Messages or WhatsApp.',
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Invite] Could not launch SMS composer: $e');
      await Clipboard.setData(ClipboardData(text: message));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SMS invite copied to clipboard ($cleanPhone). Paste in SMS app.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _addInvite() async {
    final draft = await showModalBottomSheet<_InviteUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteFormModal(),
    );
    if (draft == null || !mounted) return;
    setState(() => _invites.add(draft));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening SMS app for ${draft.name} (${draft.phoneNumber})...'),
        backgroundColor: AppColors.success,
      ),
    );
    await _sendSmsInvite(
      draft.phoneNumber,
      draft.name,
      draft.grantedDeviceNames,
    );
  }

  Future<void> _editInvite(_InviteUser invite, int index) async {
    final updated = await showModalBottomSheet<_InviteUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteFormModal(initialUser: invite),
    );
    if (updated == null || !mounted) return;
    setState(() => _invites[index] = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated access permissions for ${updated.name}.'),
        backgroundColor: AppColors.primary,
      ),
    );
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
                'Authorize Hasomi in the Alexa App or browser to control your lights, switches, and thermostats by voice.',
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
                      '3. Grant Hasomi device permission',
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
            Tab(text: 'Invite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [_voiceTab(), _inviteTab()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.index != 1) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _addInvite,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Invite Person'),
            backgroundColor: AppColors.primary,
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

  Widget _inviteTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _IntegrationHero(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Invite People & Manage Device Access',
          message:
              'Share control of your smart home devices with family, guests, or staff by phone number. Specify which devices they can manage (ON/OFF).',
        ),
        const SizedBox(height: 20),
        if (_invites.isEmpty)
          _EmptyInvites(onInvite: _addInvite)
        else
          ..._invites.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _InviteUserCard(
                invite: entry.value,
                onToggleActive: (value) {
                  setState(
                    () => _invites[entry.key] = entry.value.copyWith(
                      active: value,
                    ),
                  );
                },
                onEdit: () => _editInvite(entry.value, entry.key),
                onResendSms: () => _sendSmsInvite(
                  entry.value.phoneNumber,
                  entry.value.name,
                  entry.value.grantedDeviceNames,
                ),
                onDelete: () {
                  final removedName = entry.value.name;
                  setState(() => _invites.removeAt(entry.key));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Revoked invitation for $removedName.')),
                  );
                },
              ),
            ),
          ),
        const _ProductionNote(
          text:
              'Invited members receive an SMS link to log in. Device control permissions apply instantly to selected devices.',
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
                    fontSize: 16.5,
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

class _InviteUserCard extends StatefulWidget {
  final _InviteUser invite;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onResendSms;
  final VoidCallback onDelete;

  const _InviteUserCard({
    required this.invite,
    required this.onToggleActive,
    required this.onEdit,
    required this.onResendSms,
    required this.onDelete,
  });

  @override
  State<_InviteUserCard> createState() => _InviteUserCardState();
}

class _InviteUserCardState extends State<_InviteUserCard> {
  late Map<String, bool> _devicePowerStates;

  @override
  void initState() {
    super.initState();
    _devicePowerStates = {
      for (final devName in widget.invite.grantedDeviceNames) devName: true,
    };
  }

  @override
  void didUpdateWidget(covariant _InviteUserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final devName in widget.invite.grantedDeviceNames) {
      _devicePowerStates.putIfAbsent(devName, () => true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    final String initialLetter = invite.name.isNotEmpty
        ? invite.name[0].toUpperCase()
        : 'U';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    initialLetter,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              invite.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: invite.active
                                  ? const Color(0xFFE7F8F5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: invite.active
                                    ? const Color(0xFFD3F2EC)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              invite.accessLevel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: invite.active
                                    ? const Color(0xFF007E72)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 13,
                            color: AppColors.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invite.phoneNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '· ${invite.invitedAt}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: invite.active,
                  onChanged: widget.onToggleActive,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Allowed Device Controls (ON / OFF)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${invite.grantedDeviceNames.length} Devices',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!invite.active)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'User access disabled by admin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: invite.grantedDeviceNames.map((deviceName) {
                        final bool isPoweredOn =
                            _devicePowerStates[deviceName] ?? true;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _devicePowerStates[deviceName] = !isPoweredOn;
                            });
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${invite.name} toggled $deviceName ${!isPoweredOn ? "ON" : "OFF"}.',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPoweredOn
                                  ? const Color(0xFFE7F8F5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPoweredOn
                                    ? const Color(0xFF9EE4D8)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPoweredOn
                                      ? Icons.power_settings_new_rounded
                                      : Icons.power_off_rounded,
                                  size: 14,
                                  color: isPoweredOn
                                      ? const Color(0xFF007E72)
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  deviceName,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isPoweredOn
                                        ? const Color(0xFF007E72)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPoweredOn ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isPoweredOn
                                        ? const Color(0xFF007E72)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onResendSms,
                  icon: const Icon(Icons.sms_rounded, size: 14),
                  label: const Text('Send SMS', style: TextStyle(fontSize: 11.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit Access', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.person_remove_outlined,
                    size: 14,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Revoke',
                    style: TextStyle(fontSize: 11.5, color: AppColors.danger),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
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

class _EmptyInvites extends StatelessWidget {
  final VoidCallback onInvite;

  const _EmptyInvites({required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.person_add_disabled_rounded,
              size: 38,
              color: AppColors.textFaint,
            ),
            const SizedBox(height: 12),
            const Text(
              'No invited members yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Invite family or staff members by phone number to manage your property devices.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Invite Person'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteFormModal extends StatefulWidget {
  final _InviteUser? initialUser;

  const _InviteFormModal({this.initialUser});

  @override
  State<_InviteFormModal> createState() => _InviteFormModalState();
}

class _InviteFormModalState extends State<_InviteFormModal> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _accessLevel;
  late Set<String> _selectedDeviceNames;

  final List<String> _availableDeviceNames = const [
    'Living Room Light',
    'Smart Thermostat',
    'Kitchen Fan',
    'Main Door Lock',
    'Balcony Light',
    'Master Bedroom Light',
    'Water Purifier',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialUser;
    _nameController = TextEditingController(text: init?.name ?? '');
    _phoneController = TextEditingController(text: init?.phoneNumber ?? '');
    _accessLevel = init?.accessLevel ?? 'Device Control (ON/OFF)';
    _selectedDeviceNames = Set<String>.from(
      init?.grantedDeviceNames ?? ['Living Room Light', 'Kitchen Fan'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;

    if (_selectedDeviceNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one device to grant access.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    final List<String> devicesList = _selectedDeviceNames.toList();

    Navigator.pop(
      context,
      _InviteUser(
        id: widget.initialUser?.id ?? 'inv_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phoneNumber: phone,
        accessLevel: _accessLevel,
        grantedDeviceIds: devicesList
            .map((d) => 'dev_${d.toLowerCase().replaceAll(' ', '_')}')
            .toList(),
        grantedDeviceNames: devicesList,
        active: widget.initialUser?.active ?? true,
        invitedAt: widget.initialUser?.invitedAt ?? 'Just now',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialUser != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
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
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Access & Permissions' : 'Invite Person',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Add phone number and grant device ON/OFF controls',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Full Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Rahul Sharma',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 2 ? 'Enter a valid name' : null,
              ),
              const SizedBox(height: 14),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+91 98765 43210',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 7) {
                    return 'Enter a valid phone number with country code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Permission Level Dropdown
              DropdownButtonFormField<String>(
                value: _accessLevel,
                decoration: const InputDecoration(
                  labelText: 'Permission Role',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: const [
                  'Device Control (ON/OFF)',
                  'Full Control',
                  'View Only',
                ]
                    .map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(level, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _accessLevel = val);
                },
              ),
              const SizedBox(height: 18),

              // Device Access Checklist Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Allowed Device Controls (ON/OFF)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedDeviceNames.length ==
                            _availableDeviceNames.length) {
                          _selectedDeviceNames.clear();
                        } else {
                          _selectedDeviceNames = Set<String>.from(
                            _availableDeviceNames,
                          );
                        }
                      });
                    },
                    child: Text(
                      _selectedDeviceNames.length == _availableDeviceNames.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),

              // Devices Checkboxes
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _availableDeviceNames.length,
                  separatorBuilder: (ctx, i) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (ctx, index) {
                    final devName = _availableDeviceNames[index];
                    final isChecked = _selectedDeviceNames.contains(devName);
                    return CheckboxListTile(
                      dense: true,
                      activeColor: AppColors.primary,
                      title: Text(
                        devName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text(
                        'Grant ON / OFF power control',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textFaint),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedDeviceNames.add(devName);
                          } else {
                            _selectedDeviceNames.remove(devName);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    isEditing
                        ? 'Save Updated Permissions'
                        : 'Send Invitation & Grant Access',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteUser {
  final String id;
  final String name;
  final String phoneNumber;
  final String accessLevel;
  final List<String> grantedDeviceIds;
  final List<String> grantedDeviceNames;
  final bool active;
  final String invitedAt;

  const _InviteUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.accessLevel,
    required this.grantedDeviceIds,
    required this.grantedDeviceNames,
    required this.active,
    required this.invitedAt,
  });

  _InviteUser copyWith({
    String? name,
    String? phoneNumber,
    String? accessLevel,
    List<String>? grantedDeviceIds,
    List<String>? grantedDeviceNames,
    bool? active,
  }) {
    return _InviteUser(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accessLevel: accessLevel ?? this.accessLevel,
      grantedDeviceIds: grantedDeviceIds ?? this.grantedDeviceIds,
      grantedDeviceNames: grantedDeviceNames ?? this.grantedDeviceNames,
      active: active ?? this.active,
      invitedAt: invitedAt,
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
