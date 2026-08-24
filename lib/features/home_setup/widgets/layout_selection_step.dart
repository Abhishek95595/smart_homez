import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/models/home_layout_template.dart';
import '../providers/home_setup_provider.dart';
import 'custom_layout_editor.dart';
import 'layout_template_card.dart';

class LayoutSelectionStep extends StatefulWidget {
  final HomeSetupProvider provider;
  final bool canManage;

  const LayoutSelectionStep({
    super.key,
    required this.provider,
    required this.canManage,
  });

  @override
  State<LayoutSelectionStep> createState() => _LayoutSelectionStepState();
}

class _LayoutSelectionStepState extends State<LayoutSelectionStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider.homeName);
    _addressController = TextEditingController(text: widget.provider.address);
  }

  @override
  void didUpdateWidget(LayoutSelectionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.homeName != _nameController.text) {
      _nameController.text = widget.provider.homeName;
    }
    if (widget.provider.address != _addressController.text) {
      _addressController.text = widget.provider.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final canManage = widget.canManage;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Property Details
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.divider, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Home Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  enabled: canManage && !provider.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Home Name *',
                    hintText: 'e.g. My Apartment, Greenwood Villa',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  onChanged: (val) => provider.setHomeName(val),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _addressController,
                  enabled: canManage && !provider.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    hintText: 'e.g. Flat 402, Block B, Palm View',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  onChanged: (val) => provider.setAddress(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Choose Template
          const Text(
            '2. Select Layout Template',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: HomeLayoutTemplateType.values.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final template = HomeLayoutTemplateType.values[index];
              final isSelected = provider.selectedTemplate == template;

              return LayoutTemplateCard(
                template: template,
                isSelected: isSelected,
                onTap: () {
                  if (canManage && !provider.isLoading) {
                    provider.setTemplate(template);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Custom Layout Editor (if Custom selected)
          if (provider.selectedTemplate == HomeLayoutTemplateType.custom) ...[
            CustomLayoutEditor(provider: provider),
            const SizedBox(height: 20),
          ],

          // Error Message Banner
          if (provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Submit Action Button
          FilledButton.icon(
            onPressed: (!canManage || provider.isLoading)
                ? null
                : () => provider.createHomeLayout(canManage: canManage),
            icon: provider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              provider.isLoading
                  ? 'Creating Home Structure…'
                  : 'Create & Continue to Devices',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
