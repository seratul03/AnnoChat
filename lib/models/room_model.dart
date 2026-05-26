import 'dart:collection';
import 'message_model.dart';

/// Maximum number of messages retained per room.
const int kRoomMessageLimit = 300;

/// Default room lifetime.
const Duration kRoomDefaultExpiry = Duration(hours: 24);

class Room {
  final String code;
  final String name;
  final int maxUsers;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// Timestamp of the last user-visible activity (message sent or user joined).
  /// Used by the background cleanup task to detect idle rooms.
  DateTime lastActivityAt;

  /// Active users currently in this room.
  final Set<String> users = {};

  /// Rolling message buffer – oldest message is dropped when [kRoomMessageLimit]
  /// is reached, mirroring a Python deque(maxlen=300).
  final Queue<ChatMessage> messages = Queue<ChatMessage>();

  Room({
    required this.code,
    required this.name,
    required this.maxUsers,
    required this.createdAt,
    required this.expiresAt,
  }) : lastActivityAt = createdAt;

  /// Refreshes [lastActivityAt] to the current time.  Call this whenever
  /// meaningful activity occurs (message sent, user joined).
  void touchActivity() => lastActivityAt = DateTime.now();

  /// Returns `true` when the room has had no activity for longer than [timeout].
  bool isInactive(Duration timeout) =>
      DateTime.now().difference(lastActivityAt) > timeout;

  // ── Computed state ───────────────────────────────────────────────────────

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isFull => users.length >= maxUsers;
  bool get isEmpty => users.isEmpty;

  /// How much time is left before this room expires.
  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ── Message management ───────────────────────────────────────────────────

  void addMessage(ChatMessage message) {
    if (messages.length >= kRoomMessageLimit) {
      messages.removeFirst();
    }
    messages.addLast(message);
    touchActivity(); // a new message counts as activity
  }

  List<ChatMessage> get messageList => messages.toList();

  // ── Debug / logging ──────────────────────────────────────────────────────

  @override
  String toString() =>
      'Room(code: $code, name: "$name", users: ${users.length}/$maxUsers, '
      'expired: $isExpired, expiresAt: $expiresAt)';
}
