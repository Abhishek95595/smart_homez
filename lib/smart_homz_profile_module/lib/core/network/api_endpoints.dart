abstract final class ApiEndpoints {
  static const String baseUrl = 'https://tenant-api-qa.omnihome.in';

  // =============================================================
  // TENANT API IDENTITY CONFIGURATION (QA ENVIRONMENT)
  // =============================================================
  static const String productionTenantId =
      '6d11e924-d046-400d-bc30-62a06e13de61';
  static const String expectedTenantClientId = 'anvyaaai_AEB3';
  static const String productionClientGuid =
      '6782976c-e9a4-41c9-a754-05e4ba0a97b2';
  static const String expectedJwtIssuer = 'AuraBrain';
  static const String expectedJwtAudience = 'AuraBrainMobile';
  static const String expectedJwtPermission = 'write';

  // Cloud Functions / BFF Backend Base URL
  static const String cloudFunctionsBaseUrl =
      'https://us-central1-hasomi-e2ba3.cloudfunctions.net/api';
  static const String bffSessionVerify = '/session/verify';

  // Auth
  static const String authLogin = '/api/Auth/login';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String authInviteInfo = '/api/v1/auth/invite-info';

  // OAuth (RFC 7009 / OAuth2)
  static const String oauthToken = '/oauth/token';
  static const String oauthRevoke = '/oauth/revoke';

  // SSE
  static String sseEvents(String token) =>
      '/api/v1/sse/device-events?token=$token';

  // Automations
  static const String automations = '/api/v1/automations';

  static String automation(String automationId) => '$automations/$automationId';

  static String toggleAutomation(String automationId) =>
      '${automation(automationId)}/toggle';

  // Scenes
  static const String scenes = '/api/v1/scenes';

  static String scene(String sceneId) => '$scenes/$sceneId';

  static String activateScene(String sceneId) => '${scene(sceneId)}/activate';

  static String sceneStatus(String sceneId) => '${scene(sceneId)}/status';

  // Clients
  static const String clients = '/api/v1/clients';
  static const String resolveClient = '$clients/resolve';
  static const String createClient = '$clients/createClient';
  static const String verifyClient = '$clients/createClient/verify';

  /// Authoritatively normalizes any client identifier to the production client GUID
  static String normalizeClientGuid(String? clientId) {
    if (clientId == null || clientId.trim().isEmpty) {
      return productionClientGuid;
    }
    final clean = clientId.trim();
    if (clean == '03d6aaff-f21b-41fc-902f-8184dacd0861' ||
        clean == 'df0df9e3-0e47-4d46-810e-3c4f5c267d69' ||
        clean != productionClientGuid) {
      return productionClientGuid;
    }
    return clean;
  }

  static String client([String? clientId]) =>
      '$clients/${normalizeClientGuid(clientId)}';

  static String resetPassword(String clientId) =>
      '${client(clientId)}/reset-password';

  static String verifyResetPassword(String clientId) =>
      '${resetPassword(clientId)}/verify';

  static String syncClientDevices(String clientId) =>
      '${client(clientId)}/devices/sync';

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

  // Homes Layout & Device Batch Management
  static const String homesTemplateSetup = '/api/v1/homes/template-setup';
  static const String bulkAssignRooms = '/api/v1/devices/bulk-assign-rooms';
  static String unassignedDevices(String homeId) =>
      '/api/v1/homes/$homeId/unassigned-devices';

  // Environment & Contextual Services
  static const String environmentSolar = '/api/v1/environment/solar';
  static const String environmentDuskDawn = '/api/v1/environment/dusk-dawn';
  static const String environmentWeatherPrompts =
      '/api/v1/environment/weather-prompts';
  static const String environmentHomeLocation =
      '/api/v1/environment/home-location';
  static const String environmentPresence = '/api/v1/environment/presence';
  static const String environmentWidgets = '/api/v1/environment/widgets';

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

  // Alexa Integrations
  static const String alexaLinkToken = '/api/integrations/alexa/link-token';
  static const String alexaDirective = '/api/integrations/alexa/directive';
  static const String alexaDiscovery = '/api/integrations/alexa/discovery';
  static const String alexaState = '/api/integrations/alexa/state';
  static const String alexaCommands = '/api/integrations/alexa/commands';
  static const String alexaConnect = '/api/integrations/alexa/connect';
  static const String alexaStatus = '/api/integrations/alexa/status';
  static const String alexaSync = '/api/integrations/alexa/sync';
  static const String alexaDisconnect = '/api/integrations/alexa/disconnect';
}
