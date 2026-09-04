import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/app_navigation_drawer.dart';
import 'profile_theme.dart';
import 'widgets/profile_details_card.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_home_card.dart';
import 'widgets/profile_logout_button.dart';
import 'widgets/profile_preferences_card.dart';
import 'widgets/profile_stats.dart';
import 'widgets/profile_support_card.dart';
import 'widgets/profile_tariff_card.dart';

/// Smart Homz Profile screen using the Hasomi Light Theme
/// with dynamic data from providers and responsive layout styling.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    if (!mounted) return;
    try {
      final auth = Provider.of<AuthProvider?>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider?>(
        context,
        listen: false,
      );
      final propertyProvider = Provider.of<PropertyProvider?>(
        context,
        listen: false,
      );
      final profileProvider = Provider.of<ProfileProvider?>(
        context,
        listen: false,
      );

      if (profileProvider == null) return;

      final user = auth?.currentUser;

      if (profileProvider.profile == null) {
        profileProvider.loadProfile(
          clientId: auth?.resolvedClientId,
          fallbackEmail: user?.email,
          fallbackName: user?.name,
          fallbackPhone: user?.phone,
          supplementDeviceCount: deviceProvider?.devices.length,
          supplementOnlineDeviceCount: deviceProvider?.onlineCount,
          supplementFloorCount: propertyProvider?.floors.length,
          supplementRoomCount: propertyProvider?.rooms.length,
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshProfileData() async {
    try {
      final auth = Provider.of<AuthProvider?>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider?>(
        context,
        listen: false,
      );
      final propertyProvider = Provider.of<PropertyProvider?>(
        context,
        listen: false,
      );
      final profileProvider = Provider.of<ProfileProvider?>(
        context,
        listen: false,
      );

      if (profileProvider == null) return;

      final user = auth?.currentUser;

      await profileProvider.refresh(
        clientId: auth?.resolvedClientId,
        fallbackEmail: user?.email,
        fallbackName: user?.name,
        fallbackPhone: user?.phone,
        supplementDeviceCount: deviceProvider?.devices.length,
        supplementOnlineDeviceCount: deviceProvider?.onlineCount,
        supplementFloorCount: propertyProvider?.floors.length,
        supplementRoomCount: propertyProvider?.rooms.length,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);
    final profileProvider = Provider.of<ProfileProvider?>(context);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: canPop
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.textPrimary,
                  size: 18,
                ),
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: colors.textPrimary,
                    size: 26,
                  ),
                  tooltip: 'Menu',
                  onPressed: () => openAppDrawer(ctx),
                ),
              ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshProfileData,
          color: colors.accent,
          backgroundColor: colors.panel,
          child: _buildBody(profileProvider, colors),
        ),
      ),
    );
  }

  Widget _buildBody(ProfileProvider? profileProvider, ProfileThemeData colors) {
    if (profileProvider != null &&
        profileProvider.isLoading &&
        profileProvider.profile == null) {
      return _buildLoadingSkeleton(colors);
    }

    if (profileProvider != null &&
        profileProvider.error != null &&
        profileProvider.profile == null) {
      return _buildErrorView(profileProvider.error!, colors);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: const [
        ProfileHero(),
        SizedBox(height: 16),
        ProfileStats(),
        SizedBox(height: 24),
        ProfileHomeCard(),
        SizedBox(height: 24),
        ProfileDetailsCard(),
        SizedBox(height: 24),
        ProfilePreferencesCard(),
        SizedBox(height: 24),
        ProfileTariffCard(),
        SizedBox(height: 24),
        ProfileSupportCard(),
        SizedBox(height: 28),
        ProfileLogoutButton(),
      ],
    );
  }

  Widget _buildLoadingSkeleton(ProfileThemeData colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Hero Skeleton
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Stats Skeleton
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: i == 0 ? 0 : 5,
                  right: i == 2 ? 0 : 5,
                ),
                height: 80,
                decoration: BoxDecoration(
                  color: colors.panel,
                  borderRadius: BorderRadius.circular(
                    ProfileTheme.mediumRadius,
                  ),
                  border: Border.all(color: colors.border),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Cards Skeleton
        Container(
          height: 76,
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            border: Border.all(color: colors.border),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String error, ProfileThemeData colors) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.error_outline_rounded, size: 56, color: colors.danger),
        const SizedBox(height: 16),
        Text(
          'Failed to load profile data',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: _refreshProfileData,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProfileTheme.smallRadius),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}
