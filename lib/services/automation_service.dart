import '../data/models/requests/create_automation_request.dart';
import '../data/repositories/tenant_api_repository.dart';
import '../models/automation_model.dart';

class AutomationService {
  AutomationService([TenantApiRepository? repository])
    : _repository = repository ?? TenantApiRepository();

  final TenantApiRepository _repository;

  Future<List<AutomationModel>> getAutomations() {
    return _repository.getAutomations();
  }

  Future<AutomationModel> getAutomation(String id) {
    return _repository.getAutomation(id);
  }

  Future<AutomationModel> createAutomation(CreateAutomationRequest request) {
    _validateAutomationRequest(request);
    return _repository.createAutomation(request);
  }

  Future<AutomationModel> updateAutomation({
    required String automationId,
    required CreateAutomationRequest request,
  }) {
    if (automationId.trim().isEmpty) {
      throw const FormatException('Automation ID is missing.');
    }
    _validateAutomationRequest(request);
    return _repository.updateAutomation(
      automationId: automationId,
      request: request,
    );
  }

  Future<void> deleteAutomation(String id) {
    if (id.trim().isEmpty) {
      throw const FormatException('Automation ID is missing.');
    }
    return _repository.deleteAutomation(id);
  }

  Future<void> toggleAutomation({
    required String automationId,
    required bool isActive,
  }) {
    if (automationId.trim().isEmpty) {
      throw const FormatException('Automation ID is missing.');
    }
    return _repository.toggleAutomation(
      automationId: automationId,
      isActive: isActive,
    );
  }

  Future<bool> activateScene(String sceneId) {
    if (sceneId.trim().isEmpty) {
      throw const FormatException('Scene ID is missing.');
    }
    return _repository.activateScene(sceneId);
  }

  void _validateAutomationRequest(CreateAutomationRequest request) {
    if (request.name == null || request.name!.trim().isEmpty) {
      throw const FormatException('Automation name cannot be empty.');
    }
    // Specific business rules for conditions/actions could be added here
  }
}
