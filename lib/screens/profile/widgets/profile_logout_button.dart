import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';
import '../profile_theme.dart';

/// Prominent red-tinted logout button executing the existing
/// AuthProvider logout flow and resetting navigation history.
class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({super.key});

  void _confirmLogout(BuildContext context) {
    final colors = ProfileTheme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: colors.danger, size: 22),
              const SizedBox(width: 10),
              Text(
                'Log out?',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            "You'll need to sign in again to access your Smart Homz account.",
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ProfileTheme.smallRadius),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);

    final Color borderColor = colors.isDark
        ? colors.danger.withValues(alpha: 0.30)
        : const Color(0x40D94A4A);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.danger,
          textStyle: TextStyle(
            color: colors.danger,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: colors.dangerSoft,
          side: BorderSide(color: borderColor, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProfileTheme.mediumRadius),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Log Out'),
      ),
    );
  }
}
