import '../core/network/api_endpoints.dart';
import '../models/client_dashboard_model.dart';
import 'api_service.dart';

class ClientDashboardService {
  ClientDashboardService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<ClientDashboardModel> fetchDashboard({
    required String clientId,
    required String homeId,
    required String period,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.clientDashboard(clientId, homeId),
      queryParameters: <String, dynamic>{'period': period},
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid dashboard response.');
    }
    if (payload['success'] == false) {
      throw Exception(
        payload['error']?.toString() ?? 'Dashboard request failed.',
      );
    }
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Dashboard data is missing.');
    }
    return ClientDashboardModel.fromJson(data);
  }
}
