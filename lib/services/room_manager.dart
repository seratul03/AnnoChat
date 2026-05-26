import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import '../models/room_model.dart';
import '../models/message_model.dart';

// ── Message control constants ────────────────────────────────────────────────

/// Hard cap on message text length (characters).
const int kMaxMessageLength = 500;

/// Hard cap on the UTF-8 byte size of a single message payload.
const int kMaxPayloadBytes = 2048; // 2 KB

/// Max messages a single user may send within [kRateLimitWindow].
const int kRateLimitCount = 5;

/// Sliding-window duration for rate-limit enforcement.
const Duration kRateLimitWindow = Duration(seconds: 1);

// ── Result types ─────────────────────────────────────────────────────────────

enum CreateRoomResult { success, codeTaken }

enum JoinRoomResult {
  success,
  roomNotFound,
  roomExpired,
  roomFull,
  alreadyInRoom,
}

/// Reasons a message can be rejected before it reaches the room store.
enum MessageRejectReason {
  /// Text was empty (or became empty after HTML stripping).
  empty,

  /// Exceeds [kMaxMessageLength] characters.
  tooLong,

  /// UTF-8 byte size exceeds [kMaxPayloadBytes].
  payloadTooLarge,

  /// User is sending faster than [kRateLimitCount] per [kRateLimitWindow].
  rateLimited,
}

/// Result returned by [RoomManager.validateMessage].
class MessageValidationResult {
  /// Non-null when the message was accepted; contains the sanitized text.
  final String? sanitizedText;

  /// Non-null when the message was rejected.
  final MessageRejectReason? rejectReason;

  const MessageValidationResult._({this.sanitizedText, this.rejectReason});

  factory MessageValidationResult.accepted(String text) =>
      MessageValidationResult._(sanitizedText: text);

  factory MessageValidationResult.rejected(MessageRejectReason reason) =>
      MessageValidationResult._(rejectReason: reason);

  bool get isAccepted => sanitizedText != null;
}

// ── RoomManager ───────────────────────────────────────────────────────────────

/// Singleton that owns the in-memory room dictionary.
///
/// Mirrors the conceptual Python structure:
/// ```
/// rooms = {
///   "AB1C23": {
///     "users": set(),
///     "messages": deque(maxlen=300),
///     "created_at": time,
///     "expires_at": time,
///   }
/// }
/// ```
class RoomManager {
  RoomManager._internal();

  static final RoomManager instance = RoomManager._internal();

  // ── Internal state ─────────────────────────────────────────────────────────

  /// Master room dictionary  – key is the unique room code.
  final Map<String, Room> _rooms = {};

  /// Per-user sliding window of recent message timestamps.
  /// Key: '$roomCode:$username'
  final Map<String, Queue<DateTime>> _rateLimits = {};

  Timer? _cleanupTimer;

  // ── Code generation ────────────────────────────────────────────────────────

  /// Characters used for room codes.  Visually ambiguous chars (0/O, 1/I/L)
  /// are intentionally excluded so codes are easy to read aloud.
  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
  static const int _codeLength = 6;

  /// Returns a new alphanumeric room code that is guaranteed not to collide
  /// with any currently active room.
  String generateUniqueCode() {
    final rng = Random.secure();
    String code;
    do {
      code = List.generate(
        _codeLength,
        (_) => _codeChars[rng.nextInt(_codeChars.length)],
      ).join();
    } while (_rooms.containsKey(code));
    return code;
  }

  // ── Room lifecycle ─────────────────────────────────────────────────────────

  /// Creates a new room.  Returns [CreateRoomResult.codeTaken] if [code] is
  /// already in use (race-condition guard).
  CreateRoomResult createRoom({
    required String code,
    required String name,
    required int maxUsers,
    Duration expiry = kRoomDefaultExpiry,
  }) {
    if (_rooms.containsKey(code)) return CreateRoomResult.codeTaken;

    final now = DateTime.now();
    _rooms[code] = Room(
      code: code,
      name: name,
      maxUsers: maxUsers,
      createdAt: now,
      expiresAt: now.add(expiry),
    );
    return CreateRoomResult.success;
  }

  /// Adds [username] to the room identified by [code].
  ///
  /// Enforces:
  ///   - Room existence
  ///   - Room expiry (expired rooms are lazily purged here)
  ///   - Max-users cap
  ///   - Duplicate join guard
  JoinRoomResult joinRoom(String code, String username) {
    final room = _rooms[code];

    if (room == null) return JoinRoomResult.roomNotFound;

    if (room.isExpired) {
      _rooms.remove(code); // lazy expiry purge
      return JoinRoomResult.roomExpired;
    }

    if (room.isFull) return JoinRoomResult.roomFull;

    if (room.users.contains(username)) return JoinRoomResult.alreadyInRoom;

    room.users.add(username);
    room.touchActivity(); // joining counts as activity
    return JoinRoomResult.success;
  }

  /// Removes [username] from the room.  Auto-deletes the room when it becomes
  /// empty (no active users remaining).
  void leaveRoom(String code, String username) {
    final room = _rooms[code];
    if (room == null) return;

    room.users.remove(username);
    // Drop rate-limit history for this user.
    _rateLimits.remove('$code:$username');

    if (room.isEmpty) {
      _rooms.remove(code);
    }
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  Room? getRoom(String code) => _rooms[code];

  bool roomExists(String code) => _rooms.containsKey(code);

  int get roomCount => _rooms.length;

  /// Read-only snapshot of all rooms (for debugging / admin views).
  Map<String, Room> get allRooms => Map.unmodifiable(_rooms);

  // ── Message validation ─────────────────────────────────────────────────────

  /// Validates and sanitizes [rawText] from [username] in room [roomCode].
  ///
  /// Enforces in order:
  ///   1. HTML / script injection stripping
  ///   2. Empty-after-sanitization guard
  ///   3. Character length cap ([kMaxMessageLength])
  ///   4. Byte payload cap ([kMaxPayloadBytes])
  ///   5. Per-user sliding-window rate limit ([kRateLimitCount] / [kRateLimitWindow])
  MessageValidationResult validateMessage({
    required String roomCode,
    required String username,
    required String rawText,
  }) {
    // 1. Sanitize HTML / script injection.
    final sanitized = _sanitize(rawText);

    // 2. Reject if empty after sanitization.
    if (sanitized.isEmpty) {
      return MessageValidationResult.rejected(MessageRejectReason.empty);
    }

    // 3. Character length.
    if (sanitized.length > kMaxMessageLength) {
      return MessageValidationResult.rejected(MessageRejectReason.tooLong);
    }

    // 4. Byte-payload size (protects against CJK / emoji-heavy strings that are
    //    short in chars but large in bytes).
    if (utf8.encode(sanitized).length > kMaxPayloadBytes) {
      return MessageValidationResult.rejected(
        MessageRejectReason.payloadTooLarge,
      );
    }

    // 5. Sliding-window rate limit.
    final key = '$roomCode:$username';
    final now = DateTime.now();
    final windowStart = now.subtract(kRateLimitWindow);
    final timestamps = _rateLimits.putIfAbsent(key, Queue.new);

    // Evict timestamps that are outside the current window.
    while (timestamps.isNotEmpty && timestamps.first.isBefore(windowStart)) {
      timestamps.removeFirst();
    }

    if (timestamps.length >= kRateLimitCount) {
      return MessageValidationResult.rejected(MessageRejectReason.rateLimited);
    }

    timestamps.addLast(now);
    return MessageValidationResult.accepted(sanitized);
  }

  /// Strips HTML tags, javascript:/data: URI schemes, and on* event handlers.
  static String _sanitize(String text) {
    var s = text
        // Remove all HTML/XML tags.
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Remove javascript: and data: URI schemes.
        .replaceAll(RegExp(r'javascript\s*:', caseSensitive: false), '')
        .replaceAll(RegExp(r'data\s*:', caseSensitive: false), '')
        // Remove inline on* event-handler attributes.
        .replaceAll(RegExp(r'\bon\w+\s*=', caseSensitive: false), '');
    return s.trim();
  }

  // ── Message management ─────────────────────────────────────────────────────

  void addMessageToRoom(String code, ChatMessage message) {
    _rooms[code]?.addMessage(message);
  }

  List<ChatMessage> getRoomMessages(String code) =>
      _rooms[code]?.messageList ?? [];

  // ── Cleanup timer ──────────────────────────────────────────────────────────

  /// How often the background task fires (30–60 s range, set to 45 s).
  static const Duration _cleanupInterval = Duration(seconds: 45);

  /// Rooms with no activity for longer than this are considered idle and purged.
  static const Duration kRoomInactivityTimeout = Duration(minutes: 5);

  /// Starts the background cleanup timer.  Call once from [main].
  void startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _runCleanup());
  }

  /// Stops the cleanup timer.  Useful in tests or when the app is suspended.
  void stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Purges rooms that satisfy any of the following conditions:
  ///   1. No active users (empty).
  ///   2. Past their [Room.expiresAt] timestamp (expired).
  ///   3. Had no activity ([Room.lastActivityAt]) for longer than
  ///      [kRoomInactivityTimeout] (inactive > 5 minutes).
  ///
  /// Orphaned rate-limit buckets for purged rooms are also removed.
  void _runCleanup() {
    final stale = _rooms.entries
        .where(
          (e) =>
              e.value.isEmpty ||
              e.value.isExpired ||
              e.value.isInactive(kRoomInactivityTimeout),
        )
        .map((e) => e.key)
        .toList();

    for (final code in stale) {
      _rooms.remove(code);
      // Remove all rate-limit buckets belonging to this room.
      _rateLimits.removeWhere((key, _) => key.startsWith('$code:'));
    }
  }
}
