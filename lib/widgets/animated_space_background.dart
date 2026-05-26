import 'package:flutter/material.dart';

/// The default animated-space background (Classic Dark theme).
///
/// Pass [gradientOverride] to replace the starfield with a solid gradient —
/// used by the non-Classic chat themes (Aurora Purple, Midnight Blue, etc.).
class AnimatedSpaceBackground extends StatelessWidget {
  final Widget? child;

  /// When non-null this gradient is rendered instead of the dark starfield.
  final LinearGradient? gradientOverride;

  const AnimatedSpaceBackground({
    super.key,
    this.child,
    this.gradientOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (gradientOverride != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(gradient: gradientOverride!),
          ),
          if (child != null) child!,
        ],
      );
    }

    // ── Classic Dark: existing star-field look ────────────────────────────
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Deep space gradient ────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E2E), Color(0xFF2A2A40), Color(0xFF1E1E2E)],
            ),
          ),
        ),

        // ── Subtle radial light overlay ────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  radius: 1.2,
                  colors: [Colors.white.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        // ── Optional child content ─────────────────────────────────────────
        if (child != null) child!,
      ],
    );
  }
}

/// Convenience widget: reads the current [ThemeManager] and wraps [child]
/// in [AnimatedSpaceBackground] with the appropriate gradient.
/// Used directly in the chat screen body.
class ThemedChatBackground extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;

  const ThemedChatBackground({
    super.key,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSpaceBackground(
      gradientOverride: gradient,
      child: child,
    );
  }
}

