/// OpenAI uyumlu sağlayıcı ön ayarları.
///
/// Amaç: kullanıcı yalnızca API anahtarını girsin; sunucu adresi ve model
/// otomatik dolsun. Böylece "Gemini sunucusu + OpenAI anahtarı" gibi
/// karışıklıklar yaşanmaz.
library;

class LlmProviderPreset {
  const LlmProviderPreset({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.defaultModel,
    required this.keyPrefixes,
    required this.keyHint,
    required this.docsUrl,
    this.modelSuggestions = const <String>[],
    this.requiresApiKey = true,
    this.note,
  });

  final String id;
  final String label;
  final String baseUrl;
  final String defaultModel;

  /// Anahtarın başlaması gereken önekler. Boş liste = biçim denetlenmez.
  final List<String> keyPrefixes;

  /// Kullanıcıya gösterilen kısa anahtar biçimi açıklaması.
  final String keyHint;

  /// Anahtarın alındığı adres.
  final String docsUrl;

  final List<String> modelSuggestions;
  final bool requiresApiKey;
  final String? note;

  bool acceptsKey(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return !requiresApiKey;
    if (keyPrefixes.isEmpty) return true;
    // Önek çakışmalarını (sk- vs sk-or-v1-) en uzun eşleşme çözer.
    final detected = LlmProviders.detectByKey(trimmed);
    if (detected != null) return detected.id == id;
    return keyPrefixes.any(trimmed.startsWith);
  }
}

abstract final class LlmProviders {
  static const LlmProviderPreset openai = LlmProviderPreset(
    id: 'openai',
    label: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
    modelSuggestions: <String>['gpt-4o-mini', 'gpt-4o', 'gpt-4.1-mini'],
    keyPrefixes: <String>['sk-'],
    keyHint: 'sk- ile başlar',
    docsUrl: 'platform.openai.com/api-keys',
    note: 'Ücretli: kredi yüklemeniz gerekir.',
  );

  static const LlmProviderPreset groq = LlmProviderPreset(
    id: 'groq',
    label: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModel: 'openai/gpt-oss-120b',
    modelSuggestions: <String>[
      'openai/gpt-oss-120b',
      'openai/gpt-oss-20b',
      'qwen/qwen3.8-27b',
    ],
    keyPrefixes: <String>['gsk_'],
    keyHint: 'gsk_ ile başlar',
    docsUrl: 'console.groq.com/keys',
    note: 'Ücretsiz katman: günde 1.000 istek, kart gerekmez.',
  );

  static const LlmProviderPreset openRouter = LlmProviderPreset(
    id: 'openrouter',
    label: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'openrouter/free',
    modelSuggestions: <String>[
      'openrouter/free',
      'nvidia/nemotron-3.5-lightning:free',
      'google/gemma-4-31b-it:free',
    ],
    keyPrefixes: <String>['sk-or-v1-'],
    keyHint: 'sk-or-v1- ile başlar',
    docsUrl: 'openrouter.ai/keys',
    note: '"openrouter/free" ücretsiz modeller arasından otomatik seçer.',
  );

  static const LlmProviderPreset gemini = LlmProviderPreset(
    id: 'gemini',
    label: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
    defaultModel: 'gemini-flash-latest',
    modelSuggestions: <String>[
      'gemini-flash-latest',
      'gemini-3.8-flash',
      'gemini-3.5-flash-lite',
      'gemini-2.5-flash',
    ],
    keyPrefixes: <String>['AIza'],
    keyHint: 'AIza ile başlar (Google AI Studio anahtarı)',
    docsUrl: 'aistudio.google.com/apikey',
    note: 'Ücretsiz katman var; OpenAI anahtarı burada çalışmaz.',
  );

  static const LlmProviderPreset ollama = LlmProviderPreset(
    id: 'ollama',
    label: 'Ollama (yerel)',
    baseUrl: 'http://10.0.2.2:11434/v1',
    defaultModel: 'llama3.2',
    modelSuggestions: <String>['llama3.2', 'qwen3', 'gemma3'],
    keyPrefixes: <String>[],
    keyHint: 'gerekmez (boş bırakılabilir)',
    docsUrl: 'ollama.com',
    requiresApiKey: false,
    note: 'Bilgisayarınızda Ollama çalışmalı: OLLAMA_HOST=0.0.0.0',
  );

  static const List<LlmProviderPreset> all = <LlmProviderPreset>[
    openai,
    groq,
    openRouter,
    gemini,
    ollama,
  ];

  /// Base URL'den sağlayıcıyı tahmin eder.
  static LlmProviderPreset? matchByBaseUrl(String baseUrl) {
    final lower = baseUrl.trim().toLowerCase();
    if (lower.isEmpty) return null;
    for (final preset in all) {
      final host = Uri.tryParse(preset.baseUrl)?.host ?? '';
      if (host.isNotEmpty && lower.contains(host)) return preset;
    }
    if (lower.contains('localhost') || lower.contains('10.0.2.2')) {
      return ollama;
    }
    return null;
  }

  /// Anahtar önekine göre sağlayıcıyı tahmin eder.
  ///
  /// En uzun önek kazanır: `sk-or-v1-` > `sk-`.
  static LlmProviderPreset? detectByKey(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return null;
    LlmProviderPreset? best;
    var bestLength = 0;
    for (final preset in all) {
      for (final prefix in preset.keyPrefixes) {
        if (trimmed.startsWith(prefix) && prefix.length > bestLength) {
          best = preset;
          bestLength = prefix.length;
        }
      }
    }
    return best;
  }

  /// Base URL'yi `/chat/completions` eklenecek biçime getirir.
  ///
  /// Kullanıcı tam uç adresi yapıştırmış olabilir; ayrıca Gemini/Groq gibi
  /// sağlayıcılarda eksik yol parçaları tamamlanır.
  static String normalizeBaseUrl(String raw) {
    var base = raw.trim();
    if (base.isEmpty) return base;

    const suffix = '/chat/completions';
    if (base.toLowerCase().endsWith(suffix)) {
      base = base.substring(0, base.length - suffix.length);
    }
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    final uri = Uri.tryParse(base);
    if (uri == null || uri.host.isEmpty) return base;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (host == 'generativelanguage.googleapis.com' &&
        !path.contains('/openai')) {
      return '${uri.scheme}://${uri.host}/v1beta/openai';
    }
    if (host == 'api.groq.com' && !path.contains('/openai')) {
      return '${uri.scheme}://${uri.host}/openai/v1';
    }
    if (host == 'openrouter.ai' && !path.contains('/api/')) {
      return '${uri.scheme}://${uri.host}/api/v1';
    }
    if (host == 'api.openai.com' && path.isEmpty) {
      return '${uri.scheme}://${uri.host}/v1';
    }
    // Yolu olmayan özel sunucularda OpenAI uyumlu varsayılan `/v1`.
    if ((path.isEmpty || path == '/') &&
        !host.contains('localhost') &&
        !host.startsWith('10.') &&
        !host.startsWith('192.168.')) {
      return '$base/v1';
    }
    return base;
  }
}
