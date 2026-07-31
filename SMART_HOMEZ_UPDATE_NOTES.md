# Smart Homez reference UI update

## Included

- Light workspace, dark navigation and amber/orange Smart Homez design system.
- Full responsive landing page with sticky navigation, hero property preview,
  property-type cards, setup steps, feature grid and final call to action.
- Working landing navigation links and Log in/Get Started actions.
- Top, middle and bottom conversion CTAs plus a three-slide interactive demo.
- Trust indicators for end-to-end encryption and the 150+ device integration
  catalogue, clearly marked as production-backend capabilities.
- Responsive navigation: mobile drawer/bottom navigation and desktop sidebar.
- Redesigned sign-in experience with property preview.
- Residential and commercial property support.
- Property types: House, Apartment, Villa, Farmhouse, Office, Retail store,
  Warehouse and Co-working.
- Adaptive Add/Edit Property screen with timezone, currency, business hours,
  validation and live preview.
- Persisted property metadata through the existing Hive repository.
- Existing Property → Floor → Room → Device CRUD retained.
- Existing Safety, Alerts, Fire/Smoke/Gas, Water Pump and Energy modules retained.
- Persistent scheduled automations and Morning, Night, Away and Custom scenes.
- Voice assistant connection setup UI.
- Webhook endpoint configuration and test preparation UI.
- Existing role-aware access control and vendor-node modules retained.

## Modern signed-in Home

- Added a property-first Home layout with search, modern property cards, live
  property statistics and a prominent Add Property action.
- The time-aware greeting and first name now sit between the menu and profile
  icon in the top app bar.
- Property Management is now a clean header rather than a surrounding card,
  and its old View All button has been removed.
- Property cards use richer gradients, ambient colour, stronger hierarchy and
  premium Automation and Energy control tiles.
- Property three-dot menus contain exactly Edit, Delete and Device History;
  opening a property is handled by tapping the card itself.
- The Home page keeps Automations, Energy, Energy Snapshot and System Health.
- Quick Actions and the embedded Recent Activity list have been removed from
  Home to keep the property dashboard focused.
- Activity replaces Water as the final, lower-right bottom-navigation tab and
  opens a searchable, filterable cross-property activity timeline.
- Safety monitoring, the water-pump snapshot, fire/smoke alert card and the
  old Home/Devices/Alerts/Fire quick-navigation tiles are no longer shown on
  Home. Their dedicated app modules, including Water Management, remain
  available elsewhere.

## Optional setup fields

- Property, floor, room and device names may be left blank; Smart Homez creates
  readable default names.
- MAC address is optional.
- Devices can be registered without a property, floor or room and appear under
  Unassigned until they are organised.

## Backend-bound features

Physical device commands, voice-provider authorization and external webhook
delivery require the production backend, credentials and IoT gateway. The app
shows the complete setup and management flows without embedding secrets in the
mobile client.

## Run locally

```bash
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## Build correction

- Restored the dashboard device-model import required by
  `DeviceStatus.online`.
- Made the property, responsive landing and Activity widget tests deterministic
  across Flutter test window sizes and environments without initialized Hive.
