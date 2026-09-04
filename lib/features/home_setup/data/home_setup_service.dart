import '../../../data/repositories/tenant_api_repository.dart';
import 'models/bulk_assignment_models.dart';
import 'models/home_layout_template.dart';
import 'models/home_setup_request.dart';
import 'models/home_setup_response.dart';
import 'models/unassigned_device_model.dart';

class HomeSetupService {
  final TenantApiRepository _repository;

  HomeSetupService({TenantApiRepository? repository})
    : _repository = repository ?? TenantApiRepository();

  /// Call the V1 template-setup API to generate the home, floors, and rooms.
  Future<HomeSetupResult> setupHomeFromTemplate(
    HomeSetupRequest request,
  ) async {
    final Map<String, dynamic>? data = await _repository.setupHomeFromTemplate(
      template: request.template,
      homeName: request.homeName,
      address: request.address,
      structureType: request.hierarchyMode == HierarchyMode.flat
          ? 'flat'
          : 'floor_based',
      customRooms:
          request.hierarchyMode == HierarchyMode.flat &&
              request.flatRooms != null
          ? request.flatRooms!
                .map((name) => {'name': name, 'type': 'Room'})
                .toList()
          : null,
      customFloors:
          request.hierarchyMode == HierarchyMode.floorBased &&
              request.floors != null
          ? request.floors!.map((f) => f.toJson()).toList()
          : null,
      extraData: request.toJson(),
    );

    if (data == null || data.isEmpty) {
      throw Exception('Failed to create home structure from template.');
    }

    return HomeSetupResult.fromJson(data);
  }

  /// Fetches unassigned devices for the newly created home.
  Future<List<UnassignedDevice>> getUnassignedDevices(String homeId) async {
    final rawList = await _repository.getUnassignedDevices(homeId);
    return rawList.map((map) => UnassignedDevice.fromJson(map)).toList();
  }

  /// Submits the selected room assignments via the bulk assignment API.
  Future<BulkAssignmentResponse> bulkAssignDevicesToRooms(
    List<DeviceAssignmentItem> assignments,
  ) async {
    if (assignments.isEmpty) {
      return const BulkAssignmentResponse(success: true);
    }

    final payload = assignments.map((item) => item.toJson()).toList();
    final result = await _repository.bulkAssignDevicesToRoomsWithResult(
      payload,
    );
    return BulkAssignmentResponse.fromJson(result);
  }
}
