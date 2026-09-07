import 'package:flutter/material.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_typography.dart';
import 'icon_container.dart';

/// The standard surface container for CyberSentinel.
///
/// Replaces the `Container` + `BoxDecoration(bgSecondary, borderPrimary,
/// radiusLg)` pattern that is currently duplicated inline in nearly every
/// screen. Reads all of its colours from semantic tokens, so it is correct in
/// both the dark and light themes.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.footer,
    this.child,
    this.padding,
    this.onTap,
    this.hoverable,
    this.selected = false,
    this.dense = false,
    this.accent,
  });

  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  /// Trailing widget in the header row — a badge, menu or button.
  final Widget? trailing;

  /// Rendered below [child], separated by a divider. Use for card footers such
  /// as "Last updated" or a primary action.
  final Widget? footer;

  final Widget? child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  /// Defaults to `onTap != null`. Set explicitly to get hover feedback on a
  /// non-interactive card.
  final bool? hoverable;

  /// Draws an accent bar and a stronger border to mark the active card.
  final bool selected;

  final bool dense;

  /// Colour of the selection accent bar. Defaults to the primary accent.
  final Color? accent;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;
  bool _focused = false;

  bool get _interactive => widget.onTap != null;

  bool get _hoverable => widget.hoverable ?? _interactive;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final accent = widget.accent ?? colors.primary;
    final padding = widget.padding ??
        (widget.dense ? CsSpacing.cardCompact : CsSpacing.card);

    final background = widget.selected
        ? colors.surfaceElevated
        : (_hovered && _hoverable ? colors.surfaceHover : colors.surface);

    final borderColor = widget.selected
        ? CsColors.hairline(accent, alpha: 0.55)
        : (_focused ? colors.focusRing : colors.border);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: CsRadius.largeBorder,
        border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
        // shadowSubtle is empty in the dark palette, so this lifts only
        // light-theme cards; dark cards stay flat and border-defined.
        boxShadow: colors.shadowSubtle,
      ),
      child: ClipRRect(
        borderRadius: CsRadius.largeBorder,
        child: Stack(
          children: [
            if (widget.selected)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 3, color: accent),
                ),
              ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null || widget.trailing != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.icon != null) ...[
                          IconContainer(
                            icon: widget.icon!,
                            color: widget.iconColor ?? accent,
                            size: CsIconSize.sm,
                          ),
                          const SizedBox(width: CsSpacing.sm + 2),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null)
                                Text(
                                  widget.title!,
                                  style: text.sectionTitle
                                      .copyWith(color: colors.textPrimary),
                                ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  style: text.bodySmall
                                      .copyWith(color: colors.textTertiary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: CsSpacing.sm),
                          widget.trailing!,
                        ],
                      ],
                    ),
                    if (widget.child != null)
                      const SizedBox(height: CsSpacing.lg),
                  ],
                  if (widget.child != null) widget.child!,
                  if (widget.footer != null) ...[
                    const SizedBox(height: CsSpacing.lg),
                    Divider(color: colors.border, height: 1, thickness: 1),
                    const SizedBox(height: CsSpacing.md),
                    widget.footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final interactive = Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      canRequestFocus: _interactive,
      child: MouseRegion(
        onEnter: _hoverable ? (_) => setState(() => _hovered = true) : null,
        onExit: _hoverable ? (_) => setState(() => _hovered = false) : null,
        cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: card,
        ),
      ),
    );

    if (!_interactive) {
      return interactive;
    }

    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: interactive,
      ),
    );
  }
}
