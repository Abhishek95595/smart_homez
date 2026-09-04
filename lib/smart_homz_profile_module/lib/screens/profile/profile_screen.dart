import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/property_provider.dart';
import 'profile_theme.dart';
import 'widgets/profile_details_card.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_home_card.dart';
import 'widgets/profile_logout_button.dart';
import 'widgets/profile_stats.dart';
import 'widgets/profile_support_card.dart';

/// Redesigned Smart Homz Profile screen using Hasomi Light Theme
/// with dynamic data from the AuraBrain Tenant API and responsive preferences.
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
        centerTitle: true,
        leading: canPop
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.textPrimary,
                  size: 18,
                ),
              )
            : null,
        title: Text(
          'Profile',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: const [
        ProfileHero(),
        SizedBox(height: 16),
        ProfileStats(),
        SizedBox(height: 22),
        ProfileHomeCard(),
        SizedBox(height: 22),
        ProfileDetailsCard(),
        SizedBox(height: 22),
        ProfileSupportCard(),
        SizedBox(height: 28),
        ProfileLogoutButton(),
      ],
    );
  }

  Widget _buildLoadingSkeleton(ProfileThemeData colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Hero Skeleton
        Container(
          height: 260,
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
        const SizedBox(height: 22),
        // Cards Skeleton
        Container(
          height: 76,
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            border: Border.all(color: colors.border),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            border: Border.all(color: colors.border),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String errorMessage, ProfileThemeData colors) {
    final Color retryTextColor = Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_off_rounded,
                        color: colors.danger,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load profile',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadProfileData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: retryTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ProfileTheme.smallRadius,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
