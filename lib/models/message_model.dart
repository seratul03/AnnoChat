class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;

  /// Optional emoji reaction chosen by the local user.
  final String? reaction;

  /// Non-null when this message is a reply to another message.
  final String? replyToId;
  final String? replyToSender;
  final String? replyToText;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? timestamp,
    this.replyToId,
    this.replyToSender,
    this.replyToText,
    this.reaction,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? text,
    DateTime? timestamp,
    String? replyToId,
    String? replyToSender,
    String? replyToText,
    String? reaction,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      replyToSender: replyToSender ?? this.replyToSender,
      replyToText: replyToText ?? this.replyToText,
      reaction: reaction ?? this.reaction,
    );
  }
}
