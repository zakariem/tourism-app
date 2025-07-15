class ChatMessage {
  final int? id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final int? userId;

  ChatMessage({
    this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.userId,
  });

  // Convert ChatMessage to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
    };
  }

  // Create ChatMessage from Map (database row)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      message: map['message'] as String,
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['user_id'] as int?,
    );
  }

  // Create a copy of ChatMessage with optional new values
  ChatMessage copyWith({
    int? id,
    String? message,
    bool? isUser,
    DateTime? timestamp,
    int? userId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }
}
