# Smart Homz Final Review Checklist

Use this checklist after applying the latest source archive.

## 1. Build checks

```bash
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

If `flutter test` fails because of an old test creating `DeviceProvider()`
directly, update that test to use `test/test_helpers.dart`.

## 2. Property management flow

- Open **Menu → Homes**.
- Add a property/home.
- Open the property and add a floor.
- Open the floor and add a room.
- Open the room and add a device.
- Edit each level once.
- Delete a test room/floor/property and confirm child devices are removed.
- Restart the app and confirm saved data remains.

## 3. Role checks

- Super Admin / Society Manager:
  - Add/Edit/Delete controls should be visible.
- Resident / Security / Maintenance:
  - Property, floor, room, and device management actions should be hidden.
  - Device controls should still follow device-control permissions.

## 4. Dashboard checks

- Hero card shows property and device status.
- Property Overview counts Homes, Floors, Rooms, and Devices.
- Quick Navigation opens Homes, Devices, Alerts, and Fire & Smoke.
- Fire & Smoke card reflects active smoke/gas alerts.

## 5. Alerts and safety checks

- Alerts tab shows summary cards.
- Active/Acknowledged/All tabs work.
- Search and filter work.
- Acknowledge works for permitted roles.
- Fire & Smoke screen shows smoke/gas sensors and recent safety alerts.

## 6. Empty/error states

- Search with a random word and confirm no-results cards display.
- Open an empty room and confirm the empty-device card displays.
- Local-storage retry cards are available if saved data fails to load.

## 7. Backend readiness

- Read `BACKEND_INTEGRATION_PLAN.md`.
- Keep Hive enabled until Firebase is actually configured.
- Implement Firebase repositories only after adding:

```bash
flutter pub add firebase_core cloud_firestore firebase_auth
flutterfire configure
```

## Recommended next real feature

Connect Firebase Auth + Firestore for:

- User login
- Role-based access
- Property hierarchy sync
- Device registry sync
- Alert history sync
