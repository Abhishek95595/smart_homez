# Hasomi Automation UI Update

Changed files:

- `lib/screens/automations/automations_screen.dart`
  - Redesigned to match the supplied Hasomi automation reference.
  - Added Select Home and Filter controls.
  - Added hero area, automation category tabs, My Scenes, compact Automation Rules, Scheduled Automations, Timers, Quick Actions, and Ask Hasomi banner.
  - Existing AutomationProvider fetch/create/update/delete/toggle behavior is preserved.
  - Uses the project's existing images from `assets/images/`.

- `lib/screens/main_shell.dart`
  - Added Activity to the bottom navigation.
  - Updated the bottom navigation styling to better match the reference.

No backend/service/provider API code was changed.
