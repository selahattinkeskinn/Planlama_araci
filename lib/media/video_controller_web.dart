import 'dart:js_interop';

import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import '../models/chat_thread.dart';

final Expando<String> _blobUrls = Expando<String>('blobUrl');

/// Web'de videoyu bellekten bir blob adresiyle oynatır.
Future<VideoPlayerController> createVideoController(
  ChatAttachment attachment,
) async {
  final web.Blob blob = web.Blob(
    <JSAny>[attachment.bytes.toJS].toJS,
    web.BlobPropertyBag(type: attachment.resolvedMimeType),
  );
  final String url = web.URL.createObjectURL(blob);
  final VideoPlayerController controller = VideoPlayerController.networkUrl(
    Uri.parse(url),
  );
  _blobUrls[controller] = url;
  return controller;
}

Future<void> disposeVideoController(VideoPlayerController controller) async {
  final String? url = _blobUrls[controller];
  await controller.dispose();
  if (url != null) {
    web.URL.revokeObjectURL(url);
  }
}
