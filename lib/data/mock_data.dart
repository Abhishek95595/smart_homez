import '../models/alert.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/property_hierarchy.dart';
import '../models/ticket.dart';
import '../models/user_role.dart';
import '../models/water_system.dart';

/// Central mock/seed dataset. Structured to mirror what a real backend
/// (PostgreSQL registry + MQTT retained state) would provide, so swapping
/// this out for real API/MQTT calls later requires no UI changes.
class MockData {
  static const tenantId = 'anvya_greenwood';
  static const buildingId = 'bldg_A';

  static Society buildSociety() {
    return const Society(
      id: tenantId,
      name: 'Greenwood Heights',
      address: '221 Palm Avenue, Bengaluru',
      buildings: [
        Building(
          id: buildingId,
          name: 'Greenwood Heights',
          towers: [
            Tower(
              id: 'tower_A',
              name: 'Tower A',
              commonAreas: ['Lobby', 'Basement', 'Terrace', 'Elevator 1'],
              flats: [
                Flat(id: 'flat_302', label: '302', floor: 3),
                Flat(id: 'flat_303', label: '303', floor: 3),
                Flat(id: 'flat_401', label: '401', floor: 4),
              ],
            ),
            Tower(
              id: 'tower_B',
              name: 'Tower B',
              commonAreas: ['Lobby', 'Basement', 'DG Room'],
              flats: [
                Flat(id: 'flat_101', label: '101', floor: 1),
                Flat(id: 'flat_202', label: '202', floor: 2),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static List<AppUser> demoUsers() {
    return const [
      AppUser(
        id: 'user_admin',
        name: 'Aditya Rao',
        email: 'admin@anvya.io',
        phone: '+91 90000 00001',
        role: UserRole.superAdmin,
        tenantId: tenantId,
        avatarInitials: 'AR',
      ),
      AppUser(
        id: 'user_manager',
        name: 'Priya Sharma',
        email: 'manager@anvya.io',
        phone: '+91 90000 00002',
        role: UserRole.facilityManager,
        tenantId: tenantId,
        buildingId: buildingId,
        avatarInitials: 'PS',
      ),
      AppUser(
        id: 'user_resident',
        name: 'Rahul Verma',
        email: 'rahul@anvya.io',
        phone: '+91 90000 00003',
        role: UserRole.resident,
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'Tower A',
        flatId: '302',
        avatarInitials: 'RV',
      ),
      AppUser(
        id: 'user_security',
        name: 'Suresh Kumar',
        email: 'security@anvya.io',
        phone: '+91 90000 00004',
        role: UserRole.security,
        tenantId: tenantId,
        buildingId: buildingId,
        avatarInitials: 'SK',
      ),
      AppUser(
        id: 'user_maintenance',
        name: 'Manoj Gupta',
        email: 'maintenance@anvya.io',
        phone: '+91 90000 00005',
        role: UserRole.maintenance,
        tenantId: tenantId,
        buildingId: buildingId,
        avatarInitials: 'MG',
      ),
    ];
  }

  static List<Device> demoDevices() {
    final now = DateTime.now();
    return [
      Device(
        deviceId: 'dev_light_lr_302',
        type: DeviceType.light,
        name: 'Living Room Light',
        firmwareVersion: '1.4.2',
        macAddress: 'AA:BB:01:02:03:04',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        flatId: 'flat_302',
        zone: 'Living Room',
        isOn: true,
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_fan_lr_302',
        type: DeviceType.fan,
        name: 'Living Room Fan',
        firmwareVersion: '1.4.2',
        macAddress: 'AA:BB:01:02:03:05',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        flatId: 'flat_302',
        zone: 'Living Room',
        isOn: true,
        dimLevel: 60,
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_ac_bed_302',
        type: DeviceType.ac,
        name: 'Bedroom AC',
        firmwareVersion: '2.0.1',
        macAddress: 'AA:BB:01:02:03:06',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        flatId: 'flat_302',
        zone: 'Bedroom',
        isOn: false,
        dimLevel: 24,
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_light_kitchen_302',
        type: DeviceType.light,
        name: 'Kitchen Light',
        firmwareVersion: '1.4.2',
        macAddress: 'AA:BB:01:02:03:07',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        flatId: 'flat_302',
        zone: 'Kitchen',
        isOn: false,
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_pump_1',
        type: DeviceType.pump,
        name: 'Overhead Tank Pump',
        firmwareVersion: '3.1.0',
        macAddress: 'AA:BB:02:00:00:01',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        zone: 'Basement',
        isOn: false,
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_smoke_basement_A',
        type: DeviceType.smokeSensor,
        name: 'Smoke Sensor',
        firmwareVersion: '1.0.5',
        macAddress: 'AA:BB:03:00:00:01',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        zone: 'Basement',
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_gas_basement_A',
        type: DeviceType.gasSensor,
        name: 'Gas Leak Sensor',
        firmwareVersion: '1.0.5',
        macAddress: 'AA:BB:03:00:00:02',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        zone: 'Basement',
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_energy_meter_302',
        type: DeviceType.energyMeter,
        name: 'Flat 302 Energy Meter',
        firmwareVersion: '2.2.0',
        macAddress: 'AA:BB:04:00:00:01',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        flatId: 'flat_302',
        zone: 'Main Panel',
        lastHeartbeat: now,
      ),
      Device(
        deviceId: 'dev_corridor_light_A',
        type: DeviceType.light,
        name: 'Corridor Light - Floor 3',
        firmwareVersion: '1.4.2',
        macAddress: 'AA:BB:01:00:00:09',
        tenantId: tenantId,
        buildingId: buildingId,
        towerId: 'tower_A',
        zone: 'Corridor',
        isOn: true,
        lastHeartbeat: now,
      ),
    ];
  }

  static List<AppAlert> demoAlerts() {
    final now = DateTime.now();
    return [
      AppAlert(
        id: 'alert_001',
        alertType: AlertType.gasLeak,
        severity: AlertSeverity.critical,
        location: 'Tower A / Basement',
        deviceId: 'dev_gas_basement_A',
        value: 780,
        threshold: 500,
        timestamp: now.subtract(const Duration(minutes: 4)),
      ),
      AppAlert(
        id: 'alert_002',
        alertType: AlertType.highLoad,
        severity: AlertSeverity.medium,
        location: 'Flat 302',
        deviceId: 'dev_energy_meter_302',
        value: 4200,
        threshold: 3500,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
        acknowledged: true,
        acknowledgedBy: 'Rahul Verma',
        acknowledgedAt: now.subtract(const Duration(minutes: 55)),
      ),
      AppAlert(
        id: 'alert_003',
        alertType: AlertType.pumpDryRun,
        severity: AlertSeverity.high,
        location: 'Tower A / Basement',
        deviceId: 'dev_pump_1',
        value: 0.4,
        threshold: 2.0,
        timestamp: now.subtract(const Duration(hours: 5)),
        acknowledged: true,
        acknowledgedBy: 'Manoj Gupta',
        acknowledgedAt: now.subtract(const Duration(hours: 4, minutes: 50)),
      ),
      AppAlert(
        id: 'alert_004',
        alertType: AlertType.deviceOffline,
        severity: AlertSeverity.low,
        location: 'Tower B / Lobby',
        deviceId: 'dev_light_lobby_B',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        acknowledged: true,
        acknowledgedBy: 'Priya Sharma',
        acknowledgedAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
    ];
  }

  static List<WaterTank> demoTanks() {
    return [
      WaterTank(
        id: 'tank_A_overhead',
        name: 'Overhead Tank - Tower A',
        levelPercent: 68,
        pumpMode: PumpMode.auto,
        pumpState: PumpState.stopped,
      ),
      WaterTank(
        id: 'tank_B_overhead',
        name: 'Overhead Tank - Tower B',
        levelPercent: 22,
        pumpMode: PumpMode.auto,
        pumpState: PumpState.running,
        pumpStartedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ];
  }

  static List<ServiceTicket> demoTickets() {
    final now = DateTime.now();
    return [
      ServiceTicket(
        id: 'tkt_1001',
        title: 'Flickering light in corridor',
        description: 'Floor 3 corridor light flickers intermittently.',
        category: TicketCategory.electrical,
        status: TicketStatus.inProgress,
        raisedBy: 'Rahul Verma',
        location: 'Tower A / Floor 3',
        createdAt: now.subtract(const Duration(days: 2)),
        assignedTo: 'Manoj Gupta',
      ),
      ServiceTicket(
        id: 'tkt_1002',
        title: 'AC not cooling',
        description: 'Bedroom AC running but not cooling properly.',
        category: TicketCategory.device,
        status: TicketStatus.open,
        raisedBy: 'Rahul Verma',
        location: 'Flat 302',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      ServiceTicket(
        id: 'tkt_1003',
        title: 'Water leakage near pump room',
        description: 'Minor leakage observed near basement pump room.',
        category: TicketCategory.plumbing,
        status: TicketStatus.resolved,
        raisedBy: 'Suresh Kumar',
        location: 'Tower A / Basement',
        createdAt: now.subtract(const Duration(days: 5)),
        assignedTo: 'Manoj Gupta',
      ),
    ];
  }

  static List<BroadcastNotice> demoBroadcasts() {
    final now = DateTime.now();
    return [
      BroadcastNotice(
        id: 'note_1',
        title: 'Scheduled Water Tank Cleaning',
        message:
            'Overhead tank cleaning scheduled for Tower A on Sunday 8 AM - 11 AM. Water supply may be interrupted.',
        postedAt: now.subtract(const Duration(hours: 3)),
        postedBy: 'Priya Sharma',
      ),
      BroadcastNotice(
        id: 'note_2',
        title: 'Fire Drill Notice',
        message:
            'A mock fire drill will be conducted on Saturday at 5 PM. Please cooperate with security staff.',
        postedAt: now.subtract(const Duration(days: 1)),
        postedBy: 'Priya Sharma',
      ),
    ];
  }
}
