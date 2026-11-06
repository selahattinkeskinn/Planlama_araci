import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../models/llm_chat_model.dart';
import '../../services/llm_service.dart';
import '../../services/llm_settings_service.dart';

sealed class LlmChatEvent {
  const LlmChatEvent();
}

/// Ekran açıldığında son oturumu yükler (yoksa yeni oturum hazırlar).
class LlmChatStarted extends LlmChatEvent {
  const LlmChatStarted();
}

/// Kullanıcı yeni bir mesaj gönderdi.
class SendPrompt extends LlmChatEvent {
  const SendPrompt(this.text);

  final String text;
}

/// Yeni bir sohbet oturumu başlatır.
class NewSession extends LlmChatEvent {
  const NewSession();
}

/// Son gönderilen istemi tekrar dener.
class RetryLastPrompt extends LlmChatEvent {
  const RetryLastPrompt();
}

sealed class LlmChatState {
  const LlmChatState();
}

class LlmChatInitial extends LlmChatState {
  const LlmChatInitial();
}

class LlmChatLoaded extends LlmChatState {
  const LlmChatLoaded({
    required this.messages,
    this.sessionId,
    this.isSending = false,
  });

  final List<LlmMessage> messages;
  final String? sessionId;
  final bool isSending;
}

class LlmChatError extends LlmChatState {
  const LlmChatError({
    required this.message,
    this.messages = const <LlmMessage>[],
    this.sessionId,
  });

  final String message;
  final List<LlmMessage> messages;
  final String? sessionId;
}

/// LLM sohbet durumunu yönetir: mesajları Hive'a yazar ve akışı canlı yayınlar.
class LlmChatBloc extends Bloc<LlmChatEvent, LlmChatState> {
  LlmChatBloc({
    LlmSettingsService? settingsService,
    LlmService Function(LlmSettings settings)? serviceFactory,
  }) : _settingsService = settingsService ?? LlmSettingsService(),
       _serviceFactory =
           serviceFactory ??
           ((settings) => LlmService(
             apiKey: settings.apiKey,
             baseUrl: settings.baseUrl,
             model: settings.model,
           )),
       super(const LlmChatInitial()) {
    on<LlmChatStarted>(_onStarted);
    on<SendPrompt>(_onSendPrompt);
    on<NewSession>(_onNewSession);
    on<RetryLastPrompt>(_onRetryLastPrompt);
  }

  static const String messagesBoxName = 'llm_messages';
  static const String sessionsBoxName = 'llm_sessions';

  final LlmSettingsService _settingsService;
  final LlmService Function(LlmSettings settings) _serviceFactory;

  Box<dynamic>? _messagesBox;
  Box<dynamic>? _sessionsBox;
  String? _currentSessionId;
  String? _lastPrompt;
  CancelToken? _cancelToken;
  bool _isSending = false;

  String? get currentSessionId => _currentSessionId;

  Future<void> _ensureBoxes() async {
    if (_messagesBox == null || !_messagesBox!.isOpen) {
      _messagesBox = Hive.isBoxOpen(messagesBoxName)
          ? Hive.box<dynamic>(messagesBoxName)
          : await Hive.openBox<dynamic>(messagesBoxName);
    }
    if (_sessionsBox == null || !_sessionsBox!.isOpen) {
      _sessionsBox = Hive.isBoxOpen(sessionsBoxName)
          ? Hive.box<dynamic>(sessionsBoxName)
          : await Hive.openBox<dynamic>(sessionsBoxName);
    }
  }

  Future<void> _onStarted(
    LlmChatStarted event,
    Emitter<LlmChatState> emit,
  ) async {
    await _ensureBoxes();

    final sessions = _sessionsBox!.values
        .whereType<Map<dynamic, dynamic>>()
        .map(LlmChatSession.fromMap)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (sessions.isEmpty) {
      _currentSessionId = _newSessionId();
      emit(const LlmChatLoaded(messages: <LlmMessage>[]));
      return;
    }

    final session = sessions.first;
    _currentSessionId = session.id;
    emit(
      LlmChatLoaded(
        sessionId: session.id,
        messages: _messagesFor(session.id),
      ),
    );
  }

  Future<void> _onNewSession(
    NewSession event,
    Emitter<LlmChatState> emit,
  ) async {
    _cancelStreaming();
    await _ensureBoxes();
    _currentSessionId = _newSessionId();
    _lastPrompt = null;
    emit(const LlmChatLoaded(messages: <LlmMessage>[]));
  }

  Future<void> _onRetryLastPrompt(
    RetryLastPrompt event,
    Emitter<LlmChatState> emit,
  ) async {
    final prompt = _lastPrompt;
    if (prompt == null || _isSending) return;
    add(SendPrompt(prompt));
  }

  Future<void> _onSendPrompt(
    SendPrompt event,
    Emitter<LlmChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || _isSending) return;

    await _ensureBoxes();
    _currentSessionId ??= _newSessionId();
    final sessionId = _currentSessionId!;
    _lastPrompt = text;
    _isSending = true;

    final previous = _messagesFor(sessionId);
    final now = DateTime.now();
    final userMessage = LlmMessage(
      id: '${sessionId}_u_${now.microsecondsSinceEpoch}',
      sessionId: sessionId,
      text: text,
      isUser: true,
      createdAt: now,
    );
    await _messagesBox!.put(userMessage.id, userMessage.toMap());
    await _messagesBox!.flush();
    await _touchSession(sessionId, firstUserText: text);

    final history = List<LlmMessage>.unmodifiable(previous);
    var withUser = <LlmMessage>[...previous, userMessage];

    final assistantId = '${sessionId}_a_${now.microsecondsSinceEpoch}';
    var assistant = LlmMessage(
      id: assistantId,
      sessionId: sessionId,
      text: '',
      isUser: false,
      createdAt: now.add(const Duration(milliseconds: 1)),
      isStreaming: true,
    );

    var visible = <LlmMessage>[...withUser, assistant];
    emit(
      LlmChatLoaded(
        messages: visible,
        sessionId: sessionId,
        isSending: true,
      ),
    );

    try {
      final settings = await _settingsService.load();
      if (!settings.isConfigured) {
        _isSending = false;
        emit(
          LlmChatError(
            sessionId: sessionId,
            messages: withUser,
            message:
                'API anahtarı ayarlanmamış. Sağ üstteki ayarlar simgesinden '
                'anahtarınızı ekleyin.',
          ),
        );
        return;
      }

      final service = _serviceFactory(settings);
      final buffer = StringBuffer();
      _cancelToken = CancelToken();

      await service.streamChat(
        history: history,
        prompt: text,
        cancelToken: _cancelToken,
        onChunk: (chunk) {
          if (isClosed || (_cancelToken?.isCancelled ?? false)) return;
          buffer.write(chunk);
          assistant = assistant.copyWith(text: buffer.toString());
          visible = <LlmMessage>[...withUser, assistant];
          emit(
            LlmChatLoaded(
              messages: visible,
              sessionId: sessionId,
              isSending: true,
            ),
          );
        },
      );

      _isSending = false;
      final finalMessage = assistant.copyWith(
        text: buffer.isEmpty
            ? 'Yanıt alınamadı. Lütfen tekrar deneyin.'
            : buffer.toString(),
        isStreaming: false,
      );
      visible = <LlmMessage>[...withUser, finalMessage];
      await _messagesBox!.put(finalMessage.id, finalMessage.toMap());
      await _messagesBox!.flush();
      await _touchSession(sessionId, firstUserText: text);

      if (isClosed) return;
      emit(
        LlmChatLoaded(messages: visible, sessionId: sessionId),
      );
    } on LlmApiException catch (error) {
      _isSending = false;
      final partial = assistant.copyWith(isStreaming: false);
      if (partial.text.trim().isNotEmpty) {
        await _messagesBox!.put(partial.id, partial.toMap());
        await _messagesBox!.flush();
        withUser = <LlmMessage>[...withUser, partial];
      }
      if (isClosed) return;
      emit(
        LlmChatError(
          sessionId: sessionId,
          messages: withUser,
          message: error.message,
        ),
      );
    } catch (error) {
      _isSending = false;
      if (isClosed) return;
      emit(
        LlmChatError(
          sessionId: sessionId,
          messages: withUser,
          message: 'Beklenmeyen bir hata oluştu: $error',
        ),
      );
    } finally {
      _isSending = false;
      _cancelToken = null;
    }
  }

  List<LlmMessage> _messagesFor(String sessionId) {
    final messages = _messagesBox!.values
        .whereType<Map<dynamic, dynamic>>()
        .map(LlmMessage.fromMap)
        .where((message) => message.sessionId == sessionId && !message.isStreaming)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> _touchSession(
    String sessionId, {
    required String firstUserText,
  }) async {
    final existing = _sessionsBox!.get(sessionId);
    final previous = existing is Map<dynamic, dynamic>
        ? LlmChatSession.fromMap(existing)
        : null;

    final isFirstMessage =
        _messagesBox!.values
            .whereType<Map<dynamic, dynamic>>()
            .map(LlmMessage.fromMap)
            .where((m) => m.sessionId == sessionId && m.isUser)
            .length <=
        1;

    final title = (isFirstMessage || (previous?.title ?? '').isEmpty)
        ? _titleFrom(firstUserText)
        : previous!.title;

    final session = LlmChatSession(
      id: sessionId,
      title: title,
      createdAt: previous?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _sessionsBox!.put(sessionId, session.toMap());
    await _sessionsBox!.flush();
  }

  String _titleFrom(String text) {
    final singleLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 40) return singleLine;
    return '${singleLine.substring(0, 40)}…';
  }

  String _newSessionId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _cancelStreaming() {
    _cancelToken?.cancel('Yeni oturum başlatıldı');
    _cancelToken = null;
  }

  @override
  Future<void> close() {
    _cancelStreaming();
    return super.close();
  }
}
