import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Semi-transparent white glass card — web's `.glass-card` equivalent.
/// Used by both CreateRoomTab and JoinRoomTab.
class WebFormCard extends StatelessWidget {
  final Widget child;
  const WebFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.104),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// "AnnoRooms" badge — web's `.badge` equivalent.
class AnnoBadge extends StatelessWidget {
  const AnnoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.webBadgeBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'AnnoRooms',
          style: GoogleFonts.poppins(
            color: AppColors.webBadgeText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Bottom row of the form: hint text + greenyellow action button.
class FormFooter extends StatelessWidget {
  final String hint;
  final String buttonText;
  final VoidCallback onTap;

  const FormFooter({
    super.key,
    required this.hint,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            hint,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2C2929),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _WebNeonButtonInline(text: buttonText, onTap: onTap),
      ],
    );
  }
}

/// Minimalist +/- spinner button.
class SpinBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SpinBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Icon(icon, size: 20, color: Colors.white.withOpacity(0.7)),
      ),
    );
  }
}

// ── Internal inline button (avoids re-import of neon_button.dart) ──────────

class _WebNeonButtonInline extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _WebNeonButtonInline({required this.text, required this.onTap});

  @override
  State<_WebNeonButtonInline> createState() => _WebNeonButtonInlineState();
}

class _WebNeonButtonInlineState extends State<_WebNeonButtonInline> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.webGreenyellow,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.webGreenyellow.withValues(
                  alpha: _pressed ? 0.2 : 0.4,
                ),
                blurRadius: _pressed ? 6 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2B4F00),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
