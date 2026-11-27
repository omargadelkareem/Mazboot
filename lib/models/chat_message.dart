class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.imageBase64,
    this.seen = false,
  });

  final String id;
  final String senderId;
  final String text;
  final int sentAt;
  final String? imageBase64;
  final bool seen;

  factory ChatMessage.fromMap(String id, Map<Object?, Object?> map) =>
      ChatMessage(
        id: id,
        senderId: map['senderId']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        sentAt: (map['sentAt'] as num?)?.toInt() ?? 0,
        imageBase64: map['imageBase64']?.toString(),
        seen: map['seen'] as bool? ?? false,
      );

  Map<String, Object?> toMap() => {
    'senderId': senderId,
    'text': text,
    'sentAt': sentAt,
    if (imageBase64 != null) 'imageBase64': imageBase64,
    'seen': seen,
  };
}
