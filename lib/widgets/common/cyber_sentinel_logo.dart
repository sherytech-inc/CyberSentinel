import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_typography.dart';

/// The single CyberSentinel brand mark.
///
/// Drawn as a vector so it stays crisp from a 16px navigation rail to a 512px
/// app icon, and so no binary asset has to be added to the repository. The
/// form is an angular sentinel perimeter — deliberately geometric rather than
/// the generic rounded shield — enclosing a monitored network node.
///
/// **Asset swap point:** when a final logo file is delivered, drop it in
/// `assets/branding/`, register that directory in `pubspec.yaml`, and replace
/// the `CustomPaint` below with an image widget. Nothing else references the
/// mark, so no screen needs to change.
class CyberSentinelLogo extends StatelessWidget {
  const CyberSentinelLogo({
    super.key,
    this.size = 32,
    this.accent,
    this.showBackdrop = true,
  });

  /// Width and height of the mark, in logical pixels.
  final double size;

  /// Defaults to the theme's primary accent.
  final Color? accent;

  /// Draws a tinted rounded backdrop behind the mark, used in the sidebar and
  /// on the login screen. Disable for inline usage next to text.
  final bool showBackdrop;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final mark = accent ?? colors.primary;

    final glyph = CustomPaint(
      size: Size.square(size),
      painter: _BrandMarkPainter(accent: mark),
    );

    if (!showBackdrop) {
      return glyph;
    }

    return Container(
      width: size + CsSpacing.lg,
      height: size + CsSpacing.lg,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CsColors.tint(mark, alpha: 0.10),
        borderRadius: CsRadius.mediumBorder,
        border: Border.all(color: CsColors.hairline(mark, alpha: 0.35)),
      ),
      child: glyph,
    );
  }
}

/// Brand mark plus wordmark, for the sidebar, login screen and app header.
class CyberSentinelLockup extends StatelessWidget {
  const CyberSentinelLockup({
    super.key,
    this.size = 28,
    this.variant = CsLockupVariant.full,
    this.onTap,
  });

  final double size;
  final CsLockupVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    final lockup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CyberSentinelLogo(
            size: size, showBackdrop: variant != CsLockupVariant.inline),
        if (variant != CsLockupVariant.mark) ...[
          const SizedBox(width: CsSpacing.md),
          Flexible(
            child: Text.rich(
              TextSpan(
                style:
                    (variant == CsLockupVariant.full ? text.title : text.label)
                        .copyWith(letterSpacing: -0.1),
                children: [
                  TextSpan(
                    text: 'Cyber',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  TextSpan(
                    text: 'Sentinel',
                    style: TextStyle(color: colors.primary),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) {
      return lockup;
    }
    return GestureDetector(onTap: onTap, child: lockup);
  }
}

/// How much of the lockup to render.
enum CsLockupVariant {
  /// Mark and wordmark at title size — sidebar and login.
  full,

  /// Mark and wordmark at label size — compact app header.
  inline,

  /// Mark only — navigation rail, loading and empty states, favicon contexts.
  mark,
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final perimeter = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.72)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(0, h * 0.25)
      ..close();

    canvas.drawPath(
      perimeter,
      Paint()..color = accent.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      perimeter,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1.1, w * 0.055)
        ..color = accent,
    );

    final cx = w * 0.5;
    final cy = h * 0.485;
    final orbit = w * 0.24;
    final linkWidth = math.max(0.9, w * 0.042);

    final link = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = linkWidth
      ..color = accent.withValues(alpha: 0.75);

    const nodeAngles = <double>[-90, 30, 150];
    final satellites = <Offset>[];

    for (final degrees in nodeAngles) {
      final radians = degrees * math.pi / 180;
      final point = Offset(
        cx + orbit * math.cos(radians),
        cy + orbit * math.sin(radians),
      );
      satellites.add(point);
      canvas.drawLine(Offset(cx, cy), point, link);
    }

    final nodeFill = Paint()..color = accent;
    for (final point in satellites) {
      canvas.drawCircle(point, math.max(0.9, w * 0.055), nodeFill);
    }
    canvas.drawCircle(Offset(cx, cy), math.max(1.2, w * 0.085), nodeFill);
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
