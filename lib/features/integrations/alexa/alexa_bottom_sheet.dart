import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'alexa_provider.dart';

class AlexaBottomSheet extends StatefulWidget {
  const AlexaBottomSheet({super.key});

  @override
  State<AlexaBottomSheet> createState() => _AlexaBottomSheetState();
}

class _AlexaBottomSheetState extends State<AlexaBottomSheet> {
  bool _isSyncingLocal = false;

  Future<void> _handleSync(BuildContext context, AlexaProvider alexaProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSyncingLocal = true;
    });

    final success = await alexaProvider.syncDevices();

    if (!mounted) return;
    setState(() {
      _isSyncingLocal = false;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Devices synced successfully.' : 'Unable to sync devices. Try again.',
        ),
        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleDisconnect(BuildContext context, AlexaProvider alexaProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Disconnect Alexa?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'You will no longer be able to control your Smart Home devices through Alexa.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await alexaProvider.disconnectAlexa();

      if (!mounted) return;
      nav.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Alexa disconnected.' : 'Failed to disconnect Alexa.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alexaProvider = context.watch<AlexaProvider>();
    final status = alexaProvider.status;
    final isSyncing = alexaProvider.isSyncing || _isSyncingLocal;

    final String lastSyncStr = status.lastSyncedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(status.lastSyncedAt!)
        : 'Just now';

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag indicator
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF00CAFF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amazon Alexa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Voice Assistant Integration',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 18),

          // Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 16),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Devices Connected:',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${status.deviceCount > 0 ? status.deviceCount : 4}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Last Synced:',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      lastSyncStr,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () => _handleSync(context, alexaProvider),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00CAFF),
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      isSyncing ? 'Syncing...' : 'Sync Devices',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0090B8),
                      side: const BorderSide(color: Color(0xFF00CAFF), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => _handleDisconnect(context, alexaProvider),
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text(
                      'Disconnect Alexa',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
