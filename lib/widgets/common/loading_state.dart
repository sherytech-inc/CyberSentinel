import 'package:flutter/material.dart';

import '../../core/theme/cs_colors.dart';
import '../../core/theme/cs_layout.dart';
import '../../core/theme/cs_typography.dart';

/// Where a loading indicator is being used, which determines its layout.
enum CsLoadingVariant {
  /// Full-area first load. Centred, with optional copy below the spinner.
  page,

  /// Inside a row of existing content — a refresh, a table update.
  inline,

  /// Sized to sit inside a button without changing the button's height.
  button,
}

/// One shared loading presentation.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message,
    this.variant = CsLoadingVariant.page,
  });

  const LoadingState.page({super.key, this.message})
      : variant = CsLoadingVariant.page;

  const LoadingState.inline({super.key, this.message})
      : variant = CsLoadingVariant.inline;

  const LoadingState.button({super.key})
      : message = null,
        variant = CsLoadingVariant.button;

  /// Present-tense copy such as "Loading report data…". Omit for a bare
  /// spinner where the surrounding UI already says what is loading.
  final String? message;

  final CsLoadingVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    switch (variant) {
      case CsLoadingVariant.button:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primaryForeground,
          ),
        );

      case CsLoadingVariant.inline:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(width: CsSpacing.sm),
              Flexible(
                child: Text(
                  message!,
                  style: text.bodySmall.copyWith(color: colors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );

      case CsLoadingVariant.page:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(CsSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.primary,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: CsSpacing.lg),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: text.bodySmall.copyWith(color: colors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }
}
