/// LLM sohbetinde kullanılan mesaj ve oturum modelleri.
///
/// Hive'a codegen (adapter) gerektirmeden yazılabilmesi için modeller
/// `Map<String, dynamic>` üzerinden serileştirilir.
library;

class LlmMessage {
  const LlmMessage({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isStreaming = false,
  });

  final String id;
  final String sessionId;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isStreaming;

  bool get isAssistant => !isUser;

  LlmMessage copyWith({
    String? id,
    String? sessionId,
    String? text,
    bool? isUser,
    DateTime? createdAt,
    bool? isStreaming,
  }) {
    return LlmMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'sessionId': sessionId,
    'text': text,
    'isUser': isUser,
    'createdAt': createdAt.toIso8601String(),
    'isStreaming': isStreaming,
  };

  Map<String, String> toApiMap() => <String, String>{
    'role': isUser ? 'user' : 'assistant',
    'content': text,
  };

  factory LlmMessage.fromMap(Map<dynamic, dynamic> map) {
    return LlmMessage(
      id: '${map['id'] ?? ''}',
      sessionId: '${map['sessionId'] ?? ''}',
      text: '${map['text'] ?? ''}',
      isUser: map['isUser'] == true,
      createdAt:
          DateTime.tryParse('${map['createdAt'] ?? ''}') ?? DateTime.now(),
      isStreaming: map['isStreaming'] == true,
    );
  }
}

class LlmChatSession {
  const LlmChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LlmChatSession.fromMap(Map<dynamic, dynamic> map) {
    return LlmChatSession(
      id: '${map['id'] ?? ''}',
      title: '${map['title'] ?? 'Sohbet'}',
      createdAt:
          DateTime.tryParse('${map['createdAt'] ?? ''}') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? DateTime.now(),
    );
  }
}

/// Ayarlar ekranında kullanılan sabitler.
abstract final class LlmDefaults {
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String model = 'gpt-4o-mini';
  static const String systemPrompt =
      'Sen yardımcı, kısa ve net cevap veren bir Türkçe asistansın.';
}
