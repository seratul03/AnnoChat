import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// A bottom-sheet that lists all current room members.
///
/// [members] should be the live list of member names — the caller (ChatScreen)
/// passes the current list from RoomManager / WebSocketService.
/// [currentUser] is highlighted with the neon-cyan colour.
class MembersScreen extends StatelessWidget {
  final List<String> members;
  final String currentUser;

  const MembersScreen({
    super.key,
    required this.members,
    required this.currentUser,
  });

  /// Derives a stable colour for each username using the same hashing
  /// algorithm as the chat message bubbles so colours stay consistent.
  Color _getUserColor(String username) {
    if (username == currentUser) return AppColors.neonCyan;

    int hash = username.codeUnits.fold(0, (acc, val) => acc * 31 + val);
    hash = hash.abs();

    final int bucket = hash % 289;
    final double hue =
        bucket < 185 ? bucket.toDouble() : (bucket + 71).toDouble();

    final double saturation = 0.70 + (hash % 20) / 100.0;
    final double lightness = 0.62 + (hash % 12) / 100.0;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
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

          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Members',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.neonCyan.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${members.length}',
                  style: GoogleFonts.poppins(
                    color: AppColors.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Member list ────────────────────────────────────────────────
          Flexible(
            child: members.isEmpty
                ? Center(
                    child: Text(
                      'No members yet',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final name = members[index];
                      final isMe = name == currentUser;
                      final color = _getUserColor(name);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMe
                                ? AppColors.neonCyan.withOpacity(0.35)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Coloured avatar dot
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.8),
                                    color.withOpacity(0.4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isMe ? '$name (you)' : name,
                                style: GoogleFonts.poppins(
                                  color: isMe ? color : Colors.white,
                                  fontSize: 14,
                                  fontWeight: isMe
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isMe)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'you',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.neonCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Shows [MembersScreen] as a modal bottom sheet.
Future<void> showMembersSheet(
  BuildContext context, {
  required List<String> members,
  required String currentUser,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => MembersScreen(members: members, currentUser: currentUser),
  );
}
