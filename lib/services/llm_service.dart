import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/llm_chat_model.dart';
import '../models/llm_provider.dart';

/// Kullanıcıya gösterilebilir LLM hatası.
class LlmApiException implements Exception {
  const LlmApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// OpenAI uyumlu `/chat/completions` ucuna akışlı (SSE) istek atan istemci.
class LlmService {
  LlmService({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String apiKey;
  final String baseUrl;
  final String model;
  final Dio _dio;

  /// Sunucu adresi; sondaki eğik çizgiler ve olası tam uç adresi temizlenir.
  String get _base {
    var base = LlmProviders.normalizeBaseUrl(baseUrl);
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  String get _endpoint => '$_base/chat/completions';

  LlmProviderPreset? get _provider => LlmProviders.matchByBaseUrl(baseUrl);

  /// Sağlayıcının desteklediği model kimliklerini listeler.
  Future<List<String>> listModels({CancelToken? cancelToken}) async {
    if (apiKey.trim().isEmpty && (_provider?.requiresApiKey ?? true)) {
      throw const LlmApiException(
        'API anahtarı ayarlanmamış. Ayarlar bölümünden ekleyin.',
      );
    }

    Response<ResponseBody> response;
    try {
      response = await _dio.get<ResponseBody>(
        '$_base/models',
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 500,
          headers: <String, String>{
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Accept': 'application/json',
          },
        ),
      );
    } on DioException catch (error) {
      throw LlmApiException(_describeDioError(error));
    }

    final body = response.data;
    if (body == null) {
      throw const LlmApiException('Sunucudan boş yanıt geldi.');
    }

    final raw = await _readBody(body);
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw LlmApiException(_extractErrorMessage(raw, status));
    }

    final models = <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final data = decoded['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map && item['id'] is String) {
              models.add(item['id'] as String);
            }
          }
        } else if (decoded['models'] is List) {
          // Gemini'nin yerel biçimi: models/xxx
          for (final item in decoded['models'] as List) {
            if (item is Map && item['id'] is String) {
              models.add((item['id'] as String).replaceFirst('models/', ''));
            }
          }
        }
      }
    } catch (_) {
      throw const LlmApiException(
        'Model listesi okunamadı. Sunucu OpenAI uyumlu olmayabilir.',
      );
    }

    if (models.isEmpty) {
      throw const LlmApiException(
        'Sunucu model listesi döndürmedi. Model adını elle girmeyi deneyin.',
      );
    }
    models.sort();
    return models;
  }

  /// Geçmiş mesajlar + yeni istemle akış başlatır.
  ///
  /// Her gelen parça [onChunk] ile bildirilir. Akış bittiğinde döner.
  Future<void> streamChat({
    required List<LlmMessage> history,
    required String prompt,
    required void Function(String chunk) onChunk,
    CancelToken? cancelToken,
  }) async {
    if (apiKey.trim().isEmpty && (_provider?.requiresApiKey ?? true)) {
      throw const LlmApiException(
        'API anahtarı ayarlanmamış. Ayarlar bölümünden ekleyin.',
      );
    }

    final messages = <Map<String, String>>[
      <String, String>{
        'role': 'system',
        'content': LlmDefaults.systemPrompt,
      },
      ...history
          .where((m) => m.text.trim().isNotEmpty && !m.isStreaming)
          .map((m) => m.toApiMap()),
      <String, String>{'role': 'user', 'content': prompt},
    ];

    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        _endpoint,
        data: <String, dynamic>{
          'model': model,
          'messages': messages,
          'stream': true,
          'temperature': 0.7,
        },
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          validateStatus: (status) => status != null && status < 500,
          headers: <String, String>{
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
        ),
      );
    } on DioException catch (error) {
      throw LlmApiException(_describeDioError(error));
    }

    final body = response.data;
    if (body == null) {
      throw const LlmApiException('Sunucudan boş yanıt geldi.');
    }

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      final raw = await _readBody(body);
      throw LlmApiException(_extractErrorMessage(raw, status));
    }

    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    try {
      await for (final line in lines) {
        if (cancelToken?.isCancelled ?? false) break;

        final trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;

        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') break;

        try {
          final decoded = jsonDecode(data);
          if (decoded is! Map) continue;
          final choices = decoded['choices'];
          if (choices is! List || choices.isEmpty) continue;
          final first = choices.first;
          if (first is! Map) continue;
          final delta = first['delta'];
          if (delta is Map) {
            final content = delta['content'];
            if (content is String && content.isNotEmpty) {
              onChunk(content);
            }
          }
        } catch (_) {
          // Tek bir bozuk satır tüm akışı bozmasın.
        }
      }
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      throw LlmApiException(_describeDioError(error));
    }
  }

  Future<String> _readBody(ResponseBody body) async {
    try {
      final bytes = await body.stream.fold<List<int>>(
        <int>[],
        (previous, chunk) => previous..addAll(chunk),
      );
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  String _extractErrorMessage(String raw, int status) {
    String? apiMessage;
    String? apiCode;
    String? apiType;

    if (raw.isNotEmpty) {
      try {
        // Bazı sağlayıcılar (ör. Gemini) hatayı JSON *dizisi* içinde döner.
        Object? decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          decoded = decoded.first;
        }
        if (decoded is Map) {
          final error = decoded['error'];
          if (error is Map) {
            if (error['message'] is String) {
              apiMessage = error['message'] as String;
            }
            if (error['code'] is String) {
              apiCode = error['code'] as String;
            }
            if (error['type'] is String) {
              apiType = error['type'] as String;
            }
            if (error['status'] is String && apiType == null) {
              apiType = error['status'] as String;
            }
          } else if (decoded['message'] is String) {
            apiMessage = decoded['message'] as String;
          }
        }
      } catch (_) {
        // JSON değilse aşağıda ham metin gösterilir.
      }
    }

    final lower = (apiMessage ?? '').toLowerCase();
    final provider = _provider;
    final keyOwner = LlmProviders.detectByKey(apiKey);

    final keyRejected =
        lower.contains('api key') ||
        lower.contains('api_key') ||
        lower.contains('invalid key') ||
        lower.contains('unauthorized') ||
        apiCode == 'invalid_api_key' ||
        status == 401;

    if (keyRejected) {
      final buffer = StringBuffer();

      if (provider != null &&
          !provider.acceptsKey(apiKey) &&
          apiKey.trim().isNotEmpty) {
        buffer.write('API anahtarı reddedildi ($status). ');
        if (keyOwner != null && keyOwner.id != provider.id) {
          buffer.write(
            'Girdiğiniz anahtar ${keyOwner.label} anahtarı gibi görünüyor; '
            '${provider.label} anahtarı ${provider.keyHint}. ',
          );
        } else {
          buffer.write(
            '${provider.label} anahtarı ${provider.keyHint}. ',
          );
        }
        buffer.write('Doğru anahtarı ${provider.docsUrl} adresinden alın.');
        return buffer.toString();
      }

      if (provider != null) {
        return 'API anahtarı geçersiz ($status). ${provider.label} anahtarı '
            '${provider.keyHint}. ${provider.docsUrl} adresinden kontrol edin.';
      }

      return 'API anahtarı geçersiz veya yetkisiz ($status). Ayarlar '
          'bölümünden anahtarınızı kontrol edin.';
    }

    if (status == 403) {
      return 'Bu anahtar veya model için yetkiniz yok (403).';
    }
    if (status == 404) {
      final modelHint = provider == null
          ? ''
          : ' ${provider.label} için güncel model kimliğini Ayarlar > '
                '"MODELLERİ GETİR" ile listeden seçin.';
      return 'Model ya da adres bulunamadı (404). Ayarlar bölümündeki '
          '"Model" ve "Sunucu (Base URL)" alanlarını kontrol edin.$modelHint';
    }

    final quotaExceeded =
        apiCode == 'insufficient_quota' ||
        apiType == 'insufficient_quota' ||
        lower.contains('no credits') ||
        lower.contains('insufficient quota') ||
        lower.contains('exceeded your current quota') ||
        lower.contains('billing');

    if (quotaExceeded) {
      final where = provider?.id == 'openai'
          ? 'OpenAI hesabınıza kredi ekleyin: '
                'platform.openai.com/settings/organization/billing.'
          : 'Sağlayıcı hesabınızın kotası/bakiyesi doldu.';
      return 'API bakiyeniz bitmiş (429). $where Alternatif olarak Ayarlar '
          'bölümünden başka bir ücretsiz sağlayıcı seçebilirsiniz.';
    }

    final rateLimited =
        apiCode == 'rate_limit_exceeded' ||
        apiType == 'requests' ||
        apiType == 'tokens' ||
        lower.contains('rate limit') ||
        lower.contains('quota exceeded');

    if (status == 429) {
      if (rateLimited) {
        return 'İstek sınırı aşıldı (429): çok sık istek gönderildi veya '
            'dakikalık/günlük kotanız doldu. Bir süre bekleyip tekrar deneyin.';
      }
      return 'Çok fazla istek gönderildi (429). Biraz bekleyip tekrar deneyin.';
    }

    if (apiMessage != null && apiMessage.isNotEmpty) {
      return 'API hatası ($status): $apiMessage';
    }

    if (raw.isNotEmpty) {
      final short = raw.length > 300 ? raw.substring(0, 300) : raw;
      return 'API hatası ($status): $short';
    }
    return 'API hatası ($status).';
  }

  String _describeDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Sunucuya bağlanılamadı (zaman aşımı). İnternetinizi kontrol edin.';
      case DioExceptionType.receiveTimeout:
        return 'Yanıt çok uzun sürdü (zaman aşımı).';
      case DioExceptionType.connectionError:
        return 'İnternet bağlantısı kurulamadı. Sunucu adresini kontrol edin.';
      case DioExceptionType.badCertificate:
        return 'Sunucu sertifikası doğrulanamadı.';
      case DioExceptionType.cancel:
        return 'İstek iptal edildi.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final status = error.response?.statusCode;
        if (status != null && (status == 401 || status == 403)) {
          return 'API anahtarı geçersiz veya yetkisiz ($status).';
        }
        if (status != null) {
          return 'Sunucu hatası ($status).';
        }
        return 'Bağlantı hatası: ${error.message ?? 'bilinmeyen hata'}';
      default:
        return 'Bağlantı hatası: ${error.message ?? 'bilinmeyen hata'}';
    }
  }
}

/// Testlerde kolayca sahte akış üretmek için yardımcı.
class FakeResponseBodyStream {
  FakeResponseBodyStream(this.chunks);

  final List<List<int>> chunks;

  Stream<Uint8List> get stream =>
      Stream<Uint8List>.fromIterable(chunks.map(Uint8List.fromList));
}
