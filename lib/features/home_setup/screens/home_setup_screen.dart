import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/property_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/hasomi_bottom_voice_bar.dart';
import '../data/models/home_layout_template.dart';
import '../providers/home_setup_provider.dart';
import '../widgets/layout_selection_step.dart';
import '../widgets/property_info_step.dart';
import '../widgets/property_review_step.dart';
import '../widgets/property_success_screen.dart';
import '../widgets/rooms_review_step.dart';

class HomeSetupScreen extends StatefulWidget {
  const HomeSetupScreen({super.key});

  @override
  State<HomeSetupScreen> createState() => _HomeSetupScreenState();
}

class _HomeSetupScreenState extends State<HomeSetupScreen> {
  Future<bool> _confirmAbandon(BuildContext context) async {
    final shouldAbandon = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Abandon Property Setup?'),
        content: const Text(
          'Your property details will not be saved if you leave now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
    return shouldAbandon ?? false;
  }

  void _handleCtaTap(
    HomeSetupProvider provider,
    PropertyProvider propertyProvider,
  ) {
    if (provider.currentStep == 0) {
      if (provider.propertyName.trim().isEmpty) {
        provider.setPropertyName(provider.propertyName);
        return;
      }
      provider.goNext();
    } else if (provider.currentStep == 1) {
      provider.goNext();
    } else if (provider.currentStep == 2) {
      provider.goNext();
    } else if (provider.currentStep == 3) {
      provider.submitPropertyCreation(propertyProvider: propertyProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupProvider = context.watch<HomeSetupProvider>();
    final propertyProvider = context.read<PropertyProvider>();

    if (setupProvider.isCompleted) {
      return PropertySuccessScreen(
        provider: setupProvider,
        onOpenProperty: () {
          setupProvider.reset();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    final currentStep = setupProvider.currentStep;
    final isResidential =
        setupProvider.category == PropertyCategory.residential;
    final accentColor = isResidential
        ? AppColors.primary
        : const Color(0xFFD97706);

    String ctaLabel;
    switch (currentStep) {
      case 0:
        ctaLabel = 'Continue';
        break;
      case 1:
        ctaLabel = 'Review rooms';
        break;
      case 2:
        ctaLabel = 'Review setup';
        break;
      case 3:
      default:
        ctaLabel = 'Create Property';
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (currentStep > 0) {
          setupProvider.goBack();
        } else {
          final shouldPop = await _confirmAbandon(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () async {
              if (currentStep > 0) {
                setupProvider.goBack();
              } else {
                final shouldPop = await _confirmAbandon(context);
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: const Text(
            'Add Property',
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
              // 4-Step Progress Header
              _WizardProgressBar(
                currentStep: currentStep,
                accentColor: accentColor,
              ),

              // Active Step Body
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(currentStep),
                    child: _buildStepBody(currentStep, setupProvider),
                  ),
                ),
              ),

              // Persistent Bottom Primary CTA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: setupProvider.isSubmitting
                        ? null
                        : () => _handleCtaTap(setupProvider, propertyProvider),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      disabledBackgroundColor: accentColor.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: setupProvider.isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Creating property…',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                currentStep == 3
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // HASOMI Bottom Voice Control Bar
              const HasomiBottomVoiceBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(int step, HomeSetupProvider provider) {
    switch (step) {
      case 0:
        return PropertyInfoStep(provider: provider);
      case 1:
        return LayoutSelectionStep(provider: provider);
      case 2:
        return RoomsReviewStep(provider: provider);
      case 3:
      default:
        return PropertyReviewStep(provider: provider);
    }
  }
}

class _WizardProgressBar extends StatelessWidget {
  final int currentStep;
  final Color accentColor;

  const _WizardProgressBar({
    required this.currentStep,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const steps = ['Property', 'Layout', 'Rooms', 'Review'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of 4 — ${steps[currentStep]}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${((currentStep + 1) / 4 * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 4,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
