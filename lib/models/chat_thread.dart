import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bir mesaja eklenebilen medya türü.
enum MediaKind { image, video, audio }

/// Sohbette gönderilen resim, video veya ses eki.
class ChatAttachment {
  ChatAttachment({
    required this.kind,
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final MediaKind kind;
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  int get sizeBytes => bytes.length;

  String get extension {
    final int dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  String get resolvedMimeType => mimeType ?? mimeTypeForExtension(extension);
}

class ChatMessage {
  const ChatMessage({required this.fromAgent, this.text = '', this.attachment});

  final bool fromAgent;
  final String text;
  final ChatAttachment? attachment;
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.accent,
    required this.messages,
  });

  final int id;
  final String title;
  final String summary;
  final IconData icon;
  final Color accent;
  final List<ChatMessage> messages;
}

const Map<String, String> _mimeTypes = <String, String>{
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'bmp': 'image/bmp',
  'mp4': 'video/mp4',
  'm4v': 'video/x-m4v',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
  'mkv': 'video/x-matroska',
  'avi': 'video/x-msvideo',
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'm4a': 'audio/mp4',
  'aac': 'audio/aac',
  'flac': 'audio/flac',
};

String mimeTypeForExtension(String extension) {
  return _mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
}

/// Medya türüne göre dosya seçicide kullanılacak uzantılar.
List<String> extensionsFor(MediaKind kind) {
  return switch (kind) {
    MediaKind.image => <String>['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    MediaKind.video => <String>['mp4', 'm4v', 'mov', 'webm', 'mkv', 'avi'],
    MediaKind.audio => <String>['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'],
  };
}

const List<ChatThread> planningChats = <ChatThread>[
  ChatThread(
    id: 1,
    title: 'Sohbet 1',
    summary: 'Günlük plan ve öncelikler',
    icon: Icons.wb_sunny_rounded,
    accent: AppColors.cyan,
    messages: <ChatMessage>[
      ChatMessage(
        fromAgent: true,
        text:
            'Günaydın! Bugün için üç öncelik belirledim: sprint toplantısı, '
            'tasarım incelemesi ve rapor teslimi.',
      ),
      ChatMessage(
        fromAgent: false,
        text: 'Toplantıyı öğleden sonraya alabilir misin?',
      ),
      ChatMessage(
        fromAgent: true,
        text:
            'Elbette. Sprint toplantısını 14:30’a taşıdım ve öncesine 30 '
            'dakikalık odaklanma bloğu ekledim.',
      ),
    ],
  ),
  ChatThread(
    id: 2,
    title: 'Sohbet 2',
    summary: 'Proje takvimi ve kilometre taşları',
    icon: Icons.calendar_month_rounded,
    accent: AppColors.primary,
    messages: <ChatMessage>[
      ChatMessage(
        fromAgent: true,
        text:
            'Sprint planını hazırladım. Bu hafta üç kilometre taşı var; ilki '
            'çarşamba günü kapanıyor.',
      ),
      ChatMessage(fromAgent: false, text: 'Riskli bir iş var mı?'),
      ChatMessage(
        fromAgent: true,
        text:
            'API entegrasyonu iki gün gecikebilir. Bunu cuma gününe taşıyıp '
            'tasarım incelemesini öne alabiliriz.',
      ),
    ],
  ),
  ChatThread(
    id: 3,
    title: 'Sohbet 3',
    summary: 'Fikirler ve notlar',
    icon: Icons.lightbulb_rounded,
    accent: AppColors.amber,
    messages: <ChatMessage>[
      ChatMessage(
        fromAgent: true,
        text:
            'Notlarından üç yeni fikir çıkardım: haftalık özet, hızlı görev '
            'ekleme ve odak modu.',
      ),
      ChatMessage(
        fromAgent: false,
        text: 'Odak modu bana en mantıklısı gibi geliyor.',
      ),
      ChatMessage(
        fromAgent: true,
        text:
            'Harika seçim. Bildirimleri sessize alan ve zamanlayıcı başlatan '
            'bir akış tasarlayabilirim.',
      ),
    ],
  ),
  ChatThread(
    id: 4,
    title: 'Sohbet 4',
    summary: 'Async ve sync farkları',
    icon: Icons.sync_rounded,
    accent: AppColors.cyan,
    messages: <ChatMessage>[
      ChatMessage(
        fromAgent: true,
        text:
            'Senkron (sync) kod sırayla çalışır: bir işlem bitmeden sonraki '
            'başlamaz. Asenkron (async) kod ise uzun süren işleri (ağ, dosya, '
            'zamanlayıcı) beklerken arayüzü kilitlemeden devam eder.',
      ),
      ChatMessage(fromAgent: false, text: 'Farkları kısaca özetler misin?'),
      ChatMessage(
        fromAgent: true,
        text:
            '1) Sync: Future yok; sonuç anında döner. Async: Future/Stream '
            'döner, sonuç sonra gelir.\n'
            '2) Sync: UI thread bloklar. Async: await ile akisi duraklatir '
            'ama thread serbest birakir.\n'
            '3) Sync: hata anında fırlar. Async: try/catch ile await sonrası '
            'yakalanır.\n'
            '4) Sync: sıralı ve basit. Async: paralel iş, zaman aşımları ve '
            'iptal (cancel) yönetimi gerekir.',
      ),
      ChatMessage(fromAgent: false, text: 'Dartta async nasil isaretlenir?'),
      ChatMessage(
        fromAgent: true,
        text:
            'Fonksiyon imzasına async eklenir ve içerde await kullanılır:\n'
            'Future<String> veriGetir() async {\n'
            '  final yanit = await http.get(url);\n'
            '  return yanit.body;\n'
            '}\n'
            'Sync karşılığı String veriGetir() { return ...; } şeklinde olur '
            've çağrı anında tamamlanır.',
      ),
    ],
  ),
];
