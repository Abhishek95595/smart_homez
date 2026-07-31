class AuthLoginRequest {
  final String email;
  final String password;

  AuthLoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class AuthLoginResponse {
  final String token;

  AuthLoginResponse({required this.token});

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    return AuthLoginResponse(
      token: json['token'] as String,
    );
  }
}

class ClientResolveRequest {
  final String? email;
  final String? phone;
  final String? name;

  ClientResolveRequest({this.email, this.phone, this.name});

  Map<String, dynamic> toJson() => {
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (name != null) 'name': name,
  };
}

class ClientResolveResponse {
  final String id;
  final String? name;
  final String? email;

  ClientResolveResponse({required this.id, this.name, this.email});

  factory ClientResolveResponse.fromJson(Map<String, dynamic> json) {
    return ClientResolveResponse(
      id: json['client_id'] as String,
      name: json['client_name'] as String?,
      email: json['email'] as String?,
    );
  }
}

class CreateHomeRequest {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  CreateHomeRequest({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

class CreateFloorRequest {
  final String name;
  final int floorNumber;

  CreateFloorRequest({required this.name, required this.floorNumber});

  Map<String, dynamic> toJson() => {
    'name': name,
    'floor_number': floorNumber,
  };
}

class CreateRoomRequest {
  final String name;

  CreateRoomRequest({required this.name});

  Map<String, dynamic> toJson() => {
    'name': name,
  };
}

class ApiHomeResponse {
  final String id;
  final String name;
  final String address;

  ApiHomeResponse({required this.id, required this.name, required this.address});

  factory ApiHomeResponse.fromJson(Map<String, dynamic> json) {
    return ApiHomeResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
    );
  }
}

class ApiFloorResponse {
  final String id;
  final String name;
  final int floorNumber;

  ApiFloorResponse({required this.id, required this.name, required this.floorNumber});

  factory ApiFloorResponse.fromJson(Map<String, dynamic> json) {
    return ApiFloorResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      floorNumber: (json['floor_number'] as num).toInt(),
    );
  }
}

class ApiRoomResponse {
  final String id;
  final String name;

  ApiRoomResponse({required this.id, required this.name});

  factory ApiRoomResponse.fromJson(Map<String, dynamic> json) {
    return ApiRoomResponse(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class ApiDeviceResponse {
  final String id;
  final String name;
  final String? type;
  final String? status;
  final String? homeId;
  final String? floorId;
  final String? roomId;
  final String? zone;

  ApiDeviceResponse({
    required this.id,
    required this.name,
    this.type,
    this.status,
    this.homeId,
    this.floorId,
    this.roomId,
    this.zone,
  });

  factory ApiDeviceResponse.fromJson(Map<String, dynamic> json) {
    return ApiDeviceResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String?,
      status: json['status'] as String?,
      homeId: json['home_id'] as String?,
      floorId: json['floor_id'] as String?,
      roomId: json['room_id'] as String?,
      zone: json['zone'] as String?,
    );
  }
}
