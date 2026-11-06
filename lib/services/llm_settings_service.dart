import 'package:hive_ce/hive_ce.dart';

import '../models/llm_chat_model.dart';

/// LLM ayarlarını (API anahtarı, sunucu adresi, model) Hive üzerinde tutar.
///
/// Codegen gerektirmez; değerler düz `String` olarak saklanır.
class LlmSettings {
  const LlmSettings({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  LlmSettings copyWith({String? apiKey, String? baseUrl, String? model}) {
    return LlmSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }
}

class LlmSettingsService {
  static const String boxName = 'llm_settings';
  static const String _apiKeyKey = 'api_key';
  static const String _baseUrlKey = 'base_url';
  static const String _modelKey = 'model';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return Hive.openBox<dynamic>(boxName);
  }

  Future<LlmSettings> load() async {
    final box = await _box();
    return LlmSettings(
      apiKey: (box.get(_apiKeyKey) as String?)?.trim() ?? '',
      baseUrl: (box.get(_baseUrlKey) as String?)?.trim().isNotEmpty == true
          ? (box.get(_baseUrlKey) as String).trim()
          : LlmDefaults.baseUrl,
      model: (box.get(_modelKey) as String?)?.trim().isNotEmpty == true
          ? (box.get(_modelKey) as String).trim()
          : LlmDefaults.model,
    );
  }

  Future<void> save(LlmSettings settings) async {
    final box = await _box();
    await box.put(_apiKeyKey, settings.apiKey.trim());
    await box.put(_baseUrlKey, settings.baseUrl.trim());
    await box.put(_modelKey, settings.model.trim());
    await box.flush();
  }

  Future<void> clearApiKey() async {
    final box = await _box();
    await box.delete(_apiKeyKey);
  }
}
