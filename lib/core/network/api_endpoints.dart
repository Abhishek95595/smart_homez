class ApiEndpoints {
  static const String baseUrl = 'https://tenant-api.saajsajja.in';

  // Auth
  static const String authToken = '/api/Auth/token';
  static const String authLogin = '/api/Auth/login';

  // Clients
  static const String resolveClient = '/api/v1/clients/resolve';
  static const String listClients = '/api/v1/clients';

  // Hierarchy & Devices
  static String clientHomes(String clientId) =>
      '/api/v1/clients/$clientId/homes';
  static String homeFloors(String clientId, String homeId) =>
      '/api/v1/clients/$clientId/homes/$homeId/floors';
  static String floorRooms(String clientId, String homeId, String floorId) =>
      '/api/v1/clients/$clientId/homes/$homeId/floors/$floorId/rooms';
  static String clientDevices(String clientId) =>
      '/api/v1/clients/$clientId/devices';
  static String deviceCommand(String clientId, String deviceId) =>
      '/api/v1/clients/$clientId/devices/$deviceId/command';

  // SSE
  static String sseEvents(String token) =>
      '/api/v1/sse/device-events?token=$token';
}
