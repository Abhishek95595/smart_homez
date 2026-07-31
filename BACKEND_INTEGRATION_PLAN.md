# Smart Homz Backend Integration Plan

This app is now prepared for a backend because screens talk to providers, and
providers talk to repository interfaces. To move from local Hive to Firebase,
replace the repository implementation, not the UI.

## Current local storage

- `HivePropertyRepository` stores properties, floors, and rooms locally.
- `HiveDeviceRepository` stores device registry metadata locally.
- `MemoryPropertyRepository` and `MemoryDeviceRepository` are for tests.

## Suggested Firestore structure

```text
tenants/{tenantId}
  properties/{propertyId}
    floors/{floorId}
      rooms/{roomId}
  devices/{deviceId}
  alerts/{alertId}
  tickets/{ticketId}
```

Recommended fields:

- Property: `name`, `address`, `createdAt`, `updatedAt`
- Floor: `name`, `level`, `propertyId`, `createdAt`, `updatedAt`
- Room: `name`, `type`, `propertyId`, `floorId`, `createdAt`, `updatedAt`
- Device: `name`, `type`, `macAddress`, `firmwareVersion`, `propertyId`,
  `floorId`, `roomId`, `zone`, `status`, `lastHeartbeat`, `configThresholds`

## What to do when Firebase is added

1. Add packages:

   ```bash
   flutter pub add firebase_core cloud_firestore firebase_auth
   flutterfire configure
   ```

2. Initialize Firebase before `runApp`.

3. Implement:

   - `FirebasePropertyRepository`
   - `FirebaseDeviceRepository`

4. Inject Firebase repositories in `main.dart`:

   ```dart
   ChangeNotifierProvider(
     create: (_) => PropertyProvider(
       repository: FirebasePropertyRepository(tenantId: tenantId),
     ),
   )
   ```

5. Keep Hive as offline fallback if needed.

## Security rules idea

- Super Admin / Society Manager: read/write property, floor, room, device data.
- Resident: read own flat/room devices only; control permitted devices only.
- Security: read safety/common-area devices and alerts.
- Maintenance: read building devices/tickets; limited shared-device actions.

## Important note

High-frequency telemetry should not be stored as normal Firestore document
updates. For live sensor readings, use MQTT, Realtime Database, or a time-series
backend. Firestore is best for registry data, alerts, and lower-frequency logs.
