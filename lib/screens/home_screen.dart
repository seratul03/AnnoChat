import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';
import '../widgets/web_form_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Start on JOIN tab (index 0)
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTab() {
    if (_tabController.index == 0) {
      _tabController.animateTo(1);
    } else {
      _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // ── Full-screen warm gradient background (matching the web room page) ──
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.webRoomGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isKeyboardOpen ? 8.0 : 222.0, // 190 (HeroCard) + 16 (top) + 16 (bottom)
                decoration: const BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: HeroCard(
                          isJoinTab: _tabController.index == 0,
                          onToggle: _toggleTab,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Main Glass Card with Tabs and Forms ────────────────────
              Expanded(
                key: const ValueKey('main_form_expanded'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: WebFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Web-style tab row inside the glass card
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _WebTabBar(controller: _tabController),
                          ),
                        ),
                        // Tab body
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            // Index 0 = JOIN, Index 1 = CREATE
                            children: const [JoinRoomTab(), CreateRoomTab()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isKeyboardOpen ? 0 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  final bool isJoinTab;
  final VoidCallback onToggle;

  const HeroCard({
    super.key,
    required this.isJoinTab,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNum = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final dateStr = '$dayNum/$month/$year';
    final days = [
      "MONDAY",
      "TUESDAY",
      "WEDNESDAY",
      "THURSDAY",
      "FRIDAY",
      "SATURDAY",
      "SUNDAY"
    ];
    final dayStr = days[now.weekday - 1];

    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFe84a5f),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Center Circle
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom half glass overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 95,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Left Logo Text / Box
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'lib/assets/Anno_Logo.png',
                  height: 56,
                ),
              ),
            ),

            // Top Right Action Button
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    isJoinTab ? 'CREATE' : 'JOIN',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFe84a5f),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Left Date/Day
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    dayStr,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A web-style horizontal tab switcher (for inside the glass card).
class _WebTabBar extends StatelessWidget {
  final TabController controller;

  const _WebTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.webRed,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF333333),
        unselectedLabelColor: Colors.white,
        labelPadding: const EdgeInsets.only(right: 20),
        tabAlignment: TabAlignment.start,
        labelStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(text: 'JOIN'),
          Tab(text: 'CREATE'),
        ],
      ),
    );
  }
}
