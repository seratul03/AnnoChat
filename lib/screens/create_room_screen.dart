import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/websocket_service.dart';
import '../utils/constants.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/web_form_widgets.dart';
import 'chat_screen.dart';

class CreateRoomTab extends StatefulWidget {
  const CreateRoomTab({super.key});

  @override
  State<CreateRoomTab> createState() => _CreateRoomTabState();
}

class _CreateRoomTabState extends State<CreateRoomTab> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _maxMembersController = TextEditingController(
    text: '5',
  );

  static const int _minMembers = 1;
  static const int _maxMembersLimit = 200;

  String? _maxMembersError;
  bool _isCreating = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _roomNameController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  int get _currentMaxMembers =>
      int.tryParse(_maxMembersController.text) ?? _minMembers;

  void _onMaxMembersChanged(String value) {
    if (value.isEmpty) {
      setState(() => _maxMembersError = null);
      return;
    }
    final parsed = int.tryParse(value);
    if (parsed == null) return;

    if (parsed < _minMembers) {
      _maxMembersController.text = '$_minMembers';
      _maxMembersController.selection = TextSelection.collapsed(
        offset: '$_minMembers'.length,
      );
      setState(() => _maxMembersError = null);
    } else if (parsed > _maxMembersLimit) {
      setState(() => _maxMembersError = 'Maximum 200 members allowed.');
    } else {
      setState(() => _maxMembersError = null);
    }
  }

  void _increment() {
    final current = _currentMaxMembers;
    if (current < _maxMembersLimit) {
      _maxMembersController.text = '${current + 1}';
      setState(() => _maxMembersError = null);
    }
  }

  void _decrement() {
    final current = _currentMaxMembers;
    if (current > _minMembers) {
      _maxMembersController.text = '${current - 1}';
      setState(() => _maxMembersError = null);
    }
  }

  void _createRoom() {
    if (_isCreating) return;

    final username = _usernameController.text.trim();
    final roomName = _roomNameController.text.trim();

    if (username.isEmpty) {
      _showError('Username is required!');
      return;
    }

    int maxMembers = int.tryParse(_maxMembersController.text) ?? _minMembers;
    if (maxMembers < _minMembers) {
      maxMembers = _minMembers;
      _maxMembersController.text = '$_minMembers';
      setState(() => _maxMembersError = null);
    }
    if (_maxMembersError != null) {
      _showError(_maxMembersError!);
      return;
    }

    setState(() => _isCreating = true);

    WebSocketService.instance.connect(username, '');
    WebSocketService.instance.createRoom(username, maxUsers: maxMembers);

    WebSocketService.instance.socket.once('room created', (roomId) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      Navigator.push(
        context,
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (ctx, a1, a2) => ChatScreen(
            username: username,
            roomCode: roomId.toString(),
            roomName: roomName.isEmpty ? null : roomName,
            initialMemberCount: 1,
            maxUsers: maxMembers,
          ),
          transitionsBuilder: (ctx, a1, a2, child) {
            final fade = CurvedAnimation(parent: a1, curve: Curves.easeOut);
            final slide = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      );
    });

    WebSocketService.instance.socket.once('connect_error', (_) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showError('Failed to connect to server.');
    });
  }

  void _showError(String message) => AppToast.show(context, message);

  /// Capacity row with +/- spinners — web-style
  Widget _buildCapacityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Icon(
                Icons.people_outline,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxMembersController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onMaxMembersChanged,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Room capacity (e.g. 5)',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              // +/- spinner buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinBtn(icon: Icons.keyboard_arrow_up, onTap: _increment),
                  SpinBtn(icon: Icons.keyboard_arrow_down, onTap: _decrement),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        if (_maxMembersError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              _maxMembersError!,
              style: GoogleFonts.poppins(
                color: AppColors.webRed,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardInset > 0;
    final double bottomPadding =
        keyboardInset > 0 ? keyboardInset + 8.0 : 32.0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AnnoRooms badge ───────────────────────────────────────────
              const AnnoBadge(),

              // ── SVG icon (hidden when keyboard is open) ───────────────────
              Visibility(
                visible: !isKeyboardOpen,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: SvgPicture.asset(
                  'lib/assets/Icons/create_room.svg',
                  width: 56,
                  height: 56,
                  colorFilter: const ColorFilter.mode(
                    AppColors.webRed,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          WebTextField(
            controller: _usernameController,
            placeholder: 'username (max 8)',
            icon: Icons.person_outline,
            maxLength: 8,
          ),
          const SizedBox(height: 14),
          WebTextField(
            controller: _roomNameController,
            placeholder: 'Room name (optional)',
            icon: Icons.chat_bubble_outline,
          ),
          const SizedBox(height: 14),
          _buildCapacityField(),
          const SizedBox(height: 18),

          // ── Footer: hint + button ─────────────────────────────────────
          FormFooter(
            hint: 'Start a new room and share the ID with friends.',
            buttonText: _isCreating ? 'Creating...' : 'create',
            onTap: _createRoom,
          ),
        ],
      ),
    );
  }
}

