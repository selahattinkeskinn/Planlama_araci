import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/blocs/llm_chat/llm_chat_bloc.dart';
import 'package:flutter_application_1/models/llm_chat_model.dart';
import 'package:flutter_application_1/services/llm_service.dart';
import 'package:flutter_application_1/services/llm_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

class _FakeSettingsService extends LlmSettingsService {
  @override
  Future<LlmSettings> load() async => const LlmSettings(
    apiKey: 'test-key',
    baseUrl: 'https://example.com/v1',
    model: 'test-model',
  );

  @override
  Future<void> save(LlmSettings settings) async {}
}

class _FakeLlmService extends LlmService {
  _FakeLlmService()
    : super(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1',
        model: 'test-model',
      );

  @override
  Future<void> streamChat({
    required List<LlmMessage> history,
    required String prompt,
    required void Function(String chunk) onChunk,
    CancelToken? cancelToken,
  }) async {
    onChunk('Merhaba');
    onChunk(' dünya');
  }
}

class _FailingLlmService extends LlmService {
  _FailingLlmService()
    : super(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1',
        model: 'test-model',
      );

  @override
  Future<void> streamChat({
    required List<LlmMessage> history,
    required String prompt,
    required void Function(String chunk) onChunk,
    CancelToken? cancelToken,
  }) async {
    throw const LlmApiException('API anahtarı geçersiz (401).');
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('llm_chat_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  LlmChatBloc createBloc() => LlmChatBloc(
    settingsService: _FakeSettingsService(),
    serviceFactory: (_) => _FakeLlmService(),
  );

  test('mesaj gönderir, akışı birleştirir ve Hive\'a kaydeder', () async {
    final bloc = createBloc();
    addTearDown(bloc.close);

    final initial = bloc.stream.firstWhere((state) => state is LlmChatLoaded);
    bloc.add(const LlmChatStarted());
    await initial;

    final completed = bloc.stream.firstWhere(
      (state) =>
          state is LlmChatLoaded &&
          !state.isSending &&
          state.messages.length == 2,
    );
    bloc.add(const SendPrompt('Selam'));
    final state = await completed as LlmChatLoaded;

    expect(state.messages.first.text, 'Selam');
    expect(state.messages.first.isUser, isTrue);
    expect(state.messages.last.text, 'Merhaba dünya');
    expect(state.messages.last.isUser, isFalse);
    expect(state.messages.last.isStreaming, isFalse);

    await Hive.close();
    Hive.init(tempDir.path);

    final restoredBloc = createBloc();
    addTearDown(restoredBloc.close);

    final restoredFuture = restoredBloc.stream.firstWhere(
      (value) => value is LlmChatLoaded && value.messages.isNotEmpty,
    );
    restoredBloc.add(const LlmChatStarted());
    final restored = await restoredFuture as LlmChatLoaded;

    expect(restored.messages.map((message) => message.text), <String>[
      'Selam',
      'Merhaba dünya',
    ]);
    expect(restored.sessionId, state.sessionId);
  });

  test('API hatası durumunda kullanıcı mesajı korunur', () async {
    final bloc = LlmChatBloc(
      settingsService: _FakeSettingsService(),
      serviceFactory: (_) => _FailingLlmService(),
    );
    addTearDown(bloc.close);

    final failureFuture = bloc.stream.firstWhere(
      (state) => state is LlmChatError,
    );
    bloc.add(const LlmChatStarted());
    bloc.add(const SendPrompt('Deneme'));
    final failure = await failureFuture as LlmChatError;

    expect(failure.message, contains('401'));
    expect(failure.messages.single.text, 'Deneme');
    expect(failure.messages.single.isUser, isTrue);
  });
}
