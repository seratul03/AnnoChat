import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Original dark glassmorphism text field — used in the existing chat screen.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: kRadiusLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: kRadiusLarge,
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 62, 95, 244)
                    .withOpacity(kGlassOpacityHigh),
                const Color.fromARGB(255, 81, 191, 255).withOpacity(0.08),
              ],
            ),
            border:
                Border.all(color: Colors.white.withOpacity(0.25), width: 0.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Web-style light text field — used in the Create/Join Room forms.
///
/// Matches the web room page's input look: semi-transparent white background,
/// Poppins font, pill shape (radius 25), and a red focus ring.
class WebTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData? icon;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? Function(String)? validator;

  const WebTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.validator,
  });

  @override
  State<WebTextField> createState() => _WebTextFieldState();
}

class _WebTextFieldState extends State<WebTextField> {
  final FocusNode _focus = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _hasFocus = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: _hasFocus
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.08),
        border: Border.all(
          color: _hasFocus
              ? Colors.white.withOpacity(0.8)
              : Colors.white.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15,
          ),
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, color: Colors.white.withOpacity(0.7), size: 20)
              : null,
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

