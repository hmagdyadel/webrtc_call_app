import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A premium, reusable empty state widget for the Sawa app.
///
/// Displays a themed icon inside a gradient container, a bold title,
/// a descriptive subtitle, and an optional call-to-action button.
/// Animates in with a subtle fade + scale effect.
class SawaEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SawaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<SawaEmptyState> createState() => _SawaEmptyStateState();
}

class _SawaEmptyStateState extends State<SawaEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon Container ──────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.accent.withValues(alpha: 0.10),
                            ]
                          : [
                              AppColors.primary.withValues(alpha: 0.10),
                              AppColors.accent.withValues(alpha: 0.08),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 44,
                    color: isDark
                        ? AppColors.primaryLight.withValues(alpha: 0.7)
                        : AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title ───────────────────────────────────────────
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text1,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Subtitle ────────────────────────────────────────
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text3,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                // ── CTA Button ──────────────────────────────────────
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: widget.onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
