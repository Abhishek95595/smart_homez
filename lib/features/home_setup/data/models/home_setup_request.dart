import 'home_layout_template.dart';

class HomeSetupRequest {
  final String template;
  final String homeName;
  final String? address;
  final HierarchyMode hierarchyMode;
  final List<String>? flatRooms;
  final List<CustomFloorDraft>? floors;

  const HomeSetupRequest({
    required this.template,
    required this.homeName,
    this.address,
    required this.hierarchyMode,
    this.flatRooms,
    this.floors,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'template': template,
      'home_name': homeName.trim(),
      'structure_type': hierarchyMode == HierarchyMode.flat
          ? 'flat'
          : 'floor_based',
    };

    if (address != null && address!.trim().isNotEmpty) {
      data['address'] = address!.trim();
    }

    if (hierarchyMode == HierarchyMode.flat &&
        flatRooms != null &&
        flatRooms!.isNotEmpty) {
      data['rooms'] = flatRooms!
          .map((name) => {'name': name.trim(), 'type': 'Room'})
          .toList();
    } else if (hierarchyMode == HierarchyMode.floorBased &&
        floors != null &&
        floors!.isNotEmpty) {
      data['floors'] = floors!
          .map(
            (f) => {
              'name': f.name.trim(),
              'floor_number': f.level,
              'rooms': f.rooms
                  .map((r) => {'name': r.trim(), 'type': 'Room'})
                  .toList(),
            },
          )
          .toList();
    }

    return data;
  }
}
