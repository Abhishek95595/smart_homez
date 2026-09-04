import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../alerts/alerts_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _lastUpdated = 'August 9, 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Alerts',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
                );
              },
              icon: const _NotificationIcon(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            const _PolicyHero(lastUpdated: _lastUpdated),
            const SizedBox(height: 30),
            const _SectionHeading('Introduction'),
            const SizedBox(height: 12),
            const _BodyText(
              'Welcome to Hasomi, a smart-property monitoring and '
              'automation platform. This Privacy Policy explains how '
              'information is handled when you use the Hasomi mobile '
              'application and connected services.',
            ),
            const SizedBox(height: 24),
            const _PolicyCard(
              icon: Icons.inventory_2_outlined,
              title: 'Information We Collect',
              bullets: [
                'Account information such as your name, email address and phone number when provided.',
                'Property hierarchy information including homes, floors, rooms and assigned access.',
                'Connected-device information, device state, telemetry and configuration details.',
                'Energy, water, alert, automation and routine data used to provide app features.',
                'Technical information needed for authentication, reliability and troubleshooting.',
              ],
            ),
            const SizedBox(height: 16),
            const _PolicyCard(
              icon: Icons.query_stats_rounded,
              title: 'How We Use Your Information',
              bullets: [
                'Operate, maintain and improve Hasomi features.',
                'Display property, device, energy and water insights relevant to your account.',
                'Run device controls, routines and automations that you configure.',
                'Deliver safety, device-status and system alerts.',
                'Authenticate users, enforce permissions and protect connected properties.',
                'Investigate service issues and maintain platform reliability.',
              ],
            ),
            const SizedBox(height: 16),
            const _PolicyCard(
              icon: Icons.shield_outlined,
              title: 'Data Security',
              bullets: [
                'We use reasonable technical and organizational safeguards designed to protect account and smart-home data.',
                'Access should be restricted according to the permissions assigned to each user role.',
                'No electronic transmission or storage system can be guaranteed to be completely secure.',
              ],
            ),
            const SizedBox(height: 16),
            const _PolicyCard(
              icon: Icons.share_outlined,
              title: 'Data Sharing and Third-Party Services',
              bullets: [
                'Information may be processed by services required to provide authentication, cloud connectivity, notifications or integrations.',
                'Connected vendor or voice-assistant integrations may receive information necessary to perform actions you request.',
                'Information may also be disclosed when required by applicable law or to protect users, property or the service.',
              ],
            ),
            const SizedBox(height: 16),
            const _PolicyCard(
              icon: Icons.manage_accounts_outlined,
              title: 'Your Choices and Access',
              bullets: [
                'Keep your account and property information accurate through the available profile and management controls.',
                'Disable automations, integrations or connected devices when you no longer want them active.',
                'Contact your Hasomi administrator or support team for account-access or privacy requests.',
              ],
            ),
            const SizedBox(height: 28),
            _SupportCard(onContact: () => _showSupportDialog(context)),
            const SizedBox(height: 24),
            const Text(
              'This in-app policy should be reviewed against your production '
              'backend, third-party integrations and applicable legal '
              'requirements before public release.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Privacy Support'),
            ],
          ),
          content: const Text(
            'For privacy, account-access or data questions, contact the '
            'Hasomi administrator or support contact provided by your '
            'organization.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textPrimary,
          size: 28,
        ),
        Positioned(
          right: 1,
          top: 0,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.accentTeal,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyHero extends StatelessWidget {
  final String lastUpdated;

  const _PolicyHero({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.primary,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Your privacy is important to us.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Last updated: $lastUpdated',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontSize: 19,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.25,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;

  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.55,
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;

  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BulletText(text: bullet),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  final VoidCallback onContact;

  const _SupportCard({required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBDEDE6)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFD4F5F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Need Help?',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'For questions about privacy, account access or data handling, '
            'contact your Hasomi administrator or support team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
            label: const Text('Contact Support'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
