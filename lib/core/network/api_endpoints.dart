abstract final class ApiEndpoints {
  static const String baseUrl = 'https://tenant-api.saajsajja.in';

  // Auth
  static const String authToken = '/api/Auth/token';
  static const String authLogin = '/api/Auth/login';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';

  // SSE
  static String sseEvents(String token) =>
      '/api/v1/sse/device-events?token=$token';

  // Automations
  static const String automations = '/api/v1/automations';

  static String automation(String automationId) => '$automations/$automationId';

  static String toggleAutomation(String automationId) =>
      '${automation(automationId)}/toggle';

  // Clients
  static const String clients = '/api/v1/clients';
  static const String resolveClient = '$clients/resolve';

  static String client(String clientId) => '$clients/$clientId';

  static String clientDevices(String clientId) => '${client(clientId)}/devices';

  static String clientDevice(String clientId, String deviceId) =>
      '${clientDevices(clientId)}/$deviceId';

  static String deviceCommand(String clientId, String deviceId) =>
      '${clientDevice(clientId, deviceId)}/command';

  // Global fallback command endpoint
  static String globalDeviceCommand(String deviceId) =>
      '/api/v1/devices/$deviceId/command';

  static String moveDevice(String clientId, String deviceId) =>
      '${clientDevice(clientId, deviceId)}/move';

  static String clientHomes(String clientId) => '${client(clientId)}/homes';

  static String clientHome(String clientId, String homeId) =>
      '${clientHomes(clientId)}/$homeId';

  static String clientDashboard(String clientId, String homeId) =>
      '${clientHome(clientId, homeId)}/dashboard';

  static String homeFloors(String clientId, String homeId) =>
      '${clientHome(clientId, homeId)}/floors';

  static String homeFloor(String clientId, String homeId, String floorId) =>
      '${homeFloors(clientId, homeId)}/$floorId';

  static String floorRooms(String clientId, String homeId, String floorId) =>
      '${homeFloor(clientId, homeId, floorId)}/rooms';

  static String floorRoom(
    String clientId,
    String homeId,
    String floorId,
    String roomId,
  ) => '${floorRooms(clientId, homeId, floorId)}/$roomId';

  // Vendor endpoints
  static String vendorAccounts(String clientId) =>
      '${client(clientId)}/vendor/accounts';

  static String vendorAccount(String clientId, String accountId) =>
      '${vendorAccounts(clientId)}/$accountId';

  static String vendorSync(String clientId) =>
      '${client(clientId)}/vendor/sync';

  static String vendorNodes(String clientId) =>
      '${client(clientId)}/vendor/nodes';

  static String pairVendorNode(String clientId, String nodeId) =>
      '${vendorNodes(clientId)}/$nodeId/pair';
}
