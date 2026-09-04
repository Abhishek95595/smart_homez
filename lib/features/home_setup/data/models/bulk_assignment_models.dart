class DeviceAssignmentItem {
  final String deviceId;
  final String roomId;

  const DeviceAssignmentItem({required this.deviceId, required this.roomId});

  Map<String, String> toJson() => {'device_id': deviceId, 'room_id': roomId};
}

class BulkAssignmentFailure {
  final String deviceId;
  final String error;

  const BulkAssignmentFailure({required this.deviceId, required this.error});

  factory BulkAssignmentFailure.fromJson(Map<String, dynamic> json) {
    return BulkAssignmentFailure(
      deviceId: (json['device_id'] ?? json['deviceId'] ?? json['id'] ?? '')
          .toString(),
      error: (json['error'] ?? json['message'] ?? 'Assignment failed')
          .toString(),
    );
  }
}

class BulkAssignmentResponse {
  final bool success;
  final List<String> assignedIds;
  final List<BulkAssignmentFailure> failedAssignments;

  const BulkAssignmentResponse({
    required this.success,
    this.assignedIds = const [],
    this.failedAssignments = const [],
  });

  bool get hasPartialFailures =>
      failedAssignments.isNotEmpty && assignedIds.isNotEmpty;
  bool get hasFailures => failedAssignments.isNotEmpty;
  bool get isFullSuccess => success && failedAssignments.isEmpty;
  List<String> get assigned => assignedIds;

  factory BulkAssignmentResponse.fromJson(dynamic rawData) {
    if (rawData is bool) {
      return BulkAssignmentResponse(success: rawData);
    }

    if (rawData is! Map) {
      return const BulkAssignmentResponse(success: true);
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(rawData);
    final dynamic data = json['data'] ?? json;

    final bool overallSuccess = json['success'] != false;
    final List<String> assigned = [];
    final List<BulkAssignmentFailure> failures = [];

    if (data is Map) {
      final dynamic assignedRaw = data['assigned'] ?? data['assigned_devices'];
      if (assignedRaw is List) {
        for (final item in assignedRaw) {
          if (item is String) {
            assigned.add(item);
          } else if (item is Map && (item['device_id'] ?? item['id']) != null) {
            assigned.add((item['device_id'] ?? item['id']).toString());
          }
        }
      }

      final dynamic failedRaw =
          data['failed'] ?? data['failed_devices'] ?? data['errors'];
      if (failedRaw is List) {
        for (final item in failedRaw) {
          if (item is Map) {
            failures.add(
              BulkAssignmentFailure.fromJson(Map<String, dynamic>.from(item)),
            );
          } else if (item is String) {
            failures.add(
              BulkAssignmentFailure(deviceId: item, error: 'Assignment failed'),
            );
          }
        }
      }
    }

    return BulkAssignmentResponse(
      success: overallSuccess && (failures.isEmpty || assigned.isNotEmpty),
      assignedIds: assigned,
      failedAssignments: failures,
    );
  }
}
