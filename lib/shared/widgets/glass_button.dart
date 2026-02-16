import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

enum GlassButtonStyle { primary, secondary, danger }

/// A tappable button with three variants: primary (teal), secondary (glass), danger (red).
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final GlassButtonStyle style;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = GlassButtonStyle.primary,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.isLoading = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    switch (widget.style) {
      case GlassButtonStyle.primary:
        return _PrimaryButton(
          text: widget.text,
          icon: widget.icon,
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
          isLoading: widget.isLoading,
        );
      case GlassButtonStyle.secondary:
        return _SecondaryButton(
          text: widget.text,
          icon: widget.icon,
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
          isLoading: widget.isLoading,
        );
      case GlassButtonStyle.danger:
        return _DangerButton(
          text: widget.text,
          icon: widget.icon,
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
          isLoading: widget.isLoading,
        );
    }
  }
}

// ── Primary (filled teal) ──────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const _PrimaryButton({
    required this.text,
    this.icon,
    this.width,
    required this.height,
    required this.borderRadius,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(child: _content(Colors.white)),
    );
  }

  Widget _content(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: _textStyle(color)),
        ],
      );
    }
    return Text(text, style: _textStyle(color));
  }

  TextStyle _textStyle(Color color) => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

// ── Secondary (glass) ──────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const _SecondaryButton({
    required this.text,
    this.icon,
    this.width,
    required this.height,
    required this.borderRadius,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: _content()),
        ),
      ),
    );
  }

  Widget _content() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primaryTeal,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 20),
          const SizedBox(width: 8),
          Text(text, style: _textStyle()),
        ],
      );
    }
    return Text(text, style: _textStyle());
  }

  TextStyle _textStyle() => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTeal,
      );
}

// ── Danger (red) ───────────────────────────────────────
class _DangerButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const _DangerButton({
    required this.text,
    this.icon,
    this.width,
    required this.height,
    required this.borderRadius,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.errorRed,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.errorRed.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(child: _content()),
    );
  }

  Widget _content() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(text, style: _textStyle()),
        ],
      );
    }
    return Text(text, style: _textStyle());
  }

  TextStyle _textStyle() => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
}
