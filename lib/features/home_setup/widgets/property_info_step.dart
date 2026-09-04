import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/models/home_layout_template.dart';
import '../providers/home_setup_provider.dart';

class PropertyInfoStep extends StatefulWidget {
  final HomeSetupProvider provider;

  const PropertyInfoStep({super.key, required this.provider});

  @override
  State<PropertyInfoStep> createState() => _PropertyInfoStepState();
}

class _PropertyInfoStepState extends State<PropertyInfoStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider.propertyName);
    _addressController = TextEditingController(text: widget.provider.address);

    _nameController.addListener(() {
      widget.provider.setPropertyName(_nameController.text);
    });
    _addressController.addListener(() {
      widget.provider.setAddress(_addressController.text);
    });
  }

  @override
  void didUpdateWidget(PropertyInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_nameController.text != widget.provider.propertyName) {
      _nameController.text = widget.provider.propertyName;
    }
    if (_addressController.text != widget.provider.address) {
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
    final isResidential = provider.category == PropertyCategory.residential;

    final accentColor = isResidential
        ? AppColors.primary
        : const Color(0xFFD97706);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Let's set up your space",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select your property category and enter initial details.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Category Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CategorySegment(
                    label: 'Residential',
                    icon: Icons.home_outlined,
                    isSelected: isResidential,
                    activeColor: AppColors.primary,
                    onTap: () =>
                        provider.setCategory(PropertyCategory.residential),
                  ),
                ),
                Expanded(
                  child: _CategorySegment(
                    label: 'Commercial',
                    icon: Icons.business_outlined,
                    isSelected: !isResidential,
                    activeColor: const Color(0xFFD97706),
                    onTap: () =>
                        provider.setCategory(PropertyCategory.commercial),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Property Name Input
          const Text(
            'Property Name *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: isResidential
                  ? 'e.g. My Villa, Apartment 402'
                  : 'e.g. Headquarters Office, Tech Store',
              prefixIcon: Icon(
                isResidential
                    ? Icons.home_work_outlined
                    : Icons.business_center_outlined,
                color: accentColor,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.6),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Address Input (Optional)
          const Text(
            'Address (Optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 124 Park Avenue, Suite 3B',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.6),
              ),
            ),
          ),

          if (provider.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategorySegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _CategorySegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
