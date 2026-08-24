import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_dashboard_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/energy_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../screens/main_shell.dart';
import '../../../theme/app_theme.dart';
import '../providers/home_setup_provider.dart';
import '../widgets/device_assignment_step.dart';
import '../widgets/layout_selection_step.dart';

class HomeSetupScreen extends StatefulWidget {
  const HomeSetupScreen({super.key});

  @override
  State<HomeSetupScreen> createState() => _HomeSetupScreenState();
}

class _HomeSetupScreenState extends State<HomeSetupScreen> {
  Future<bool> _confirmAbandon(
    BuildContext context,
    HomeSetupProvider provider,
  ) async {
    // If on Step 0 and clean, allow popping immediately
    if (provider.currentStep == 0 && provider.createdHome == null) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Setup Wizard?'),
        content: Text(
          provider.createdHome != null
              ? 'Your home "${provider.createdHome!.home.name}" was created, but unassigned devices have not been saved yet. You can assign devices later.'
              : 'Are you sure you want to exit? Your unsaved setup progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Setup'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit Setup'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleCompletion(
    BuildContext context,
    HomeSetupProvider setupProvider,
  ) async {
    final auth = context.read<AuthProvider>();
    final clientId = auth.resolvedClientId;

    if (clientId != null && clientId.isNotEmpty) {
      // Refresh providers asynchronously
      final propertyProvider = context.read<PropertyProvider>();
      final deviceProvider = context.read<DeviceProvider>();
      final energyProvider = context.read<EnergyProvider>();
      final dashboardProvider = context.read<ClientDashboardProvider>();

      await Future.wait([
        propertyProvider.syncFromApi(clientId),
        deviceProvider.syncFromApi(clientId),
      ]);

      if (setupProvider.createdHome != null) {
        energyProvider.fetchDashboard(
          clientId: clientId,
          homeId: setupProvider.createdHome!.home.id,
        );
        dashboardProvider.load(
          clientId: clientId,
          homeId: setupProvider.createdHome!.home.id,
        );
      }
    }

    final createdHomeName = setupProvider.createdHome?.home.name ?? 'Home';
    setupProvider.reset();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryDark,
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Setup complete! "$createdHomeName" is ready.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );

    // Navigate to Dashboard
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final role = user?.role ?? UserRole.resident;
    final bool canManage = role.canManageProperties || role.canAdminister;

    final setupProvider = context.watch<HomeSetupProvider>();
    final int currentStep = setupProvider.currentStep;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmAbandon(context, setupProvider);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldPop = await _confirmAbandon(context, setupProvider);
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            'One-Click Home Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Read-only Permission Banner (if user cannot manage)
              if (!canManage) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: const Color(0xFFFFF3CD),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF856404),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'View-only mode: Administrator or manager permissions are required to create homes.',
                          style: TextStyle(
                            color: Color(0xFF856404),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 2-Step Progress Indicator
              _WizardProgressBar(currentStep: currentStep),

              // Active Step Body
              Expanded(
                child: currentStep == 0
                    ? LayoutSelectionStep(
                        provider: setupProvider,
                        canManage: canManage,
                      )
                    : DeviceAssignmentStep(
                        provider: setupProvider,
                        canManage: canManage,
                        onComplete: () =>
                            _handleCompletion(context, setupProvider),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WizardProgressBar extends StatelessWidget {
  final int currentStep;

  const _WizardProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Step 1 Indicator
          _StepIndicatorItem(
            stepNumber: 1,
            label: 'Layout',
            isActive: currentStep >= 0,
            isCompleted: currentStep > 0,
          ),
          // Connector Line
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: currentStep > 0 ? AppColors.primary : AppColors.divider,
            ),
          ),
          // Step 2 Indicator
          _StepIndicatorItem(
            stepNumber: 2,
            label: 'Devices',
            isActive: currentStep >= 1,
            isCompleted: currentStep > 1,
          ),
        ],
      ),
    );
  }
}

class _StepIndicatorItem extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicatorItem({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor = isCompleted
        ? AppColors.primary
        : (isActive ? AppColors.primary : AppColors.surfaceElevated);
    final Color textColor = isCompleted || isActive
        ? Colors.white
        : AppColors.textSecondary;
    final Color labelColor = isActive
        ? AppColors.primaryDark
        : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.divider,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
