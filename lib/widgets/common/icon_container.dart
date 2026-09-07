import 'package:flutter/material.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';

/// Icon chip sizes.
enum CsIconSize { sm, md, lg, xl }

/// A tinted container for a single icon.
///
/// Replaces the hand-rolled `Container` + `BoxDecoration` + `Icon` pattern that
/// is currently repeated across the dashboard widgets and several screens.
class IconContainer extends StatelessWidget {
  const IconContainer({
    super.key,
    required this.icon,
    this.color,
    this.background,
    this.size = CsIconSize.md,
    this.tooltip,
    this.shape = BoxShape.rectangle,
  });

  final IconData icon;

  /// Foreground colour. Defaults to the primary accent.
  final Color? color;

  /// Chip background. Defaults to a translucent wash of [color].
  final Color? background;

  final CsIconSize size;
  final String? tooltip;
  final BoxShape shape;

  double get _boxSize {
    switch (size) {
      case CsIconSize.sm:
        return 28;
      case CsIconSize.md:
        return 36;
      case CsIconSize.lg:
        return 44;
      case CsIconSize.xl:
        return 48;
    }
  }

  double get _iconSize {
    switch (size) {
      case CsIconSize.sm:
        return 14;
      case CsIconSize.md:
        return 18;
      case CsIconSize.lg:
        return 22;
      case CsIconSize.xl:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final foreground = color ?? colors.primary;

    final chip = Container(
      width: _boxSize,
      height: _boxSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? CsColors.tint(foreground),
        borderRadius: shape == BoxShape.circle ? null : CsRadius.mediumBorder,
        shape: shape,
      ),
      child: Icon(icon, size: _iconSize, color: foreground),
    );

    if (tooltip == null) {
      return chip;
    }
    return Tooltip(message: tooltip!, child: chip);
  }
}
