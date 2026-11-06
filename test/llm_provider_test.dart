import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/models/llm_chat_model.dart';
import 'package:flutter_application_1/models/llm_provider.dart';
import 'package:flutter_application_1/services/llm_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('base URL normalizasyonu', () {
    test('sondaki eğik çizgi ve tam uç adresi temizlenir', () {
      expect(
        LlmProviders.normalizeBaseUrl('https://api.openai.com/v1/'),
        'https://api.openai.com/v1',
      );
      expect(
        LlmProviders.normalizeBaseUrl(
          'https://api.groq.com/openai/v1/chat/completions',
        ),
        'https://api.groq.com/openai/v1',
      );
    });

    test('Gemini için eksik /openai yolu tamamlanır', () {
      expect(
        LlmProviders.normalizeBaseUrl(
          'https://generativelanguage.googleapis.com/v1beta',
        ),
        'https://generativelanguage.googleapis.com/v1beta/openai',
      );
      expect(
        LlmProviders.normalizeBaseUrl(
          'https://generativelanguage.googleapis.com/v1beta/openai/',
        ),
        'https://generativelanguage.googleapis.com/v1beta/openai',
      );
    });

    test('Groq ve OpenRouter yolları tamamlanır', () {
      expect(
        LlmProviders.normalizeBaseUrl('https://api.groq.com'),
        'https://api.groq.com/openai/v1',
      );
      expect(
        LlmProviders.normalizeBaseUrl('https://openrouter.ai'),
        'https://openrouter.ai/api/v1',
      );
    });
  });

  group('anahtar sağlayıcı eşleşmesi', () {
    test('OpenRouter anahtarı OpenAI ile karıştırılmaz', () {
      const key = 'sk-or-v1-abc123';
      expect(LlmProviders.detectByKey(key)?.id, 'openrouter');
      expect(LlmProviders.openai.acceptsKey(key), isFalse);
      expect(LlmProviders.openRouter.acceptsKey(key), isTrue);
    });

    test('Gemini anahtarı AIza ile tanınır', () {
      expect(LlmProviders.detectByKey('AIzaSyD-123')?.id, 'gemini');
      expect(LlmProviders.gemini.acceptsKey('sk-proj-abc'), isFalse);
    });

    test('Ollama anahtarsız çalışır', () {
      expect(LlmProviders.ollama.acceptsKey(''), isTrue);
      expect(LlmProviders.groq.acceptsKey(''), isFalse);
    });
  });

  test('Gemini hata dizisi anlaşılır Türkçe mesaja çevrilir', () async {
    // Gemini, hatayı JSON dizisi içinde ve INVALID_ARGUMENT olarak döner.
    const body =
        '[{"error":{"code":400,"message":"Please pass a valid API key",'
        '"status":"INVALID_ARGUMENT"}}]';
    final dio = Dio()..httpClientAdapter = _FakeAdapter(400, body);
    final service = LlmService(
      apiKey: 'sk-proj-openai-anahtari',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
      model: 'gemini-flash-latest',
      dio: dio,
    );

    await expectLater(
      service.streamChat(
        history: const <LlmMessage>[],
        prompt: 'merhaba',
        onChunk: (_) {},
      ),
      throwsA(
        isA<LlmApiException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('Google Gemini'),
            contains('AIza'),
            contains('OpenAI'),
          ),
        ),
      ),
    );
  });
}
