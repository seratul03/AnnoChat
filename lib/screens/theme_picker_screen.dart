import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/theme_manager.dart';

/// Bottom-sheet theme picker — shows 5 swatches and lets the user switch the
/// chat background theme. The selection is applied immediately via [ThemeManager].
class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  ChatTheme _selected = ThemeManager.instance.current.value;

  void _apply(ChatTheme theme) {
    setState(() => _selected = theme);
    ThemeManager.instance.setTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          Text(
            'Chat Theme',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Choose a background for this session',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),

          // ── Dark & Light Side-by-Side Lists ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dark Column ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.dark_mode_rounded,
                          color: Colors.blueGrey,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DARK',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._buildThemeList([
                      ChatTheme.classicDark,
                      ChatTheme.cosmicDark,
                      ChatTheme.darkSkyBlue,
                      ChatTheme.darkPurple,
                      ChatTheme.darkGray,
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // ── Light Column ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.light_mode_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIGHT',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._buildThemeList([
                      ChatTheme.auroraPurple,
                      ChatTheme.lightSkyBlue,
                      ChatTheme.lightPurple,
                      ChatTheme.lightGray,
                      ChatTheme.sunsetGold,
                    ]),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<Widget> _buildThemeList(List<ChatTheme> themes) {
    return themes.map((theme) {
      final data = kChatThemes[theme]!;
      final isSelected = theme == _selected;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _apply(theme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [data.previewColor1, data.previewColor2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected
                    ? AppColors.webGreenyellow
                    : Colors.white24,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.webGreenyellow.withOpacity(0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          const Shadow(
                            blurRadius: 6,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.webGreenyellow,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Shows the [ThemePickerScreen] as a modal bottom sheet.
Future<void> showThemePicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const ThemePickerScreen(),
  );
}
