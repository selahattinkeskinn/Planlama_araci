import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/chat_thread.dart';

/// Masaüstü ve mobilde videoyu geçici bir dosyaya yazıp oynatır.
Future<VideoPlayerController> createVideoController(
  ChatAttachment attachment,
) async {
  final Directory directory = await getTemporaryDirectory();
  final String extension = attachment.extension.isEmpty
      ? 'mp4'
      : attachment.extension;
  final String fileName =
      'chat_media_${attachment.hashCode.toRadixString(16)}.$extension';
  final File file = File('${directory.path}${Platform.pathSeparator}$fileName');

  if (!await file.exists()) {
    await file.writeAsBytes(attachment.bytes, flush: true);
  }

  return VideoPlayerController.file(file);
}

Future<void> disposeVideoController(VideoPlayerController controller) {
  return controller.dispose();
}
