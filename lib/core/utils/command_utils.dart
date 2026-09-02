/// Normalizes legacy/deprecated device command names into canonical backend ones.
String normalizeDeviceCommand(String command) {
  switch (command.trim().toLowerCase()) {
    case 'turn_on':
      return 'on';
    case 'turn_off':
      return 'off';
    case 'set_brightness':
      return 'brightness';
    case 'set_speed':
      return 'speed';
    default:
      return command.trim();
  }
}
