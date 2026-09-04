import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum GlassLevel { level1, level2, level3 }

class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassLevel level;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? customSurfaceColor;
  final Border? customBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.level = GlassLevel.level1,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.customSurfaceColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);
    
    // Level settings derived from DESIGN.md specs
    final double blurAmount = switch (level) {
      GlassLevel.level1 => 12.0,
      GlassLevel.level2 => 16.0,
      GlassLevel.level3 => 24.0,
    };

    final Color surfaceColor = customSurfaceColor ?? switch (level) {
      GlassLevel.level1 => AppTheme.surfaceLow.withValues(alpha: 0.75),
      GlassLevel.level2 => AppTheme.surfaceHigh.withValues(alpha: 0.85),
      GlassLevel.level3 => AppTheme.surfaceHighest.withValues(alpha: 0.95),
    };

    final Border border = customBorder ?? switch (level) {
      GlassLevel.level1 => Border.all(
          color: AppTheme.emeraldStrokeAlpha15,
          width: 1,
        ),
      GlassLevel.level2 => Border.all(
          color: AppTheme.emeraldStrokeAlpha25,
          width: 1,
        ),
      GlassLevel.level3 => Border.all(
          color: AppTheme.emeraldStrokeAlpha40,
          width: 1.5,
        ),
    };

    final List<BoxShadow> shadows = switch (level) {
      GlassLevel.level1 => [],
      GlassLevel.level2 => [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      GlassLevel.level3 => [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.16),
            blurRadius: 40,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
    };

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          splashColor: AppTheme.primaryContainer.withValues(alpha: 0.15),
          highlightColor: AppTheme.primaryContainer.withValues(alpha: 0.08),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: content,
        ),
      ),
    );
  }
}
