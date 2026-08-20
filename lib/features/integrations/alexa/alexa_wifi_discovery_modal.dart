import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/device_provider.dart';
import 'alexa_provider.dart';
import 'alexa_status_model.dart';

class AlexaWifiDiscoveryModal extends StatefulWidget {
  const AlexaWifiDiscoveryModal({super.key});

  @override
  State<AlexaWifiDiscoveryModal> createState() => _AlexaWifiDiscoveryModalState();
}

class _AlexaWifiDiscoveryModalState extends State<AlexaWifiDiscoveryModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanAnimationController;
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realDevices = context.read<DeviceProvider>().devices;
      context.read<AlexaProvider>().scanLocalWifiDevices(realDevices: realDevices);
    });
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _connectDevice(AlexaWifiDevice device) async {
    setState(() {
      _connectingDeviceId = device.id;
    });

    final alexaProvider = context.read<AlexaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final success = await alexaProvider.connectToLocalWifiDevice(device);

    if (!mounted) return;
    setState(() {
      _connectingDeviceId = null;
    });

    nav.pop();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success
                    ? 'Connected to ${device.name} (${device.room})!'
                    : 'Failed to connect to ${device.name}.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alexaProvider = context.watch<AlexaProvider>();
    final devices = alexaProvider.wifiDevices;
    final isScanning = alexaProvider.isScanningWifi;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 18),

          // Header with Alexa logo & title
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF00CAFF), // Alexa official Cyan
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Local Alexa Device',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Local Wi-Fi Network Discovery',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Wi-Fi Scanner Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _scanAnimationController,
                  builder: (context, child) {
                    return Icon(
                      Icons.wifi_find_rounded,
                      color: isScanning
                          ? Color.lerp(
                              const Color(0xFF00CAFF),
                              const Color(0xFF10B981),
                              _scanAnimationController.value,
                            )
                          : const Color(0xFF10B981),
                      size: 20,
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isScanning
                        ? 'Scanning local Wi-Fi for Echo & Alexa speakers...'
                        : 'Discovered ${devices.length} Alexa device${devices.length == 1 ? '' : 's'} on Wi-Fi',
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isScanning)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF166534)),
                    onPressed: () {
                      final realDevices = context.read<DeviceProvider>().devices;
                      alexaProvider.scanLocalWifiDevices(realDevices: realDevices);
                    },
                    tooltip: 'Rescan Wi-Fi',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Discovered Devices List
          Flexible(
            child: isScanning && devices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF00CAFF),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Searching local network...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: devices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final bool isConnectingThis = _connectingDeviceId == device.id;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isConnectingThis
                                ? const Color(0xFF00CAFF)
                                : const Color(0xFFE2E8F0),
                            width: isConnectingThis ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Device icon container
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F7FE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.speaker_group_rounded,
                                color: Color(0xFF0090B8),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Device Name, Room, and IP Address
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${device.room} • ${device.ipAddress}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          device.wifiFrequency,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Select / Connect Button
                            SizedBox(
                              height: 36,
                              child: FilledButton(
                                onPressed: isConnectingThis
                                    ? null
                                    : () => _connectDevice(device),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF00CAFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                ),
                                child: isConnectingThis
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Connect',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
