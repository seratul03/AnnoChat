import 'package:flutter/material.dart';

// ── Design system constants ────────────────────────────────────────────────────

// Background
const Color kBackgroundTop = Color(0xFF0F2027);
const Color kBackgroundMiddle = Color(0xFF203A43);
const Color kBackgroundBottom = Color(0xFF2C5364);

// Glass
const Color kGlassLight = Colors.white;
const Color kAccentBlue = Color(0xFF4DA3FF);

// Blur / opacity
const double kGlassBlur = 6;
const double kGlassOpacityLow = 0.10;
const double kGlassOpacityHigh = 0.18;

// Border radii
const BorderRadius kRadiusLarge = BorderRadius.all(Radius.circular(24));
const BorderRadius kRadiusMedium = BorderRadius.all(Radius.circular(20));
const BorderRadius kRadiusSmall = BorderRadius.all(Radius.circular(16));

// ── Colours ───────────────────────────────────────────────────────────────────

class AppColors {
  static const Color backgroundDeep = Color(0xFF0F172A);
  static const Color backgroundSpace = Color(0xFF020617);
  static const Color cardDark = Color(0xFF101827);

  static const Color glassSurface = Color(0x6614213A);
  static const Color glassStroke = Color(0x3387B8FF);
  static const Color glassHighlight = Color(0x55C7D2FF);
  static const Color glassShadow = Color(0x80010211);

  static const Color neonCyan = Color(0xFF3B82F6);
  static const Color neonPink = Color(0xFF6366F1);
  static const Color neonPurple = Color(0xFF4F46E5);
  static const Color neonBlue = Color(0xFF2563EB);

  // ── Web palette tokens ─────────────────────────────────────────────────────
  /// Deep near-black background used across the web landing page
  static const Color webBackground = Color(0xFF05010A);
  /// Primary red accent (#e84a5f) — hero card, tab underline, etc.
  static const Color webRed = Color(0xFFE84A5F);
  /// Warm hot-pink used in the web gradient background of the room page
  static const Color webPink = Color(0xFFD74FB3);
  /// Greenyellow CTA button colour (matches `greenyellow` / `#adff2f`)
  static const Color webGreenyellow = Color(0xFFADFF2F);
  /// Dark card used for the logo bar at the bottom of the room page
  static const Color webDarkCard = Color(0xFF1A1A1A);
  /// Badge background (lavender)
  static const Color webBadgeBg = Color(0xFFE2DCFC);
  /// Badge text (purple)
  static const Color webBadgeText = Color(0xFF5A4B9C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [neonPurple, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassSheen = LinearGradient(
    colors: [Color(0x22FFFFFF), Color(0x00FFFFFF), Color(0x33A7C5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
  );

  /// Warm pink→red gradient used on the Room page background (matching the web)
  static const LinearGradient webRoomGradient = LinearGradient(
    colors: [Color(0xFFE86E6E), Color(0xFFD74FB3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Chat Theme System ─────────────────────────────────────────────────────────

enum ChatTheme {
  classicDark,
  cosmicDark,
  darkSkyBlue,
  darkPurple,
  darkGray,
  auroraPurple,
  lightSkyBlue,
  lightPurple,
  lightGray,
  sunsetGold,
}

class ChatThemeData {
  final String name;
  final Color previewColor1;
  final Color previewColor2;
  /// The background gradient used behind the chat messages area.
  /// null = use the animated star background (Classic Dark only).
  final LinearGradient? backgroundGradient;

  const ChatThemeData({
    required this.name,
    required this.previewColor1,
    required this.previewColor2,
    this.backgroundGradient,
  });
}

/// Theme definitions — Classic Dark has no gradient (uses animated star bg).
const Map<ChatTheme, ChatThemeData> kChatThemes = {
  ChatTheme.classicDark: ChatThemeData(
    name: 'Classic Dark',
    previewColor1: Color(0xFF0F172A),
    previewColor2: Color(0xFF020617),
    backgroundGradient: null, // uses animated star background
  ),
  ChatTheme.cosmicDark: ChatThemeData(
    name: 'Cosmic Dark',
    previewColor1: Color(0xFF15153C),
    previewColor2: Color(0xFF61333B),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF15153C), Color(0xFF310631), Color(0xFF61333B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.darkSkyBlue: ChatThemeData(
    name: 'Dark Sky Blue',
    previewColor1: Color(0xFF0F1E36),
    previewColor2: Color(0xFF1B365D),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF0F1E36), Color(0xFF1B365D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.darkPurple: ChatThemeData(
    name: 'Dark Purple',
    previewColor1: Color(0xFF1E0A24),
    previewColor2: Color(0xFF381242),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF1E0A24), Color(0xFF381242)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.darkGray: ChatThemeData(
    name: 'Dark Gray',
    previewColor1: Color(0xFF1E1E1E),
    previewColor2: Color(0xFF333333),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF1E1E1E), Color(0xFF333333)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.auroraPurple: ChatThemeData(
    name: 'Aurora Purple',
    previewColor1: Color(0xFF8E8EE8),
    previewColor2: Color(0xFFE470E4),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF8E8EE8), Color(0xFFE470E4), Color(0xFFE98192)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.lightSkyBlue: ChatThemeData(
    name: 'Light Sky Blue',
    previewColor1: Color(0xFFE0F7FA),
    previewColor2: Color(0xFF87CEEB),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFE0F7FA), Color(0xFF87CEEB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.lightPurple: ChatThemeData(
    name: 'Light Purple',
    previewColor1: Color(0xFFF3E5F5),
    previewColor2: Color(0xFFDDA0DD),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFF3E5F5), Color(0xFFDDA0DD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.lightGray: ChatThemeData(
    name: 'Light Gray',
    previewColor1: Color(0xFFF5F5F5),
    previewColor2: Color(0xFFBDBDBD),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFF5F5F5), Color(0xFFBDBDBD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatTheme.sunsetGold: ChatThemeData(
    name: 'Sunset Gold',
    previewColor1: Color(0xFFFFF275),
    previewColor2: Color(0xFFFF8C42),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFFFF275), Color(0xFFFF8C42)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
};

