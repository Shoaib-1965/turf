import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

/// A frosted-glass style app bar with backdrop blur.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + MediaQuery.viewPaddingOf(context).top,
          padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.60),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.80),
                width: 1,
              ),
            ),
          ),
          child: NavigationToolbar(
            leading: leading ??
                (Navigator.canPop(context)
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        color: AppColors.primaryTeal,
                        onPressed: () => Navigator.pop(context),
                      )
                    : null),
            middle: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: actions != null
                ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                : null,
            centerMiddle: centerTitle,
            middleSpacing: 16,
          ),
        ),
      ),
    );
  }
}
