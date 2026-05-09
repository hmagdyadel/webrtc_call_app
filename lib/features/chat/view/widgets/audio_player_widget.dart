import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../app/theme/app_colors.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isSent;
  final String? localPath;
  final bool isUploading;
  final double? uploadProgress;

  const AudioPlayerWidget({
    super.key,
    required this.url,
    required this.isSent,
    this.localPath,
    this.isUploading = false,
    this.uploadProgress,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackRate = 1.0;
  bool _sourcePrepared = false;
  static const List<double> _speeds = [1.0, 1.25, 1.5, 2.0];
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.stop);
    _prepareSource();

    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _playerCompleteSubscription = _player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _prepareSource() async {
    if (widget.isUploading) return;
    try {
      if (widget.localPath != null && File(widget.localPath!).existsSync()) {
        await _player.setSource(DeviceFileSource(widget.localPath!));
      } else if (widget.url.isNotEmpty) {
        await _player.setSource(UrlSource(widget.url));
      } else {
        return;
      }
      _sourcePrepared = true;
      final total = await _player.getDuration();
      if (total != null && mounted) {
        setState(() => _duration = total);
      }
    } catch (_) {
      _sourcePrepared = false;
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (widget.isUploading) return;
    if (!_sourcePrepared) {
      await _prepareSource();
    }
    if (_sourcePrepared) {
      await _player.resume();
      await _player.setPlaybackRate(_playbackRate);
      return;
    }
    if (widget.localPath != null && File(widget.localPath!).existsSync()) {
      await _player.play(DeviceFileSource(widget.localPath!));
      await _player.setPlaybackRate(_playbackRate);
    } else if (widget.url.isNotEmpty) {
      await _player.play(UrlSource(widget.url));
      await _player.setPlaybackRate(_playbackRate);
    }
  }

  Future<void> _pause() async {
    await _player.pause();
  }

  Future<void> _cycleSpeed() async {
    final currentIndex = _speeds.indexOf(_playbackRate);
    final nextIndex = (currentIndex + 1) % _speeds.length;
    final nextRate = _speeds[nextIndex];
    setState(() => _playbackRate = nextRate);
    await _player.setPlaybackRate(nextRate);
  }

  Future<void> _seekToFraction(double fraction) async {
    if (_duration == Duration.zero || widget.isUploading) return;
    final clampedFraction = fraction.clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * clampedFraction).toInt(),
    );
    await _player.seek(target);
  }

  String _formatSpeed(double speed) {
    if (speed == speed.toInt()) return '${speed.toInt()}x';
    return '${speed}x';
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progressFraction {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSent ? Colors.white : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              widget.isUploading
                  ? Icons.hourglass_bottom_rounded
                  : _playerState == PlayerState.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
              color: color,
              size: 30,
            ),
            onPressed: () {
              if (widget.isUploading) return;
              if (_playerState == PlayerState.playing) {
                _pause();
              } else {
                _play();
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) {
                        if (constraints.maxWidth <= 0) return;
                        final fraction =
                            details.localPosition.dx / constraints.maxWidth;
                        _seekToFraction(fraction);
                      },
                      onHorizontalDragUpdate: (details) {
                        if (constraints.maxWidth <= 0) return;
                        final fraction =
                            details.localPosition.dx / constraints.maxWidth;
                        _seekToFraction(fraction);
                      },
                      child: SizedBox(
                        height: 34,
                        child: _WaveBars(
                          progress: widget.isUploading
                              ? (widget.uploadProgress ?? 0)
                              : _progressFraction,
                          color: color,
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isUploading
                            ? '${((widget.uploadProgress ?? 0) * 100).toInt()}%'
                            : _formatDuration(_position),
                        style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: color.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _cycleSpeed,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: color.withValues(alpha: 0.15),
                              ),
                              child: Text(
                                _formatSpeed(_playbackRate),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _WaveBars extends StatelessWidget {
  const _WaveBars({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  static const List<double> _pattern = [
    0.25, 0.5, 0.35, 0.75, 0.4, 0.85, 0.6, 0.3, 0.7, 0.45,
    0.3, 0.65, 0.55, 0.8, 0.33, 0.5, 0.72, 0.28, 0.6, 0.9,
    0.3, 0.48, 0.66, 0.4, 0.78, 0.32, 0.54, 0.84, 0.38, 0.7,
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final activeBars = (_pattern.length * normalized).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_pattern.length, (index) {
        final barHeight = 6 + (_pattern[index] * 18);
        final barColor = index <= activeBars
            ? color
            : color.withValues(alpha: 0.25);
        return Container(
          width: 3,
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
