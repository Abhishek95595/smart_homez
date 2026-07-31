# Smart_homz Property Navigation Patch

This patch adds the functional navigation flow:

`Homes → Floors → Rooms → Devices`

## Install on macOS

1. Back up the current project:

   ```bash
   cd ~/Downloads
   cp -R "flutter_app 2" "flutter_app 2 backup"
   ```

2. From the project root, extract the patch:

   ```bash
   cd ~/Downloads/"flutter_app 2"
   tar -xzf ~/Downloads/smart_homz_property_navigation_patch.tar.gz
   ```

3. Format, validate, and run:

   ```bash
   dart format lib test
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   flutter run
   ```

## Included functionality

- Homes lists role-visible buildings and their device totals.
- Tapping a home opens its tower/floor list.
- Tapping a floor opens its homes and rooms.
- Tapping a room opens only the devices assigned to that exact room.
- Device switches and sliders continue using the existing `DeviceProvider`.
- Residents can now correctly access devices whose stored ID uses the
  `flat_302` form while their profile stores `302`.
- Direct drawer links for Homes, Floors, and Rooms open real screens.
- Empty locations show a clear no-devices state.
- A property hierarchy and resident-device access test is included.
