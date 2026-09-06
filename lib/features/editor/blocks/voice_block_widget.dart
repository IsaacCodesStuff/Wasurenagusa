import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/services/media_service.dart';
import '../../../theme/wasurenagusa_theme.dart';

const _uuid = Uuid();

class VoiceBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final VoidCallback onDelete;
  final Future<void> Function(VoiceData) onSave;

  const VoiceBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<VoiceBlockWidget> createState() => _VoiceBlockWidgetState();
}

class _VoiceBlockWidgetState extends State<VoiceBlockWidget> {
  late AudioPlayer _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _subs.add(_player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    }));
    _subs.add(_player.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    }));
    _subs.add(_player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _playing = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      }
    }));
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final voiceData = widget.block.voiceData;
    if (voiceData == null) return;
    try {
      final path = await MediaService.instance.resolve(voiceData.filename);
      await _player.setFilePath(path);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayback() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _openDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VoiceRecordDialog(
        colors: widget.colors,
        existingVoiceData: widget.block.voiceData,
        onConfirm: (voiceData) async {
          await widget.onSave(voiceData);
          // Reinitialize player with new file
          final path =
              await MediaService.instance.resolve(voiceData.filename);
          await _player.setFilePath(path);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final voiceData = widget.block.voiceData;

    // Empty state — no recording yet, show prompt
    if (voiceData == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: _openDialog,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.mic_rounded, color: colors.accent, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Tap to record',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Recorded state — compact playback card
    final totalDuration = voiceData.durationMs != null
        ? Duration(milliseconds: voiceData.durationMs!)
        : _duration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            // Play/pause button
            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Label + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice recording',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _playing
                        ? '${_formatDuration(_position)} / ${_formatDuration(totalDuration)}'
                        : _formatDuration(totalDuration),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Open dialog button
            IconButton(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.onSurfaceVariant,
              ),
              onPressed: _openDialog,
              tooltip: 'Voice options',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Recording dialog
// ─────────────────────────────────────────────

enum _DialogState { idle, recording, recorded }

class _VoiceRecordDialog extends StatefulWidget {
  final WasurenagusaColorScheme colors;
  final VoiceData? existingVoiceData;
  final Future<void> Function(VoiceData) onConfirm;

  const _VoiceRecordDialog({
    required this.colors,
    required this.existingVoiceData,
    required this.onConfirm,
  });

  @override
  State<_VoiceRecordDialog> createState() => _VoiceRecordDialogState();
}

class _VoiceRecordDialogState extends State<_VoiceRecordDialog> {
  late _DialogState _state;

  // Recording
  AudioRecorder? _recorder;
  String? _tempPath;
  Timer? _recordTimer;
  int _elapsedSeconds = 0;

  // Playback
  AudioPlayer? _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<StreamSubscription> _subs = [];

  // Resolved path for existing recording
  String? _existingPath;

  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingVoiceData != null) {
      _state = _DialogState.recorded;
      _loadExisting();
    } else {
      _state = _DialogState.idle;
    }
  }

  Future<void> _loadExisting() async {
    final path = await MediaService.instance
        .resolve(widget.existingVoiceData!.filename);
    _existingPath = path;
    await _initPlayer(path);
  }

  Future<void> _initPlayer(String path) async {
    _player = AudioPlayer();
    _subs.add(_player!.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    }));
    _subs.add(_player!.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    }));
    _subs.add(_player!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _playing = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _player!.seek(Duration.zero);
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      }
    }));
    try {
      await _player!.setFilePath(path);
      if (mounted) setState(() => _duration = _player!.duration ?? Duration.zero);
    } catch (_) {}
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    _recorder = AudioRecorder();
    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied.')),
        );
      }
      _recorder!.dispose();
      _recorder = null;
      return;
    }

    final tempDir = await getTemporaryDirectory();
    _tempPath = p.join(tempDir.path, '${_uuid.v4()}.m4a');

    await _recorder!.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _tempPath!,
    );

    _elapsedSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    setState(() => _state = _DialogState.recording);
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    await _recorder?.stop();
    _recorder?.dispose();
    _recorder = null;

    if (_tempPath != null) {
      await _initPlayer(_tempPath!);
    }

    setState(() => _state = _DialogState.recorded);
  }

  Future<void> _togglePlayback() async {
    if (_player == null) return;
    if (_playing) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  Future<void> _share() async {
    final path = _tempPath ?? _existingPath;
    if (path == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Voice recording'),
    );
  }

  Future<void> _discard() async {
    await _player?.stop();
    _player?.dispose();
    _player = null;

    // Only delete temp files — never delete the permanent file on discard
    if (_tempPath != null) {
      final f = File(_tempPath!);
      if (await f.exists()) await f.delete();
      _tempPath = null;
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);

    try {
      await _player?.stop();

      final durationMs = _duration.inMilliseconds > 0
          ? _duration.inMilliseconds
          : _elapsedSeconds * 1000;

      if (_tempPath != null) {
        // New recording — copy temp into permanent media storage
        final filename = '${_uuid.v4()}.m4a';
        await MediaService.instance.copyInto(File(_tempPath!), filename);

        // Clean up temp file
        final f = File(_tempPath!);
        if (await f.exists()) await f.delete();
        _tempPath = null;

        final voiceData = VoiceData(filename: filename, durationMs: durationMs);
        await widget.onConfirm(voiceData);
      } else if (widget.existingVoiceData != null) {
        // Existing recording — just close, nothing changed
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title row ──────────────────────────
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
                  onPressed: _discard,
                  tooltip: 'Discard',
                ),
                Expanded(
                  child: Text(
                    'Record audio',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: _confirming
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.accent,
                          ),
                        )
                      : Icon(
                          Icons.check_rounded,
                          color: _state == _DialogState.recorded
                              ? colors.accent
                              : colors.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                  onPressed: _state == _DialogState.recorded && !_confirming
                      ? _confirm
                      : null,
                  tooltip: 'Confirm',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Main content area ───────────────────
            if (_state == _DialogState.idle) ...[
              _MicButton(
                colors: colors,
                onTap: _startRecording,
                isRecording: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to record',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ] else if (_state == _DialogState.recording) ...[
              _MicButton(
                colors: colors,
                onTap: _stopRecording,
                isRecording: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RecordingDot(color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    _elapsedLabel,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Recorded / playback state
              const SizedBox(height: 8),
              // Seek slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colors.accent,
                  inactiveTrackColor: colors.divider,
                  thumbColor: colors.accent,
                  overlayColor: colors.accent.withValues(alpha: 0.12),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0
                      ? (_position.inMilliseconds /
                              _duration.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: (v) {
                    if (_duration.inMilliseconds > 0) {
                      _player?.seek(
                        Duration(
                          milliseconds:
                              (v * _duration.inMilliseconds).round(),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Duration label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DialogIconButton(
                    icon: _playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: colors.accent,
                    onTap: _togglePlayback,
                  ),
                  const SizedBox(width: 16),
                  _DialogIconButton(
                    icon: Icons.share_rounded,
                    color: colors.accent,
                    onTap: _share,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;
  final bool isRecording;

  const _MicButton({
    required this.colors,
    required this.onTap,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isRecording
              ? colors.accent
              : colors.accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: isRecording ? Colors.white : colors.accent,
          size: 36,
        ),
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  final Color color;
  const _RecordingDot({required this.color});

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _DialogIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DialogIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}