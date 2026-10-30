import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum AudioRecordingState { idle, recording, recorded, playing, paused }

class VoiceNoteRecorderDialog extends StatefulWidget {
  final ValueChanged<bool> onVoiceNoteReady;

  const VoiceNoteRecorderDialog({
    super.key,
    required this.onVoiceNoteReady,
  });

  @override
  State<VoiceNoteRecorderDialog> createState() => _VoiceNoteRecorderDialogState();
}

class _VoiceNoteRecorderDialogState extends State<VoiceNoteRecorderDialog> {
  AudioRecordingState _state = AudioRecordingState.idle;
  int _seconds = 0;
  Timer? _timer;
  static const int maxSeconds = 30;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _state = AudioRecordingState.recording;
      _seconds = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds >= maxSeconds) {
        _stopRecording();
      } else {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _state = AudioRecordingState.recorded;
    });
    widget.onVoiceNoteReady(true);
  }

  void _playAudio() {
    setState(() {
      _state = AudioRecordingState.playing;
    });

    // Simulate playback up to recorded duration
    int playSec = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      playSec++;
      if (playSec >= _seconds) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _state = AudioRecordingState.recorded;
          });
        }
      }
    });
  }

  void _pauseAudio() {
    _timer?.cancel();
    setState(() {
      _state = AudioRecordingState.paused;
    });
  }

  void _resetRecording() {
    _timer?.cancel();
    setState(() {
      _state = AudioRecordingState.idle;
      _seconds = 0;
    });
    widget.onVoiceNoteReady(false);
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Voice Introduction (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_state == AudioRecordingState.recording)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 8, height: 8),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'REC',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Record a 30s voice intro to stand out to employers.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Timer & State Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatTime(_seconds)} / 00:30',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _state == AudioRecordingState.recording
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              if (_seconds > 0 && _state != AudioRecordingState.recording)
                TextButton.icon(
                  onPressed: _resetRecording,
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  label: const Text(
                    'Delete Recording',
                    style: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Action Controls
          if (_state == AudioRecordingState.idle)
            OutlinedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic, color: AppColors.primary),
              label: const Text('Record'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: AppColors.primary),
              ),
            )
          else if (_state == AudioRecordingState.recording)
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, color: Colors.white),
              label: Text('Stop (${maxSeconds - _seconds}s left)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(44),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _state == AudioRecordingState.playing ? _pauseAudio : _playAudio,
                    icon: Icon(
                      _state == AudioRecordingState.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    label: Text(_state == AudioRecordingState.playing ? 'Pause' : 'Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
