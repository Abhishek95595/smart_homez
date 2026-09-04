import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/device_provider.dart';
import 'alexa_provider.dart';
import 'alexa_webview_screen.dart';

class AlexaWifiDiscoveryModal extends StatefulWidget {
  const AlexaWifiDiscoveryModal({super.key});

  @override
  State<AlexaWifiDiscoveryModal> createState() =>
      _AlexaWifiDiscoveryModalState();
}

class _AlexaWifiDiscoveryModalState extends State<AlexaWifiDiscoveryModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realDevices = context.read<DeviceProvider>().devices;
      context.read<AlexaProvider>().scanLocalWifiDevices(
        realDevices: realDevices,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final alexaProvider = context.watch<AlexaProvider>();
    final devices = alexaProvider.wifiDevices;
    final isScanning = alexaProvider.isScanningWifi;

    return Container(
      padding: const EdgeInsets.all(24),
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Color(0xFF00CAFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Home Real Devices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real connected devices available for Alexa control',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isScanning) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00CAFF),
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ] else if (devices.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No real devices found in your active home inventory.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: devices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final device = devices[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.devices_other_rounded,
                        color: Color(0xFF0090B8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${device.room} • ${device.model}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: alexaProvider.isConnecting
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final result = await alexaProvider.connectAlexa();
                      if (result != null && context.mounted) {
                        final returnedUri = await Navigator.of(context)
                            .push<Uri>(
                              MaterialPageRoute(
                                builder: (_) => AlexaWebViewScreen(
                                  authorizeUri: result.uri,
                                  bearerToken: result.token,
                                ),
                              ),
                            );
                        if (returnedUri != null) {
                          await alexaProvider.handleCallbackUri(returnedUri);
                        }
                      }
                    },
              icon: const Icon(Icons.link_rounded, size: 20),
              label: Text(
                alexaProvider.isConnecting
                    ? 'Connecting...'
                    : 'Connect Alexa via Link-Token API',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00CAFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
