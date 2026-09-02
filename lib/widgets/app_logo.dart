import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A brand logo emblem widget for Hasomi that blends seamlessly with any background.
///
/// Features a transparent alpha-channel emblem that automatically adapts to
/// light and dark surfaces, avoiding opaque boxes or harsh circular container patches.
class AppLogo extends StatelessWidget {
  /// Height of the logo in logical pixels.
  final double size;

  /// Optional tint color for the logo. If null, uses [AppColors.primary] on light
  /// themes or [Colors.white] if specified or on dark backgrounds.
  final Color? color;

  /// Optional custom padding around the logo emblem.
  final EdgeInsetsGeometry padding;

  /// Optional shadow/glow behind the emblem for extra depth.
  final List<BoxShadow>? shadows;

  const AppLogo({
    super.key,
    this.size = 28,
    this.color,
    this.padding = EdgeInsets.zero,
    this.shadows,
  });

  /// Factory for dark/colored background surfaces (e.g. Navigation Drawer, dark headers).
  const AppLogo.white({
    super.key,
    this.size = 28,
    this.padding = EdgeInsets.zero,
    this.shadows,
  }) : color = Colors.white;

  /// Factory for light surfaces with brand primary teal coloring.
  const AppLogo.teal({
    super.key,
    this.size = 28,
    this.padding = EdgeInsets.zero,
    this.shadows,
  }) : color = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    // Bounded aspect ratio of the extracted H emblem: 1014 width / 910 height = 1.114
    final double logoHeight = size;
    final double logoWidth = size * (1014.0 / 910.0);

    Widget imageWidget = Image.asset(
      'assets/images/app_logo_white_transparent.png',
      width: logoWidth,
      height: logoHeight,
      fit: BoxFit.fill,
      color: effectiveColor,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
    );

    if (padding != EdgeInsets.zero) {
      imageWidget = Padding(
        padding: padding,
        child: imageWidget,
      );
    }

    if (shadows != null && shadows!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: shadows,
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// A unified brand logotype where the stylized "H" symbol serves as the initial letter,
/// directly followed by "asomi" with zero gap and leveled baseline: [H]asomi.
class AppBrandHeader extends StatelessWidget {
  final double? logoSize;
  final double fontSize;
  final Color? color;
  final String suffix;
  final TextStyle? suffixStyle;
  final double spacing;
  final List<BoxShadow>? shadows;

  const AppBrandHeader({
    super.key,
    this.logoSize,
    this.fontSize = 24,
    this.color,
    this.suffix = 'asomi',
    this.suffixStyle,
    this.spacing = 0.0,
    this.shadows,
  });

  const AppBrandHeader.white({
    super.key,
    this.logoSize,
    this.fontSize = 24,
    this.suffix = 'asomi',
    this.suffixStyle,
    this.spacing = 0.0,
    this.shadows,
  }) : color = Colors.white;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    // The H emblem height matches the capital height of the typography
    final effectiveLogoHeight = logoSize ?? (fontSize * 0.95);

    return Semantics(
      label: 'Hasomi',
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: fontSize * 0.10),
            child: AppLogo(
              size: effectiveLogoHeight,
              color: effectiveColor,
              shadows: shadows,
            ),
          ),
          if (spacing > 0) SizedBox(width: spacing),
          Text(
            suffix,
            style: suffixStyle ??
                TextStyle(
                  color: effectiveColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  height: 1.0,
                ),
          ),
        ],
      ),
    );
  }
}
