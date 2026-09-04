import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/family_provider.dart';
import '../../theme/app_theme.dart';

class FamilyInviteScreen extends StatefulWidget {
  const FamilyInviteScreen({super.key});

  @override
  State<FamilyInviteScreen> createState() => _FamilyInviteScreenState();
}

class _FamilyInviteScreenState extends State<FamilyInviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final clientUuid =
          auth.resolvedClientUuid ??
          auth.resolvedClientId ??
          '6782976c-e9a4-41c9-a754-05e4ba0a97b2';
      context.read<FamilyProvider>().setClientId(clientUuid);
      context.read<FamilyProvider>().fetchMembers(silent: true);
    });
  }

  Future<void> _showInviteModal(
    BuildContext context, {
    String initialMethod = 'email',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FamilyInviteBottomSheet(initialMethod: initialMethod),
    );

    if (result == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Family member invitation sent successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showDevicePermissionsModal(
    BuildContext context,
    FamilyMember member,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MemberDevicePermissionsBottomSheet(member: member),
    );

    if (result == true && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Updated device permissions for ${member.displayName} successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _copyOrShareJoinLink(FamilyMember member) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<FamilyProvider>();
    final joinLink = await provider.getJoinLink(
      member.id,
      fallbackPhone: member.phone,
      fallbackEmail: member.email,
    );

    if (joinLink == null || joinLink.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not generate join link.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final name = member.name ?? 'Family Member';
    final String message =
        'Hi $name! You have been invited to Smart Homez. Join using this link: $joinLink';

    // If phone available, try SMS first, otherwise copy link to clipboard
    if (member.phone != null && member.phone!.trim().isNotEmpty) {
      final cleanPhone = member.phone!.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: {'body': message},
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          return;
        }
      } catch (_) {}
    }

    await Clipboard.setData(ClipboardData(text: joinLink));
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Copied single-use join link for ${member.displayName} to clipboard!',
          ),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final familyProvider = context.watch<FamilyProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final members = familyProvider.members;

    final int totalCount = members.length + 1; // including primary admin

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF0F172A),
            size: 24,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Family & Device Access',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF0F172A),
              size: 24,
            ),
            onPressed: () => familyProvider.fetchMembers(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00A38E),
        onRefresh: () => familyProvider.fetchMembers(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
          children: [
            // Top Hero Card
            _FamilyHeroBanner(
              activeCount: familyProvider.activeMembersCount + 1,
              pendingCount: familyProvider.pendingInvitesCount,
              totalDevicesCount: deviceProvider.devices.length,
              onInviteByEmailTap: () =>
                  _showInviteModal(context, initialMethod: 'email'),
              onInviteByPhoneTap: () =>
                  _showInviteModal(context, initialMethod: 'phone'),
            ),
            const SizedBox(height: 22),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Family Members & Roles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount People',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00A38E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Primary Admin Card (Always displayed at the top)
            _PrimaryAdminCard(
              userName: currentUser?.name ?? 'Primary Owner',
              userPhone: (currentUser?.phone.isNotEmpty == true)
                  ? currentUser!.phone
                  : (currentUser?.email ?? 'admin@omnihome.in'),
              userEmail: currentUser?.email,
              totalDevicesCount: deviceProvider.devices.length,
            ),
            const SizedBox(height: 14),

            // 2. Real Invited Members Section
            if (familyProvider.isLoading && members.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF00A38E)),
                ),
              )
            else if (members.isEmpty)
              _EmptyFamilyView(onInviteTap: () => _showInviteModal(context))
            else
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _FamilyMemberCard(
                    member: member,
                    totalDevicesCount: deviceProvider.devices.length,
                    onGetJoinLink: () => _copyOrShareJoinLink(member),
                    onManagePermissions: () =>
                        _showDevicePermissionsModal(context, member),
                    onToggleAdminRole: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newRole = member.isAdmin ? 'member' : 'admin';
                      final ok = await familyProvider.updateMemberRole(
                        memberId: member.id,
                        role: newRole,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Updated ${member.displayName} role to ${newRole == "admin" ? "Admin" : "Member"}'
                                  : 'Could not update role.',
                            ),
                            backgroundColor: ok
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        );
                      }
                    },
                    onResend: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await familyProvider.resendInvite(
                        member.id,
                        email: member.email,
                        phone: member.phone,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Invitation resent to ${member.displayName} (valid for 30 days)!'
                                  : 'Could not resend invitation.',
                            ),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        );
                      }
                    },
                    onGrantAllDevices: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await familyProvider.grantAllDevicesAccess(
                        memberId: member.id,
                        availableDevices: deviceProvider.devices,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Granted access of all ${deviceProvider.devices.length} devices to ${member.displayName}!'
                                  : 'Failed to update device permissions.',
                            ),
                            backgroundColor: ok
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        );
                      }
                    },
                    onDelete: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Revoke Family Access?'),
                          content: Text(
                            'Are you sure you want to remove ${member.displayName}? This deactivates their login and drops all invite tokens and device permissions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.danger,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Revoke Access'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await familyProvider.removeMember(member.id);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Access revoked for ${member.displayName}',
                              ),
                              backgroundColor: AppColors.textPrimary,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Primary Admin / Owner Card (Pinned at the top)
class _PrimaryAdminCard extends StatelessWidget {
  final String userName;
  final String userPhone;
  final String? userEmail;
  final int totalDevicesCount;

  const _PrimaryAdminCard({
    required this.userName,
    required this.userPhone,
    this.userEmail,
    required this.totalDevicesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with Star badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF00796B),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userEmail?.isNotEmpty == true ? userEmail! : userPhone,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Role Badge: 👑 Primary Admin
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('👑 ', style: TextStyle(fontSize: 10)),
                    Text(
                      'Primary Admin',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Full Owner Access • All $totalDevicesCount Devices',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF15803D)),
                    SizedBox(width: 4),
                    Text(
                      'Active now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dot Matrix Widget for the top-right corner of hero card
class _DotMatrixWidget extends StatelessWidget {
  const _DotMatrixWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        4,
        (r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (c) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top Hero Banner Widget with Invite by Email & Invite by Phone buttons
class _FamilyHeroBanner extends StatelessWidget {
  final int activeCount;
  final int pendingCount;
  final int totalDevicesCount;
  final VoidCallback onInviteByEmailTap;
  final VoidCallback onInviteByPhoneTap;

  const _FamilyHeroBanner({
    required this.activeCount,
    required this.pendingCount,
    required this.totalDevicesCount,
    required this.onInviteByEmailTap,
    required this.onInviteByPhoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF007E72), Color(0xFF009688), Color(0xFF00BFA5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF009688).withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Family Roster & Sharing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Invite family members by email or phone to grant access to home devices, configure roles, and monitor presence.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick Action Invite Buttons (Email vs Phone)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onInviteByEmailTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF007E72),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.email_outlined, size: 16),
                      label: const Text(
                        'Invite by Email',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onInviteByPhoneTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.phone_iphone_rounded, size: 16),
                      label: const Text(
                        'Invite by Phone',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(label: 'Total Active', value: '$activeCount'),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  _StatItem(label: 'Pending Invites', value: '$pendingCount'),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  _StatItem(label: 'Home Devices', value: '$totalDevicesCount'),
                ],
              ),
            ],
          ),
        ),
        const Positioned(right: 18, bottom: 24, child: _DotMatrixWidget()),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Family Member Card
class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final int totalDevicesCount;
  final VoidCallback onGetJoinLink;
  final VoidCallback onToggleAdminRole;
  final VoidCallback onResend;
  final VoidCallback onGrantAllDevices;
  final VoidCallback onManagePermissions;
  final VoidCallback onDelete;

  const _FamilyMemberCard({
    required this.member,
    required this.totalDevicesCount,
    required this.onGetJoinLink,
    required this.onToggleAdminRole,
    required this.onResend,
    required this.onGrantAllDevices,
    required this.onManagePermissions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = member.isPending;
    final bool isAdmin = member.isAdmin;
    final int grantedCount = member.allDevicesGranted
        ? totalDevicesCount
        : (member.permissions.isNotEmpty
              ? member.permissions
                    .where((p) => p.canView || p.canControl)
                    .length
              : totalDevicesCount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: isAdmin
                    ? const Color(0xFFFEF3C7)
                    : (isPending
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFE0F2FE)),
                child: Text(
                  (member.name?.isNotEmpty == true
                          ? member.name![0]
                          : (member.email?.isNotEmpty == true
                                ? member.email![0]
                                : (member.phone?.isNotEmpty == true
                                      ? 'P'
                                      : 'F')))
                      .toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: isAdmin
                        ? const Color(0xFFD97706)
                        : (isPending
                              ? const Color(0xFFB45309)
                              : const Color(0xFF0284C7)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name, Email, Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (member.email != null && member.email!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              member.email!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (member.phone != null && member.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.phone!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAdmin ? '👑 Admin' : 'Member',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isAdmin
                        ? const Color(0xFFB45309)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Options Menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'manage_permissions':
                      onManagePermissions();
                      break;
                    case 'join_link':
                      onGetJoinLink();
                      break;
                    case 'toggle_role':
                      onToggleAdminRole();
                      break;
                    case 'resend':
                      onResend();
                      break;
                    case 'grant_all':
                      onGrantAllDevices();
                      break;
                    case 'revoke':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'manage_permissions',
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: Color(0xFF00A38E),
                        ),
                        SizedBox(width: 10),
                        Text('Manage Device Permissions'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_role',
                    child: Row(
                      children: [
                        Icon(
                          isAdmin
                              ? Icons.person_outline_rounded
                              : Icons.admin_panel_settings_rounded,
                          size: 18,
                          color: isAdmin
                              ? AppColors.textSecondary
                              : const Color(0xFFD97706),
                        ),
                        SizedBox(width: 10),
                        Text(
                          isAdmin
                              ? 'Change to Regular Member'
                              : 'Promote to Admin',
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    const PopupMenuItem(
                      value: 'join_link',
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Text('Get Single-Use Join Link'),
                        ],
                      ),
                    ),
                  if (isPending)
                    const PopupMenuItem(
                      value: 'resend',
                      child: Row(
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 10),
                          Text('Resend Invitation (+30 days)'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'grant_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.devices_rounded,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        SizedBox(width: 10),
                        Text('Grant All Devices Access'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'revoke',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Revoke Access',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: onManagePermissions,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        member.allDevicesGranted
                            ? 'Full Control • All $grantedCount Devices'
                            : '$grantedCount Devices Granted',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Status & Last Presence badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: isPending
                          ? const Color(0xFFB45309)
                          : const Color(0xFF15803D),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPending ? 'Pending' : member.presenceDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isPending
                            ? const Color(0xFFB45309)
                            : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet to Configure Per-Device Permissions for a User
class MemberDevicePermissionsBottomSheet extends StatefulWidget {
  final FamilyMember member;

  const MemberDevicePermissionsBottomSheet({super.key, required this.member});

  @override
  State<MemberDevicePermissionsBottomSheet> createState() =>
      _MemberDevicePermissionsBottomSheetState();
}

class _MemberDevicePermissionsBottomSheetState
    extends State<MemberDevicePermissionsBottomSheet> {
  late Map<String, FamilyDevicePermissionEntry> _permissionMap;
  bool _isSaving = false;
  bool _isLoadingRemote = true;

  @override
  void initState() {
    super.initState();
    final deviceProvider = context.read<DeviceProvider>();
    final devices = deviceProvider.devices;

    _permissionMap = {};

    for (final p in widget.member.permissions) {
      _permissionMap[p.deviceId] = p;
    }

    for (final d in devices) {
      if (!_permissionMap.containsKey(d.deviceId)) {
        _permissionMap[d.deviceId] = FamilyDevicePermissionEntry(
          deviceId: d.deviceId,
          deviceName: d.name,
          canView: widget.member.allDevicesGranted,
          canControl: widget.member.allDevicesGranted,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final remotePerms = await context
          .read<FamilyProvider>()
          .fetchMemberDevicePermissions(widget.member.id);
      if (mounted) {
        setState(() {
          _isLoadingRemote = false;
          if (remotePerms.isNotEmpty) {
            for (final p in remotePerms) {
              _permissionMap[p.deviceId] = p;
            }
          }
        });
      }
    });
  }

  void _toggleAll(bool enabled) {
    setState(() {
      final deviceProvider = context.read<DeviceProvider>();
      for (final d in deviceProvider.devices) {
        _permissionMap[d.deviceId] = FamilyDevicePermissionEntry(
          deviceId: d.deviceId,
          deviceName: d.name,
          canView: enabled,
          canControl: enabled,
        );
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final familyProvider = context.read<FamilyProvider>();
    final deviceProvider = context.read<DeviceProvider>();

    final permissionsList = _permissionMap.values.toList();
    final success = await familyProvider.updateMemberDevicePermissions(
      memberId: widget.member.id,
      permissions: permissionsList,
      totalAvailableDevicesCount: deviceProvider.devices.length,
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            familyProvider.errorMessage ??
                'Failed to update device permissions.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  IconData _getDeviceIcon(dynamic type) {
    final t = (type?.toString() ?? '').toLowerCase();
    if (t.contains('light') || t.contains('lamp') || t.contains('bulb')) {
      return Icons.lightbulb_rounded;
    } else if (t.contains('fan')) {
      return Icons.mode_fan_off_rounded;
    } else if (t.contains('ac') || t.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (t.contains('plug') || t.contains('socket')) {
      return Icons.power_rounded;
    } else if (t.contains('sensor') ||
        t.contains('smoke') ||
        t.contains('fire')) {
      return Icons.sensors_rounded;
    } else if (t.contains('camera')) {
      return Icons.videocam_rounded;
    } else if (t.contains('lock') || t.contains('door')) {
      return Icons.lock_rounded;
    }
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devices;

    final activeCount = _permissionMap.values
        .where((p) => p.canView || p.canControl)
        .length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF00A38E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Access Permissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure per-device permissions for ${widget.member.displayName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick actions bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Text(
                  '$activeCount of ${devices.length} Devices Granted',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _toggleAll(true),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Grant All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00A38E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _toggleAll(false),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Revoke All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Devices List
          Flexible(
            child: _isLoadingRemote
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: Color(0xFF00A38E),
                      ),
                    ),
                  )
                : devices.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No devices found for this property.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final dev = devices[i];
                      final perm =
                          _permissionMap[dev.deviceId] ??
                          FamilyDevicePermissionEntry(
                            deviceId: dev.deviceId,
                            deviceName: dev.name,
                            canView: false,
                            canControl: false,
                          );

                      final isAnyOn = perm.canView || perm.canControl;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isAnyOn
                              ? const Color(0xFFF9FBFA)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAnyOn
                                ? const Color(
                                    0xFF00A38E,
                                  ).withValues(alpha: 0.35)
                                : const Color(0xFFE2E8F0),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isAnyOn
                                    ? const Color(0xFFE6F7F5)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getDeviceIcon(dev.type),
                                color: isAnyOn
                                    ? const Color(0xFF00A38E)
                                    : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dev.name.isNotEmpty
                                        ? dev.name
                                        : 'Device #${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dev.roomName?.isNotEmpty == true
                                        ? dev.roomName!
                                        : 'Home Device',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // View switch
                            _PermissionChip(
                              label: 'View',
                              isActive: perm.canView,
                              onTap: () {
                                setState(() {
                                  _permissionMap[dev.deviceId] = perm.copyWith(
                                    canView: !perm.canView,
                                  );
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            // Control switch
                            _PermissionChip(
                              label: 'Control',
                              isActive: perm.canControl,
                              onTap: () {
                                setState(() {
                                  _permissionMap[dev.deviceId] = perm.copyWith(
                                    canControl: !perm.canControl,
                                    canView: !perm.canControl
                                        ? true
                                        : perm.canView,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A38E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Permissions',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PermissionChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00A38E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

/// Empty view when no members exist yet
class _EmptyFamilyView extends StatelessWidget {
  final VoidCallback onInviteTap;

  const _EmptyFamilyView({required this.onInviteTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F7F5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 34,
                    color: Color(0xFF00A38E),
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: -12,
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA7F3D0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Positioned(
                top: 4,
                right: -12,
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA7F3D0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Positioned(
                bottom: 2,
                right: -4,
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA7F3D0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'No Invited Family Members Yet',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You are the primary admin. Tap below to invite family members by email or phone, assign Admin or Member roles, and grant home device permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onInviteTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A38E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text(
                'Invite Family Member',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Invite Modal Bottom Sheet (Email vs Phone Switcher + Role Selector + All Devices Grant)
class FamilyInviteBottomSheet extends StatefulWidget {
  final String initialMethod; // 'email' or 'phone'

  const FamilyInviteBottomSheet({super.key, this.initialMethod = 'email'});

  @override
  State<FamilyInviteBottomSheet> createState() =>
      _FamilyInviteBottomSheetState();
}

class _FamilyInviteBottomSheetState extends State<FamilyInviteBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  late String _inviteMethod; // 'email' or 'phone'
  String _accessLevel = 'member'; // 'member' or 'admin'
  bool _giveAllDevicesAccess = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _inviteMethod = widget.initialMethod;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final familyProvider = context.read<FamilyProvider>();
    final deviceProvider = context.read<DeviceProvider>();

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    final result = await familyProvider.inviteMember(
      email: email.isNotEmpty ? email : null,
      phone: phone.isNotEmpty ? phone : null,
      name: name.isNotEmpty ? name : null,
      role: _accessLevel,
      grantAllDevices: _giveAllDevicesAccess,
      availableDevices: deviceProvider.devices,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context, true);

      // Offer single-use join link
      final joinLink = await familyProvider.getJoinLink(
        result.id,
        fallbackEmail: email,
        fallbackPhone: phone,
      );

      if (joinLink != null && joinLink.isNotEmpty && mounted) {
        final memberName = name.isNotEmpty ? name : 'Family Member';
        final message =
            'Hi $memberName! You have been invited to Smart Homez. Open access link: $joinLink';

        if (_inviteMethod == 'phone' && phone.isNotEmpty) {
          final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
          final smsUri = Uri(
            scheme: 'sms',
            path: cleanPhone,
            queryParameters: {'body': message},
          );
          try {
            if (await canLaunchUrl(smsUri)) {
              await launchUrl(smsUri);
            } else {
              await Clipboard.setData(ClipboardData(text: joinLink));
            }
          } catch (_) {
            await Clipboard.setData(ClipboardData(text: joinLink));
          }
        } else {
          await Clipboard.setData(ClipboardData(text: joinLink));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            familyProvider.errorMessage ?? 'Failed to send invite.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devices;
    final bool isEmail = _inviteMethod == 'email';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        16,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite Family Member',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose email or phone to grant device access',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Segmented Method Switcher (Invite by Email vs Invite by Phone)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _inviteMethod = 'email'),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isEmail ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isEmail
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: isEmail
                                    ? const Color(0xFF007E72)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Invite by Email',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isEmail
                                      ? const Color(0xFF007E72)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _inviteMethod = 'phone'),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isEmail ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !isEmail
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_iphone_rounded,
                                size: 16,
                                color: !isEmail
                                    ? const Color(0xFF007E72)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Invite by Phone',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: !isEmail
                                      ? const Color(0xFF007E72)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Dynamic Primary Input Field
              if (isEmail) ...[
                // Email Address Field (REQUIRED when inviting by email)
                const Text(
                  'Email Address *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. member@example.com',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Please enter the email address to invite.';
                    }
                    if (!text.contains('@') || !text.contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number (Optional)
                const Text(
                  'Phone Number (Optional)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+91 98765 43210',
                    prefixIcon: const Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Phone Number Field (REQUIRED when inviting by phone)
                const Text(
                  'Phone Number *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '+91 98765 43210',
                    prefixIcon: const Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Please enter the phone number to invite.';
                    }
                    final digits = text.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) {
                      return 'Please enter a valid phone number (at least 10 digits).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Address (Optional)
                const Text(
                  'Email Address (Optional)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'e.g. member@example.com',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Member Name (OPTIONAL)
              const Text(
                'Member Name (Optional)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Dad, Priya, Brother',
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Access Role Selector (Member vs Admin)
              const Text(
                'Access Role',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _accessLevel = 'member'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _accessLevel == 'member'
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _accessLevel == 'member'
                                ? const Color(0xFF0284C7)
                                : AppColors.divider,
                            width: _accessLevel == 'member' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: _accessLevel == 'member'
                                  ? const Color(0xFF0284C7)
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Family Member',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _accessLevel == 'member'
                                    ? const Color(0xFF0369A1)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _accessLevel = 'admin'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _accessLevel == 'admin'
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _accessLevel == 'admin'
                                ? const Color(0xFFD97706)
                                : AppColors.divider,
                            width: _accessLevel == 'admin' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 16,
                              color: _accessLevel == 'admin'
                                  ? const Color(0xFFD97706)
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _accessLevel == 'admin'
                                    ? const Color(0xFFB45309)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Give Access of All Devices Toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFBBF7D0),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.select_all_rounded,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Give Access to All Devices',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14532D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Grants ON/OFF & controls for all ${devices.length} home devices',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _giveAllDevicesAccess,
                      activeTrackColor: const Color(0xFF16A34A),
                      activeThumbColor: Colors.white,
                      onChanged: (val) {
                        setState(() => _giveAllDevicesAccess = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Device List Preview Box
              if (_giveAllDevicesAccess && devices.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${devices.length} Devices included: ${devices.take(4).map((d) => d.name).join(", ")}${devices.length > 4 ? " +${devices.length - 4} more" : ""}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEmail
                                  ? Icons.email_rounded
                                  : Icons.phone_iphone_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEmail
                                  ? 'Send Email Invite & Grant Access'
                                  : 'Send Phone Invite & Grant Access',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
