import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.resident;
  bool _loading = false;
  bool _obscureSecret = true;

  final _clientIdCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(text: 'demo@smarthomez.in');
  final _passCtrl = TextEditingController(text: '••••••••');

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _secretCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    
    final clientId = _clientIdCtrl.text.trim();
    final secret = _secretCtrl.text.trim();
    
    String? error;
    
    if (clientId.isNotEmpty && secret.isNotEmpty) {
      // Manual API login
      error = await context.read<AuthProvider>().loginWithApi(
        clientId, 
        secret, 
        _selectedRole,
        propertyProvider: context.read<PropertyProvider>(),
        deviceProvider: context.read<DeviceProvider>(),
      );
    } else {
      // Fallback to demo login
      await context.read<AuthProvider>().loginAs(_selectedRole);
    }
    
    if (!mounted) return;
    setState(() => _loading = false);
    
    if (error == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.critical,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final verticalPadding = wide ? 38.0 : 24.0;
            final availableHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight - (verticalPadding * 2)
                : 0.0;
            final safeMinHeight = availableHeight > 0 ? availableHeight : 0.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 20,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: safeMinHeight,
                  maxWidth: 1160,
                ),
                child: Center(
                  child: wide
                      ? Row(
                          children: [
                            const Expanded(child: _ProductIntroduction()),
                            const SizedBox(width: 64),
                            SizedBox(width: 420, child: _loginCard()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _MobileBrand(),
                            const SizedBox(height: 24),
                            _loginCard(),
                            const SizedBox(height: 26),
                            const _PropertyMiniPreview(),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1414161F),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect to Backend',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your Client ID and Secret to sync with real data.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: 26),
          const _FormLabel('Client ID'),
          TextField(
            controller: _clientIdCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. anvyaaai_567A',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          const _FormLabel('Client Secret'),
          TextField(
            controller: _secretCtrl,
            obscureText: _obscureSecret,
            decoration: InputDecoration(
              hintText: 'Enter your API secret',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                tooltip: _obscureSecret ? 'Show secret' : 'Hide secret',
                onPressed: () =>
                    setState(() => _obscureSecret = !_obscureSecret),
                icon: Icon(
                  _obscureSecret
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'OR USE DEMO ACCESS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserRole.values.map((role) {
              final selected = role == _selectedRole;
              return ChoiceChip(
                label: Text(role.label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedRole = role),
                selectedColor: AppColors.primarySoft,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _login,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(_clientIdCtrl.text.isNotEmpty ? 'Connect & Sign In' : 'Sign In as Demo'),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: AppColors.textFaint),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Encrypted connection to saajsajja.in',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductIntroduction extends StatelessWidget {
  const _ProductIntroduction();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _BrandLockup(),
        const SizedBox(height: 44),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '⚡ HOMES · APARTMENTS · OFFICES',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'One app to run your\nsmart property.',
          style: TextStyle(
            fontSize: 42,
            height: 1.12,
            letterSpacing: -1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Map floors and rooms, connect devices, automate routines, '
          'and keep safety at the centre of every property.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 28),
        const _TrustRow(),
        const SizedBox(height: 34),
        const _PropertyMiniPreview(),
      ],
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandLockup(),
        SizedBox(height: 20),
        Text(
          'Your entire property,\none calm dashboard.',
          style: TextStyle(
            fontSize: 29,
            height: 1.15,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Smart Building Manager',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Homez',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              'BY AURABRAIN TECHNOLOGIES',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 8.5,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 22,
      runSpacing: 10,
      children: [
        _TrustItem(icon: Icons.shield_outlined, label: 'Safety first'),
        _TrustItem(icon: Icons.hub_outlined, label: 'Backend ready'),
        _TrustItem(
          icon: Icons.notifications_active_outlined,
          label: 'Live alerts',
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textFaint),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textFaint, fontSize: 12),
        ),
      ],
    );
  }
}

class _PropertyMiniPreview extends StatelessWidget {
  const _PropertyMiniPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C14161F),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'YOUR PROPERTIES',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.circle, color: AppColors.success, size: 8),
            ],
          ),
          SizedBox(height: 12),
          _PreviewProperty(
            icon: Icons.home_rounded,
            color: AppColors.primary,
            name: 'Lakeview Home',
            details: '4 floors · 18 rooms · 62 devices',
          ),
          SizedBox(height: 9),
          _PreviewProperty(
            icon: Icons.apartment_rounded,
            color: AppColors.accentTeal,
            name: 'Willow Apartments',
            details: '6 floors · 24 units · 210 devices',
          ),
          SizedBox(height: 9),
          _PreviewProperty(
            icon: Icons.business_center_rounded,
            color: Color(0xFF3B82F6),
            name: 'AuraBrain HQ',
            details: '3 floors · 40 workspaces · 96 devices',
          ),
        ],
      ),
    );
  }
}

class _PreviewProperty extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String details;

  const _PreviewProperty({
    required this.icon,
    required this.color,
    required this.name,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Online',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}
