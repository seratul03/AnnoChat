import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  // kept for API compatibility; no longer affects visual style
  final bool isSecondary;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        scale: _isPressed ? 0.96 : 1.0,
        child: ClipRRect(
          borderRadius: kRadiusLarge,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: kRadiusLarge,
                gradient: LinearGradient(
                  colors: [
                    kAccentBlue.withOpacity(0.25),
                    kAccentBlue.withOpacity(0.10),
                  ],
                ),
                border: Border.all(
                  color: kAccentBlue.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A greenyellow pill-shaped button matching the web room page's `.green-btn`.
/// Used in the Create Room and Join Room forms.
class WebNeonButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const WebNeonButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<WebNeonButton> createState() => _WebNeonButtonState();
}

class _WebNeonButtonState extends State<WebNeonButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        scale: _isPressed ? 0.96 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.webGreenyellow,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.webGreenyellow.withOpacity(
                  _isPressed ? 0.25 : 0.45,
                ),
                blurRadius: _isPressed ? 8 : 18,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: GoogleFonts.poppins(
                color: const Color(0xFF2B4F00),
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

