import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// Android Material search bar — shown at the top of HomeScreen.
class PlatformSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const PlatformSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
            const SizedBox(width: 10),
            Text(
              AppStrings.searchHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                    fontSize: 15,
                  ),
            ),
            const Spacer(),
            Container(width: 1, height: 20, color: AppColors.divider),
            const SizedBox(width: 12),
            const Icon(Icons.tune_rounded, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

/// iOS-style frosted-glass bottom search bar.
///
/// Uses [BackdropFilter] + [ImageFilter.blur] to replicate the native
/// UISearchBar / UITabBar vibrancy effect. The bar sits in
/// [Scaffold.bottomNavigationBar] so it always floats above the content.
class IOSBottomSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const IOSBottomSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Matches iOS system material colours:
    // light → white @ 72 %,  dark → #1C1C1E @ 80 %
    final glassColor = isDark
        ? const Color(0x661C1C1E)
        : Colors.white.withOpacity(0.72);

    // Top hairline matches iOS separator colour
    final separatorColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.12);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            border: Border(
              top: BorderSide(color: separatorColor, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: _IOSSearchPill(onTap: onTap, isDark: isDark),
            ),
          ),
        ),
      ),
    );
  }
}

/// The inner search pill — mimics [UISearchBar]'s rounded-rect field.
class _IOSSearchPill extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _IOSSearchPill({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // iOS search field fill: ~12 % gray tint on both modes
    final pillColor = isDark
        ? const Color(0x3DFFFFFF)  // white 24 %
        : const Color(0x1C787880); // #787880 @ 11 %

    final hintColor = isDark
        ? const Color(0x99EBEBF5)  // iOS secondaryLabel dark
        : const Color(0x993C3C43); // iOS secondaryLabel light

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.search,
              size: 17,
              color: hintColor,
            ),
            const SizedBox(width: 5),
            Text(
              'Search',
              style: TextStyle(
                color: hintColor,
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
