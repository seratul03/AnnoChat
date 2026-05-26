import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/message_model.dart';
import '../services/room_manager.dart';
import '../services/websocket_service.dart';
import '../utils/constants.dart';
import '../utils/theme_manager.dart';
import '../widgets/app_toast.dart';
import 'members_screen.dart';
import 'theme_picker_screen.dart';

// ── Animated counter pill number ────────────────────────────────────────────────

/// A number label that slides the old digit up and the new digit in from below
/// when the count increases (and the mirror for decreases).
class _AnimatedCounter extends StatefulWidget {
  final int count;
  const _AnimatedCounter({required this.count});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late int _prev;
  late int _curr;
  late Animation<Offset> _inSlide;
  late Animation<Offset> _outSlide;

  @override
  void initState() {
    super.initState();
    _prev = widget.count;
    _curr = widget.count;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..value = 1.0;
    _rebuildTweens(goingUp: true);
  }

  void _rebuildTweens({required bool goingUp}) {
    final dir = goingUp ? 1.0 : -1.0;
    _inSlide = Tween<Offset>(
      begin: Offset(0, dir),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _outSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, -dir),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInCubic));
  }

  @override
  void didUpdateWidget(_AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (widget.count != _curr) {
      _prev = _curr;
      _curr = widget.count;
      _rebuildTweens(goingUp: _curr > _prev);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = TextStyle(
      color: Colors.white.withOpacity(0.85),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    return SizedBox(
      width: 36,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            if (_ctrl.isCompleted) {
              return Text('$_curr', textAlign: TextAlign.center, style: ts);
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                SlideTransition(
                  position: _outSlide,
                  child: Text('$_prev', textAlign: TextAlign.center, style: ts),
                ),
                SlideTransition(
                  position: _inSlide,
                  child: Text('$_curr', textAlign: TextAlign.center, style: ts),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Chat AppBar ────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? roomName;
  final String roomCode;
  final String username;
  final VoidCallback onDeleteChat;
  final VoidCallback onLeaveRoom;
  final ValueNotifier<int> memberCountNotifier;

  const _ChatAppBar({
    required this.roomName,
    required this.roomCode,
    required this.username,
    required this.onDeleteChat,
    required this.onLeaveRoom,
    required this.memberCountNotifier,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);

  @override
  State<_ChatAppBar> createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<_ChatAppBar> {
  int _displayedCount = 0;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    // Prefer the notifier's initial value (already includes the local user);
    // fall back to any cached RoomManager state if the notifier is zero.
    final initialCount = widget.memberCountNotifier.value;
    _displayedCount = initialCount > 0
        ? initialCount
        : RoomManager.instance.getRoom(widget.roomCode)?.users.length ?? 0;
    widget.memberCountNotifier.addListener(_onCountChanged);
  }

  @override
  void dispose() {
    widget.memberCountNotifier.removeListener(_onCountChanged);
    super.dispose();
  }

  void _onCountChanged() {
    final next = widget.memberCountNotifier.value;
    if (next != _displayedCount) {
      setState(() {
        _displayedCount = next;
      });
    }
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B0F2A),
        elevation: 24,
        shadowColor: Colors.black.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        title: const Text(
          'Leave Room?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'If you leave, your chats will be permanently lost.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.60),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLeaveRoom();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFC5C7D).withOpacity(0.15),
              foregroundColor: const Color(0xFFFC5C7D),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Leave',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _copyRoomId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    AppToast.show(
      context,
      'Room ID copied!',
      type: ToastType.success,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _displayedCount;
    final displayName = widget.roomName ?? widget.roomCode;

    return SizedBox(
      height: widget.preferredSize.height + MediaQuery.of(context).padding.top,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    // ── Logo ──────────────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ── Center: room name + ID row + member pill ──────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _copyRoomId(context),
                                child: Row(
                                  children: [
                                    Text(
                                      _copied ? 'Copied!' : 'Copy ID',
                                      style: TextStyle(
                                        color: _copied
                                            ? AppColors.neonCyan
                                            : Colors.white.withOpacity(0.65),
                                        fontSize: 11,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    SvgPicture.asset(
                                      _copied
                                          ? 'lib/assets/Icons/copied.svg'
                                          : 'lib/assets/Icons/copy_room_id.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ── Member count pill (tap → Members sheet) ────
                              GestureDetector(
                                onTap: () {
                                  final members =
                                      RoomManager.instance
                                          .getRoom(widget.roomCode)
                                          ?.users
                                          .toList() ??
                                      [];
                                  showMembersSheet(
                                    context,
                                    members: members,
                                    currentUser: widget.username,
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 6,
                                      sigmaY: 6,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            'lib/assets/Icons/members.svg',
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          // ── Animated push-up counter ──
                                          _AnimatedCounter(count: count),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Right: 3-dot menu ──────────────────────────────────
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(0, 46),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: SvgPicture.asset(
                        'lib/assets/Icons/options.svg',
                        width: 26,
                        height: 26,
                      ),
                      iconSize: 26,
                      color: const Color.fromARGB(255, 18, 18, 32),
                      elevation: 16,
                      shadowColor: Colors.black.withOpacity(0.65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      onSelected: (val) async {
                        if (val == 'theme') {
                          await showThemePicker(context);
                        } else if (val == 'copy') {
                          Clipboard.setData(
                            ClipboardData(text: widget.roomCode),
                          );
                          AppToast.show(
                            context,
                            'Room code copied!',
                            type: ToastType.success,
                            duration: const Duration(seconds: 2),
                          );
                        } else if (val == 'clear') {
                          widget.onDeleteChat();
                        } else if (val == 'exit') {
                          _showLeaveDialog(context);
                        }
                      },
                      itemBuilder: (_) => [
                        _menuItem(
                          icon: Icons.palette_outlined,
                          label: 'Change Theme',
                          value: 'theme',
                          color: AppColors.neonCyan,
                        ),
                        _menuItem(
                          icon: Icons.delete_sweep_outlined,
                          label: 'Clear Chat',
                          value: 'clear',
                          color: const Color(0xFFFFB347),
                        ),
                        _menuItem(
                          icon: Icons.logout_rounded,
                          label: 'Exit Chat',
                          value: 'exit',
                          color: const Color(0xFFFC5C7D),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Swipe-to-reply wrapper ─────────────────────────────────────────────────────

class _SwipeableMessage extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const _SwipeableMessage({required this.child, required this.onReply});

  @override
  State<_SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<_SwipeableMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Animation<double> _bounceAnim = const AlwaysStoppedAnimation<double>(0);

  double _dragX = 0;
  bool _triggered = false;

  static const double _kThreshold = 62;
  static const double _kMaxDrag = 80;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    // If mid-bounce, stop and snap drag to current visual position.
    if (_ctrl.isAnimating) {
      _ctrl.stop();
      _dragX = _bounceAnim.value;
    }
    setState(() {
      _triggered = false;
      _dragX = (_dragX + d.delta.dx).clamp(0.0, _kMaxDrag);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_dragX >= _kThreshold && !_triggered) {
      _triggered = true;
      widget.onReply();
    }
    // Elastic spring-back: overshoot then settle at 0.
    _bounceAnim = Tween<double>(
      begin: _dragX,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _dragX = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onPanUpdate,
      onHorizontalDragEnd: _onPanEnd,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          final offset = _ctrl.isAnimating ? _bounceAnim.value : _dragX;
          final progress = (offset / _kThreshold).clamp(0.0, 1.0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Reply icon revealed from the left.
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.35 + 0.65 * progress,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withOpacity(
                            0.15 * progress,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.reply_rounded,
                          color: AppColors.neonCyan.withOpacity(0.85),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bubble slides right.
              Transform.translate(offset: Offset(offset, 0), child: child),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ── Message entrance animation ────────────────────────────────────────────────

/// Slides each new message up while fading it in.
/// Old messages (animate: false) are shown immediately with no overhead.
class _MessageEntrance extends StatefulWidget {
  final Widget child;
  final bool animate;

  const _MessageEntrance({required this.child, required this.animate});

  @override
  State<_MessageEntrance> createState() => _MessageEntranceState();
}

class _MessageEntranceState extends State<_MessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.animate ? 0.0 : 1.0,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.animate) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Isolated message list (rebuilds only on new messages) ────────────────────

class _MessageListView extends StatefulWidget {
  final String username;
  final ScrollController scrollController;
  final void Function(ChatMessage msg) onReply;

  const _MessageListView({
    super.key,
    required this.username,
    required this.scrollController,
    required this.onReply,
  });

  @override
  _MessageListViewState createState() => _MessageListViewState();
}

class _MessageListViewState extends State<_MessageListView> {
  final List<ChatMessage> _messages = [];
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  final Set<String> _pendingAnimationIds = {};

  void addMessage(ChatMessage msg) {
    setState(() {
      _messages.add(msg);
      _pendingAnimationIds.add(msg.id);
    });
  }

  void clearMessages() {
    setState(() {
      _messages.clear();
      _messageKeys.clear();
      _highlightedMessageId = null;
    });
  }

  Color _getUserColor(String username) {
    if (username == widget.username) return AppColors.neonCyan;

    // Derive a stable seed from the username.
    int hash = username.codeUnits.fold(0, (acc, val) => acc * 31 + val);
    hash = hash.abs();

    // Allowed hue bands: [0°, 184°] ∪ [256°, 359°] (289 steps).
    // The blue/cyan band 185°–255° is reserved for the current user.
    final int bucket = hash % 289;
    final double hue = bucket < 185
        ? bucket.toDouble()
        : (bucket + 71).toDouble();

    // Vary saturation and lightness slightly for more visual variety.
    final double saturation = 0.70 + (hash % 20) / 100.0; // 0.70 – 0.89
    final double lightness = 0.62 + (hash % 12) / 100.0; // 0.62 – 0.73

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  void _scrollToAndHighlight(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.25,
    ).then((_) {
      if (!mounted) return;
      setState(() => _highlightedMessageId = messageId);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _highlightedMessageId = null);
      });
    });
  }

  Widget _buildMessageItem(ChatMessage msg) {
    final isSystem = msg.sender == 'System';
    final isMe = msg.sender == widget.username;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            msg.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }

    final isHighlighted = _highlightedMessageId == msg.id;
    final msgKey = _messageKeys.putIfAbsent(msg.id, GlobalKey.new);

    final bubble = AnimatedContainer(
      key: msgKey,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 60),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.neonCyan.withOpacity(0.09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: isHighlighted
            ? Border.all(
                color: AppColors.neonCyan.withOpacity(0.38),
                width: 1.2,
              )
            : Border.all(color: Colors.transparent),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.neonCyan.withOpacity(0.14),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(isHighlighted ? 6 : 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  isMe ? 'You' : msg.sender,
                  style: TextStyle(
                    color: _getUserColor(msg.sender),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // ── Quoted reply preview (fake glass — no BackdropFilter) ──
              if (msg.replyToSender != null)
                Builder(
                  builder: (context) {
                    // ── Reply bubble size controls ─────────────────────────
                    const double replySenderFontSize = 11; // sender name
                    const double replySourceFontSize = 12; // quoted text
                    const double replyArrowSize = 25; // ↑ arrow icon
                    const double replyTopLineHeight = 0; // horizontal rule
                    // ──────────────────────────────────────────────────────
                    return GestureDetector(
                      onTap: msg.replyToId != null
                          ? () => _scrollToAndHighlight(msg.replyToId!)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: Container(
                                height: replyTopLineHeight,
                                color: Colors.white.withOpacity(0.40),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withOpacity(0.70),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.replyToSender == widget.username
                                              ? 'You'
                                              : msg.replyToSender!,
                                          style: TextStyle(
                                            color: AppColors.neonCyan,
                                            fontSize: replySenderFontSize,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          msg.replyToText ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.55,
                                            ),
                                            fontSize: replySourceFontSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (msg.replyToId != null) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: replyArrowSize,
                                      color: AppColors.neonCyan.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              // ── Main bubble (fake glass — no BackdropFilter) ──────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isMe
                        ? [
                            AppColors.neonCyan.withOpacity(0.28),
                            AppColors.neonBlue.withOpacity(0.16),
                            Colors.white.withOpacity(0.06),
                          ]
                        : [
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0.04),
                          ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(isMe ? 0.30 : 0.22),
                    width: 1.25,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.06),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.35, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 0,
                      child: Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.40),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        msg.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final shouldAnimate = _pendingAnimationIds.remove(msg.id);
    return _MessageEntrance(
      animate: shouldAnimate,
      child: _SwipeableMessage(
        onReply: () => widget.onReply(msg),
        child: bubble,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        // The top padding clears the AppBar
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 44,
        // The bottom padding controls the gap between the last message and the input field / keyboard.
        // If the gap is too much or too little, adjust the "130" value below:
        bottom: 120 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: _messages.length,
      itemBuilder: (_, index) =>
          _buildMessageItem(_messages[_messages.length - 1 - index]),
    );
  }
}

// ── ChatScreen ─────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String username;
  final String roomCode;
  final String? roomName;

  /// Total number of users already in the room when this screen opens.
  /// Supplied by the server via the room-joined / room-created event.
  final int initialMemberCount;

  /// Maximum number of members allowed in this room.
  /// 0 means unlimited (default – used when the server does not report a cap).
  final int maxUsers;

  const ChatScreen({
    super.key,
    required this.username,
    required this.roomCode,
    this.roomName,
    this.initialMemberCount = 1,
    this.maxUsers = 0,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<_MessageListViewState> _messageListKey = GlobalKey();

  ChatMessage? _replyingTo;
  late final ValueNotifier<int> _memberCountNotifier;

  // ── Send-button press state ──────────────────────────────────────────
  bool _sendButtonPressed = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Ensure the room exists locally and the current user is added to the members list
    if (!RoomManager.instance.roomExists(widget.roomCode)) {
      RoomManager.instance.createRoom(
        code: widget.roomCode,
        name: widget.roomName ?? 'Room',
        maxUsers: widget.maxUsers,
      );
    }
    RoomManager.instance.joinRoom(widget.roomCode, widget.username);

    _memberCountNotifier = ValueNotifier<int>(widget.initialMemberCount);
    if (widget.maxUsers > 0) {
      _memberCountNotifier.addListener(_enforceCapacity);
    }
    _setupSocketListeners();
    _queueSystemMessages();
  }

  /// Called whenever the member count updates.  If the count exceeds the room
  /// cap AND this user appears to be the one who pushed it over (their own
  /// initialMemberCount already exceeded the cap when they joined), disconnect
  /// them immediately.  Existing legitimate members are not affected because
  /// their initialMemberCount was within the cap when they joined.
  void _enforceCapacity() {
    if (widget.maxUsers <= 0) return;
    if (widget.initialMemberCount > widget.maxUsers) {
      // This user was already over-limit when they joined; boot them now.
      _memberCountNotifier.removeListener(_enforceCapacity);
      WebSocketService.instance.disconnect();
      if (mounted) {
        AppToast.show(
          context,
          'Room is full (${widget.maxUsers} members max). You have been disconnected.',
        );
        // Pop back to the home screen.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  void dispose() {
    _memberCountNotifier.removeListener(_enforceCapacity);
    _memberCountNotifier.dispose();
    ThemeManager.instance.reset(); // reset theme when leaving room
    WebSocketService.instance.disconnect();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Socket.IO listeners ────────────────────────────────────────────────────

  void _setupSocketListeners() {
    WebSocketService.instance.socket.on("chat message", (data) {
      if (!mounted) return;

      final bool isSystem = data["system"] == true;
      final String sender = isSystem
          ? 'System'
          : (data["user"] as String? ?? 'Unknown');

      final String text = data["text"] as String? ?? '';

      // Always try to read a room-size field the server may embed in any event.
      final raw =
          data['user_count'] ??
          data['userCount'] ??
          data['room_users'] ??
          data['members'] ??
          data['count'];
      final serverCount = raw is int
          ? raw
          : (raw != null ? int.tryParse(raw.toString()) : null);

      if (serverCount != null && serverCount > 0) {
        _memberCountNotifier.value = serverCount;
      } else if (isSystem) {
        // Fallback: infer from join/leave keywords in the system message text.
        final lower = text.toLowerCase();
        if (lower.contains('joined') || lower.contains('connected')) {
          _memberCountNotifier.value = _memberCountNotifier.value + 1;
        } else if (lower.contains('left') || lower.contains('disconnected')) {
          _memberCountNotifier.value = (_memberCountNotifier.value - 1).clamp(
            1,
            9999,
          );
        }
      }

      // 🔥 CRITICAL FIX:
      // Ignore server echo of your own messages (prevents duplication)
      if (!isSystem && sender == widget.username) {
        return;
      }

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: sender,
        text: text,
      );

      _addMessage(message);
    });

    // Secondary channel: some servers emit a dedicated event for room headcount.
    WebSocketService.instance.socket.on('room_users', (data) {
      if (!mounted) return;
      final count =
          (data['count'] ?? data['user_count'] ?? data['users']) as int?;
      if (count != null) _memberCountNotifier.value = count;
    });
  }

  /// Adds the welcome system messages after a short animation delay.
  void _queueSystemMessages() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // _addMessage(
      //   // ChatMessage(
      //   //   id: DateTime.now().millisecondsSinceEpoch.toString(),
      //   //   sender: 'System',
      //   //   text: widget.roomName != null
      //   //       ? 'Accessing Dimension "${widget.roomName}"...\nCode: ${widget.roomCode}'
      //   //       : 'Link established with Room ${widget.roomCode}',
      //   // ),
      // );
    });
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  void _addMessage(ChatMessage message) {
    // Persist non-system messages to the room store.
    if (message.sender != 'System') {
      RoomManager.instance.addMessageToRoom(widget.roomCode, message);
    }
    _messageListKey.currentState?.addMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  void _sendMessage() {
    final raw = _messageController.text.trim();
    if (raw.isEmpty) return;

    final result = RoomManager.instance.validateMessage(
      roomCode: widget.roomCode,
      username: widget.username,
      rawText: raw,
    );

    if (!result.isAccepted) {
      _showMessageError(result.rejectReason!);
      return;
    }

    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: widget.username,
        text: result.sanitizedText!,
        replyToId: _replyingTo?.id,
        replyToSender: _replyingTo?.sender,
        replyToText: _replyingTo?.text,
      ),
    );
    setState(() => _sendButtonPressed = true);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _sendButtonPressed = false);
    });
    WebSocketService.instance.sendMessage(result.sanitizedText!);
    _messageController.clear();
    setState(() {
      _replyingTo = null;
    });
    _focusNode.requestFocus();
  }

  /// Shows a non-dismissing inline error for rejected messages.
  void _showMessageError(MessageRejectReason reason) {
    final text = switch (reason) {
      MessageRejectReason.tooLong =>
        'Too long — max $kMaxMessageLength characters.',
      MessageRejectReason.payloadTooLarge =>
        'Payload too large — max ${kMaxPayloadBytes ~/ 1024} KB.',
      MessageRejectReason.rateLimited =>
        'Slow down — max $kRateLimitCount messages per second.',
      MessageRejectReason.empty => 'Message is empty after content filtering.',
    };
    AppToast.show(context, text, duration: const Duration(seconds: 2));
  }

  /// Animated reply-to banner shown above the text input.
  Widget _buildReplyBanner() {
    // ── Pre-send reply banner size controls ───────────────────────────────
    const double replyBannerWidth = 400; // or e.g. 320
    const double replyBannerHeight = 58; // height in logical px
    const double replyBannerPaddingLeft = 0; // nudge left edge
    const double replyBannerPaddingRight = 70; // nudge right edge
    // ─────────────────────────────────────────────────────────────────────
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _replyingTo == null
            ? const SizedBox.shrink(key: ValueKey('reply-empty'))
            : Padding(
                key: const ValueKey('reply-banner'),
                padding: EdgeInsets.only(
                  bottom: 8,
                  left: replyBannerPaddingLeft,
                  right: replyBannerPaddingRight,
                ),
                child: SizedBox(
                  width: replyBannerWidth,
                  height: replyBannerHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2027).withOpacity(0.82),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.neonCyan.withOpacity(0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.neonCyan,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _replyingTo!.sender == widget.username
                                        ? 'You'
                                        : _replyingTo!.sender,
                                    style: TextStyle(
                                      color: AppColors.neonCyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _replyingTo!.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _replyingTo = null),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.35),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: _ChatAppBar(
        roomName: widget.roomName,
        roomCode: widget.roomCode,
        username: widget.username,
        memberCountNotifier: _memberCountNotifier,
        onDeleteChat: () {
          _messageListKey.currentState?.clearMessages();
          setState(() => _replyingTo = null);
        },
        onLeaveRoom: () {
          RoomManager.instance.leaveRoom(widget.roomCode, widget.username);
          Navigator.pop(context);
        },
      ),
      body: ValueListenableBuilder<ChatTheme>(
        valueListenable: ThemeManager.instance.current,
        builder: (context, activeTheme, _) {
          final themeData = kChatThemes[activeTheme]!;
          return Stack(
            children: [
              // ── Theme-reactive background ───────────────────────────────────
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient:
                          themeData.backgroundGradient ??
                          const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E1E2E),
                              Color(0xFF2A2A40),
                              Color(0xFF1E1E2E),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
              // ── Message list (isolated widget — only it rebuilds on new msg) ──
              _MessageListView(
                key: _messageListKey,
                username: widget.username,
                scrollController: _scrollController,
                onReply: (msg) => setState(() {
                  _replyingTo = msg;
                  _focusNode.requestFocus();
                }),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: MediaQuery.of(context).padding.bottom + 14,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildReplyBanner(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: ListenableBuilder(
                              listenable: _focusNode,
                              builder: (context, _) {
                                final focused = _focusNode.hasFocus;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    // Border lives here — outside ClipRRect so it
                                    // is never clipped and renders on all edges.
                                    border: Border.all(
                                      color: focused
                                          ? Colors.white.withOpacity(0.58)
                                          : Colors.white.withOpacity(0.34),
                                      width: focused ? 1.6 : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.20),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                      if (focused)
                                        BoxShadow(
                                          color: AppColors.neonCyan.withOpacity(
                                            0.28,
                                          ),
                                          blurRadius: 18,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(29),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 6,
                                        sigmaY: 6,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOut,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(
                                                focused ? 0.28 : 0.20,
                                              ),
                                              Colors.white.withOpacity(
                                                focused ? 0.14 : 0.09,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            29,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 16,
                                              right: 16,
                                              top: 0,
                                              child: Container(
                                                height: 1,
                                                color: Colors.white.withOpacity(
                                                  focused ? 0.66 : 0.48,
                                                ),
                                              ),
                                            ),
                                            TextField(
                                              controller: _messageController,
                                              focusNode: _focusNode,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              maxLength: kMaxMessageLength,
                                              maxLines: null,
                                              decoration: InputDecoration(
                                                hintText: _replyingTo != null
                                                    ? 'Replying to message...'
                                                    : 'Type a message...',
                                                hintStyle: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.62),
                                                  fontSize: 15,
                                                  letterSpacing: 0.2,
                                                ),
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                counterText: '',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 14,
                                                    ),
                                              ),
                                              onSubmitted: (_) =>
                                                  _sendMessage(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _sendMessage,
                            onTapDown: (_) =>
                                setState(() => _sendButtonPressed = true),
                            onTapUp: (_) =>
                                setState(() => _sendButtonPressed = false),
                            onTapCancel: () =>
                                setState(() => _sendButtonPressed = false),
                            child: AnimatedScale(
                              scale: _sendButtonPressed ? 0.82 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOutCubic,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.webGreenyellow,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.webGreenyellow
                                          .withOpacity(
                                            _sendButtonPressed ? 0.2 : 0.4,
                                          ),
                                      blurRadius: _sendButtonPressed ? 6 : 14,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Color(0xFF1A3300),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Helper: popup menu item builder ────────────────────────────────────────

PopupMenuItem<String> _menuItem({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return PopupMenuItem<String>(
    value: value,
    height: 48,
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}
