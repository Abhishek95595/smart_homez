import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_profile.dart';
import '../models/home_model.dart';
import '../services/profile_service.dart';

class AvatarOption {
  final String id;
  final String name;
  final String description;
  final String assetPath;

  const AvatarOption({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
  });
}

/// Provider managing the Profile screen's state, API caching, and companion avatar selection.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;
  static const String avatarPrefKey = 'smart_homz_avatar_id';
  static const String defaultAvatarId = 'smart_robot';

  static const List<AvatarOption> availableAvatars = [
    AvatarOption(
      id: 'smart_robot',
      name: 'Neo',
      description: 'Intelligent Automation Core',
      assetPath: 'assets/images/smart_robot.png',
    ),
    AvatarOption(
      id: 'new_robot',
      name: 'Aura',
      description: 'Futuristic Home Assistant',
      assetPath: 'assets/images/new_robot.png',
    ),
    AvatarOption(
      id: 'fire_safety',
      name: 'Pyro',
      description: 'Fire & Thermal Guardian',
      assetPath: 'assets/images/fire_safety_robot_ref.png',
    ),
    AvatarOption(
      id: 'water_robot',
      name: 'Aqua',
      description: 'Water Flow Sentinel',
      assetPath: 'assets/images/water_robot_ref.png',
    ),
    AvatarOption(
      id: 'fire_assistant',
      name: 'Spark',
      description: 'Emergency Dispatch Unit',
      assetPath: 'assets/images/fire_assistant_robot_ref.png',
    ),
    AvatarOption(
      id: 'water_assistant',
      name: 'Hydro',
      description: 'Hydro-Pressure Engine',
      assetPath: 'assets/images/water_assistant_robot_ref.png',
    ),
  ];

  ClientProfile? _profile;
  List<HomeModel> _homes = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String _selectedAvatarId = defaultAvatarId;

  int _deviceCount = 0;
  int _onlineDeviceCount = 0;
  int _floorCount = 0;
  int _roomCount = 0;

  ClientProfile? get profile => _profile;
  List<HomeModel> get homes => _homes;
  HomeModel? get activeHome => _homes.isNotEmpty ? _homes.first : null;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String get selectedAvatarId => _selectedAvatarId;

  AvatarOption get currentAvatar {
    return availableAvatars.firstWhere(
      (a) => a.id == _selectedAvatarId,
      orElse: () => availableAvatars.first,
    );
  }

  int get deviceCount => _deviceCount;
  int get onlineDeviceCount => _onlineDeviceCount;
  int get floorCount => _floorCount;
  int get roomCount => _roomCount;

  double get onlineRatio {
    if (_deviceCount <= 0) return 0.0;
    return (_onlineDeviceCount / _deviceCount).clamp(0.0, 1.0);
  }

  ProfileProvider({ProfileService? profileService})
    : _profileService = profileService ?? ProfileService() {
    _loadSavedAvatar();
  }

  Future<void> _loadSavedAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(avatarPrefKey);
      if (savedId != null && availableAvatars.any((a) => a.id == savedId)) {
        _selectedAvatarId = savedId;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> selectAvatar(String avatarId) async {
    if (_selectedAvatarId == avatarId) return;
    _selectedAvatarId = avatarId;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(avatarPrefKey, avatarId);
    } catch (_) {}
  }

  /// Concurrently loads client profile and home hierarchy using Future.wait.
  Future<void> loadProfile({
    String? clientId,
    String? fallbackEmail,
    String? fallbackName,
    String? fallbackPhone,
    int? supplementDeviceCount,
    int? supplementOnlineDeviceCount,
    int? supplementFloorCount,
    int? supplementRoomCount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (supplementDeviceCount != null && supplementDeviceCount > 0) {
      _deviceCount = supplementDeviceCount;
    }
    if (supplementOnlineDeviceCount != null &&
        supplementOnlineDeviceCount > 0) {
      _onlineDeviceCount = supplementOnlineDeviceCount;
    }
    if (supplementFloorCount != null && supplementFloorCount > 0) {
      _floorCount = supplementFloorCount;
    }
    if (supplementRoomCount != null && supplementRoomCount > 0) {
      _roomCount = supplementRoomCount;
    }

    if (clientId == null || !_profileService.isValidClientUuid(clientId)) {
      _synthesizeFallbackProfile(
        id: clientId ?? '',
        name: fallbackName ?? 'Smart Home User',
        email: fallbackEmail,
        phone: fallbackPhone,
      );
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final results = await Future.wait([
        _profileService.getClientProfile(clientId),
        _profileService.getClientHomes(clientId),
      ]);

      final fetchedProfile = results[0] as ClientProfile?;
      final fetchedHomes = results[1] as List<HomeModel>?;

      if (fetchedProfile != null) {
        _profile = fetchedProfile;
        if (fetchedProfile.deviceCount > 0) {
          _deviceCount = fetchedProfile.deviceCount;
          _onlineDeviceCount = fetchedProfile.onlineDeviceCount;
        }
      } else {
        _synthesizeFallbackProfile(
          id: clientId,
          name: fallbackName ?? 'Smart Home User',
          email: fallbackEmail,
          phone: fallbackPhone,
        );
      }

      if (fetchedHomes != null && fetchedHomes.isNotEmpty) {
        _homes = fetchedHomes;
      }
    } catch (e) {
      _error = 'Failed to load profile details.';
      _synthesizeFallbackProfile(
        id: clientId,
        name: fallbackName ?? 'Smart Home User',
        email: fallbackEmail,
        phone: fallbackPhone,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({
    String? clientId,
    String? fallbackEmail,
    String? fallbackName,
    String? fallbackPhone,
    int? supplementDeviceCount,
    int? supplementOnlineDeviceCount,
    int? supplementFloorCount,
    int? supplementRoomCount,
  }) async {
    _isRefreshing = true;
    notifyListeners();

    await loadProfile(
      clientId: clientId,
      fallbackEmail: fallbackEmail,
      fallbackName: fallbackName,
      fallbackPhone: fallbackPhone,
      supplementDeviceCount: supplementDeviceCount,
      supplementOnlineDeviceCount: supplementOnlineDeviceCount,
      supplementFloorCount: supplementFloorCount,
      supplementRoomCount: supplementRoomCount,
    );

    _isRefreshing = false;
    notifyListeners();
  }

  void _synthesizeFallbackProfile({
    required String id,
    required String name,
    String? email,
    String? phone,
  }) {
    _profile = ClientProfile(
      id: id,
      name: name,
      email: email,
      phone: phone,
      isActive: true,
      homeCount: _homes.isNotEmpty ? _homes.length : 0,
      deviceCount: _deviceCount,
      onlineDeviceCount: _onlineDeviceCount,
    );
  }

  @visibleForTesting
  void setProfileForTesting({
    required ClientProfile profile,
    List<HomeModel>? homes,
    int? deviceCount,
    int? onlineDeviceCount,
    int? floorCount,
    int? roomCount,
  }) {
    _profile = profile;
    if (homes != null) _homes = homes;
    if (deviceCount != null) _deviceCount = deviceCount;
    if (onlineDeviceCount != null) _onlineDeviceCount = onlineDeviceCount;
    if (floorCount != null) _floorCount = floorCount;
    if (roomCount != null) _roomCount = roomCount;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
