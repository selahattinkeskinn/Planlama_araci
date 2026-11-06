import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/chat_thread.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'pressable_scale.dart';

/// Alt kısımdaki mesaj yazma alanı: metin, resim, video ve ses gönderimi.
class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key, required this.accent, required this.onSend});

  final Color accent;
  final void Function(String text, ChatAttachment? attachment) onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  static const int _maxBytes = 40 * 1024 * 1024;

  final TextEditingController _controller = TextEditingController();
  ChatAttachment? _pending;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _canSend => _pending != null || _controller.text.trim().isNotEmpty;

  void _send() {
    if (!_canSend) return;
    final String text = _controller.text.trim();
    final ChatAttachment? attachment = _pending;
    _controller.clear();
    setState(() => _pending = null);
    widget.onSend(text, attachment);
  }

  Future<void> _openAttachSheet() async {
    if (_picking) return;
    final MediaKind? kind = await showModalBottomSheet<MediaKind>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => _AttachSheet(accent: widget.accent),
    );
    if (kind != null) {
      await _pick(kind);
    }
  }

  Future<void> _pick(MediaKind kind) async {
    setState(() => _picking = true);
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        dialogTitle: switch (kind) {
          MediaKind.image => 'Bir resim seç',
          MediaKind.video => 'Bir video seç',
          MediaKind.audio => 'Bir ses dosyası seç',
        },
        type: FileType.custom,
        allowedExtensions: extensionsFor(kind),
      );

      if (file == null) return;

      final int? length = file.lengthSync() ?? await file.length();
      if (length != null && length > _maxBytes) {
        _showError('Dosya çok büyük. En fazla 40 MB ekleyebilirsin.');
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pending = ChatAttachment(
          kind: kind,
          name: file.name,
          bytes: bytes,
          mimeType: mimeTypeForExtension(file.extension ?? ''),
        );
      });
    } catch (_) {
      _showError('Dosya seçilemedi. Lütfen tekrar dene.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF090F1E).withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _pending == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AttachmentPreview(
                      attachment: _pending!,
                      accent: widget.accent,
                      onRemove: () => setState(() => _pending = null),
                    ),
                  ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              PressableScale(
                scale: 0.9,
                onTap: _openAttachSheet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        widget.accent.withValues(alpha: 0.28),
                        widget.accent.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: _picking
                      ? Padding(
                          padding: const EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.accent,
                          ),
                        )
                      : AnimatedRotation(
                          turns: _pending == null ? 0 : 0.125,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            Icons.add_rounded,
                            color: widget.accent,
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('composer-field'),
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Mesaj yaz veya medya ekle…',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: widget.accent.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PressableScale(
                key: const ValueKey<String>('send-button'),
                scale: 0.9,
                onTap: _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: _canSend
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              widget.accent,
                              widget.accent.withValues(alpha: 0.66),
                            ],
                          )
                        : null,
                    color: _canSend
                        ? null
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canSend
                        ? <BoxShadow>[
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 21,
                    color: _canSend
                        ? (widget.accent.computeLuminance() > 0.4
                              ? const Color(0xFF0B1020)
                              : Colors.white)
                        : AppColors.textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.attachment,
    required this.accent,
    required this.onRemove,
  });

  final ChatAttachment attachment;
  final Color accent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: attachment.kind == MediaKind.image
                  ? Image.memory(
                      attachment.bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) =>
                          _kindIcon(attachment.kind, accent),
                    )
                  : _kindIcon(attachment.kind, accent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_kindLabel(attachment.kind)} · '
                  '${formatBytes(attachment.sizeBytes)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.textMuted,
            tooltip: 'Eki kaldır',
          ),
        ],
      ),
    );
  }
}

Widget _kindIcon(MediaKind kind, Color accent) {
  return ColoredBox(
    color: accent.withValues(alpha: 0.14),
    child: Icon(
      switch (kind) {
        MediaKind.image => Icons.image_rounded,
        MediaKind.video => Icons.movie_rounded,
        MediaKind.audio => Icons.graphic_eq_rounded,
      },
      color: accent,
      size: 22,
    ),
  );
}

String _kindLabel(MediaKind kind) {
  return switch (kind) {
    MediaKind.image => 'Resim',
    MediaKind.video => 'Video',
    MediaKind.audio => 'Ses',
  };
}

class _AttachSheet extends StatelessWidget {
  const _AttachSheet({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1424),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Medya ekle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Mesajına bir dosya iliştir.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _AttachTile(
                      icon: Icons.image_rounded,
                      color: AppColors.cyan,
                      title: 'Resim',
                      hint: 'JPG · PNG',
                      onTap: () => Navigator.of(context).pop(MediaKind.image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachTile(
                      icon: Icons.movie_rounded,
                      color: AppColors.primary,
                      title: 'Video',
                      hint: 'MP4 · WEBM',
                      onTap: () => Navigator.of(context).pop(MediaKind.video),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachTile(
                      icon: Icons.graphic_eq_rounded,
                      color: AppColors.amber,
                      title: 'Ses',
                      hint: 'MP3 · WAV',
                      onTap: () => Navigator.of(context).pop(MediaKind.audio),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
