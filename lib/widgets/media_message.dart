import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../media/video_controller_factory.dart';
import '../models/chat_thread.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Sohbet balonunun içinde gösterilen medya eki.
class MediaMessage extends StatelessWidget {
  const MediaMessage({
    super.key,
    required this.attachment,
    required this.accent,
  });

  final ChatAttachment attachment;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return switch (attachment.kind) {
      MediaKind.image => _ImageAttachment(attachment: attachment),
      MediaKind.video => _VideoAttachment(
        attachment: attachment,
        accent: accent,
      ),
      MediaKind.audio => _AudioAttachment(
        attachment: attachment,
        accent: accent,
      ),
    };
  }
}

double _mediaWidth(BuildContext context) {
  final double screen = MediaQuery.sizeOf(context).width;
  return (screen * 0.62).clamp(180.0, 280.0);
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.attachment});

  final ChatAttachment attachment;

  void _openViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (BuildContext dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFF05070F),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(
                      attachment.bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = _mediaWidth(context);

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          attachment.bytes,
          width: width,
          height: 185,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return _BrokenMedia(width: width, label: 'Resim açılamadı');
          },
        ),
      ),
    );
  }
}

class _VideoAttachment extends StatelessWidget {
  const _VideoAttachment({required this.attachment, required this.accent});

  final ChatAttachment attachment;
  final Color accent;

  void _openPlayer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => _VideoPlayerDialog(attachment: attachment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = _mediaWidth(context);

    return GestureDetector(
      onTap: () => _openPlayer(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: width,
                  height: 165,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF1B2440), Color(0xFF0C1326)],
                    ),
                  ),
                  child: Icon(
                    Icons.movie_creation_outlined,
                    size: 54,
                    color: accent.withValues(alpha: 0.55),
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'VİDEO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: width,
            child: Row(
              children: <Widget>[
                Icon(Icons.videocam_rounded, size: 15, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatBytes(attachment.sizeBytes),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioAttachment extends StatefulWidget {
  const _AudioAttachment({required this.attachment, required this.accent});

  final ChatAttachment attachment;
  final Color accent;

  @override
  State<_AudioAttachment> createState() => _AudioAttachmentState();
}

class _AudioAttachmentState extends State<_AudioAttachment> {
  static const List<double> _barHeights = <double>[
    8,
    14,
    20,
    11,
    24,
    16,
    9,
    18,
    22,
    13,
    7,
    17,
    21,
    12,
    25,
    15,
    10,
    19,
    23,
    14,
    8,
    16,
    20,
    12,
    9,
    18,
    22,
    13,
  ];

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  bool _playing = false;
  bool _preparing = false;
  bool _hasSource = false;
  bool _failed = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _subscriptions.add(
      _player.onPlayerStateChanged.listen((PlayerState state) {
        if (!mounted) return;
        setState(() => _playing = state == PlayerState.playing);
      }),
    );
    _subscriptions.add(
      _player.onPositionChanged.listen((Duration position) {
        if (!mounted) return;
        setState(() => _position = position);
      }),
    );
    _subscriptions.add(
      _player.onDurationChanged.listen((Duration duration) {
        if (!mounted) return;
        setState(() => _duration = duration);
      }),
    );
    _subscriptions.add(
      _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }),
    );
  }

  @override
  void dispose() {
    for (final StreamSubscription<Object?> sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_preparing) return;
    setState(() => _preparing = true);

    try {
      if (_playing) {
        await _player.pause();
      } else {
        final bool needsSource =
            !_hasSource || _player.state == PlayerState.completed;
        if (needsSource) {
          await _player.setSource(
            BytesSource(
              widget.attachment.bytes,
              mimeType: widget.attachment.resolvedMimeType,
            ),
          );
          _hasSource = true;
        }
        await _player.resume();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = _mediaWidth(context);
    final double playedBars = _progress * _barHeights.length;

    return SizedBox(
      width: width,
      child: Row(
        children: <Widget>[
          _PlayButton(
            onTap: _toggle,
            accent: widget.accent,
            loading: _preparing,
            playing: _playing,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatBytes(widget.attachment.sizeBytes),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 26,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < _barHeights.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1.2,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: _barHeights[i],
                              decoration: BoxDecoration(
                                color: i < playedBars
                                    ? widget.accent
                                    : Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Text(
                      formatDuration(_position),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _duration.inMilliseconds > 0
                          ? formatDuration(_duration)
                          : '--:--',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (_failed) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Bu ses dosyası oynatılamadı.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.onTap,
    required this.accent,
    required this.loading,
    required this.playing,
  });

  final VoidCallback onTap;
  final Color accent;
  final bool loading;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: loading
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            : Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: accent,
                size: 24,
              ),
      ),
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  const _VideoPlayerDialog({required this.attachment});

  final ChatAttachment attachment;

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    VideoPlayerController? controller;
    try {
      controller = await createVideoController(widget.attachment);
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        await disposeVideoController(controller);
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (controller != null) {
        await disposeVideoController(controller);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    final VideoPlayerController? controller = _controller;
    if (controller != null) {
      disposeVideoController(controller);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;

    return Dialog(
      backgroundColor: const Color(0xFF0B1120),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.movie_rounded,
                  size: 18,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_failed)
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.videocam_off_rounded,
                        size: 36,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bu videoyu bu platformda oynatamıyoruz.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            if (controller != null && !_loading && !_failed)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio <= 0
                      ? 16 / 9
                      : controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      VideoPlayer(controller),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        },
                        child: AnimatedOpacity(
                          opacity: controller.value.isPlaying ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.25),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.play_circle_fill_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (controller != null && !_loading && !_failed) ...<Widget>[
              const SizedBox(height: 12),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final Duration position = value.position;
                  final Duration duration = value.duration;
                  final double progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0;

                  return Column(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: () {
                              if (value.isPlaying) {
                                controller.pause();
                              } else {
                                controller.play();
                              }
                            },
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            color: AppColors.textPrimary,
                          ),
                          Text(
                            '${formatDuration(position)} / '
                            '${formatDuration(duration)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatBytes(widget.attachment.sizeBytes),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrokenMedia extends StatelessWidget {
  const _BrokenMedia({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 150,
      color: Colors.white.withValues(alpha: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
