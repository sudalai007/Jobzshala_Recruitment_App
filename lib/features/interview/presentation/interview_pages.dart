import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/chime_credentials.dart';
import '../data/chime_credentials_service.dart';
import '../data/chime_endpoint_config.dart';
import '../platform/chime_event.dart';
import '../platform/chime_platform_bridge.dart';

class InterviewPreJoinPage extends StatefulWidget {
  const InterviewPreJoinPage({super.key});

  @override
  State<InterviewPreJoinPage> createState() => _InterviewPreJoinPageState();
}

class _InterviewPreJoinPageState extends State<InterviewPreJoinPage> {
  final _nameController = TextEditingController();
  bool _micOn = true;
  bool _cameraOn = true;
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _requestDevicePermissions() async {
    final statuses = await [Permission.microphone, Permission.camera].request();
    final denied = statuses.values
        .where((status) => !status.isGranted)
        .toList();
    if (denied.isEmpty) return true;

    if (!mounted) return false;
    final permanentlyDenied = denied.any(
      (status) => status.isPermanentlyDenied,
    );
    final retryable = denied.any(
      (status) => status.isDenied || status.isRestricted,
    );
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera and microphone access'),
        content: Text(
          permanentlyDenied
              ? 'Allow camera and microphone access in Settings to join your interview.'
              : 'Camera and microphone access are needed for the interview. You can retry the permission request or cancel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          if (retryable && !permanentlyDenied)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Try again'),
            ),
          if (permanentlyDenied)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open settings'),
            ),
        ],
      ),
    );
    if (choice != true) return false;
    if (permanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return _requestDevicePermissions();
  }

  Future<void> _join() async {
    if (_joining) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      if (!Platform.isAndroid) {
        throw UnsupportedError(
          'Interview calls are currently available on Android only.',
        );
      }
      if (!await _requestDevicePermissions()) return;
      final credentials = await ChimeCredentialsService().requestJoinInfo(
        meetingCode: ChimeEndpointConfig.meetingCode,
        name: _nameController.text,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => InterviewCallPage(
            credentials: credentials,
            name: _nameController.text.trim(),
            initialMicOn: _micOn,
            initialCameraOn: _cameraOn,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your interview')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF173F6B), Color(0xFF2875A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.video_call_rounded, color: Colors.white, size: 36),
                SizedBox(height: 18),
                Text(
                  'Get ready for your interview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Check your camera and microphone before joining the meeting.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Before you join',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jobzshala needs camera and microphone access for a video interview. '
            'You can turn either one off at any time.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          _PermissionToggle(
            icon: Icons.mic_rounded,
            title: 'Microphone',
            subtitle: _micOn ? 'You will be heard' : 'You will join muted',
            value: _micOn,
            onChanged: (value) => setState(() => _micOn = value),
          ),
          const SizedBox(height: 10),
          _PermissionToggle(
            icon: Icons.videocam_rounded,
            title: 'Camera',
            subtitle: _cameraOn
                ? 'Your video is enabled'
                : 'Your video is turned off',
            value: _cameraOn,
            onChanged: (value) => setState(() => _cameraOn = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _joining ? null : _join,
            icon: _joining
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.video_call_rounded),
            label: Text(_joining ? 'Connecting…' : 'Join interview'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your meeting details are securely requested from the configured Jobzshala endpoint.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class InterviewCallPage extends StatefulWidget {
  const InterviewCallPage({
    super.key,
    required this.credentials,
    required this.name,
    required this.initialMicOn,
    required this.initialCameraOn,
  });

  final ChimeCredentials credentials;
  final String name;
  final bool initialMicOn;
  final bool initialCameraOn;

  @override
  State<InterviewCallPage> createState() => _InterviewCallPageState();
}

class _InterviewCallPageState extends State<InterviewCallPage> {
  final _bridge = ChimePlatformBridge.instance;
  final Map<String, String> _attendees = {};
  final Map<int, Map<String, dynamic>> _tiles = {};
  StreamSubscription<ChimeEvent>? _eventSubscription;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _micOn = true;
  bool _cameraOn = false;
  bool _connecting = true;
  bool _reconnecting = false;
  bool _joiningFailed = false;
  bool _screenSharing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _micOn = widget.initialMicOn;
    _cameraOn = widget.initialCameraOn;
    _eventSubscription = _bridge.events.listen(
      _handleEvent,
      onError: (Object error) {
        if (mounted) setState(() => _error = 'Call connection error: $error');
      },
    );
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      await _bridge.join(
        widget.credentials,
        micOn: _micOn,
        cameraOn: _cameraOn,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _joiningFailed = true;
        _connecting = false;
        _error = error.message ?? 'Could not join the interview.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _joiningFailed = true;
        _connecting = false;
        _error = error.toString();
      });
    }
  }

  void _handleEvent(ChimeEvent event) {
    if (!mounted) return;
    final data = event.data;
    setState(() {
      switch (event.type) {
        case 'joinStarted':
          _joiningFailed = false;
          break;
        case 'joinFailed':
          _joiningFailed = true;
          _connecting = false;
          _error =
              data['message']?.toString() ?? 'Could not join the interview.';
          break;
        case 'sessionStarted':
          _connecting = false;
          _reconnecting = false;
          _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() => _elapsedSeconds++);
          });
          break;
        case 'sessionConnecting':
          _reconnecting = data['reconnecting'] == true;
          _connecting = !_reconnecting;
          break;
        case 'connectionPoor':
          _reconnecting = true;
          break;
        case 'connectionRecovered':
          _reconnecting = false;
          _connecting = false;
          break;
        case 'sessionStopped':
          _connecting = false;
          _reconnecting = false;
          if (data['status'] != 'left') {
            _error = 'The interview meeting has ended.';
          }
          break;
        case 'attendeeJoined':
          final id = data['attendeeId']?.toString();
          if (id != null) {
            _attendees[id] = data['name']?.toString() ?? 'Interviewer';
          }
          break;
        case 'attendeeLeft':
          final id = data['attendeeId']?.toString();
          if (id != null) {
            _attendees.remove(id);
            _tiles.removeWhere((_, tile) => tile['attendeeId'] == id);
          }
          break;
        case 'videoTileAdded':
        case 'videoTileResumed':
          final id = data['tileId'];
          if (id is int) _tiles[id] = data;
          break;
        case 'videoTilePaused':
        case 'videoTileRemoved':
          final id = data['tileId'];
          if (id is int) _tiles.remove(id);
          break;
        case 'muteState':
          _micOn = data['muted'] != true;
          break;
        case 'cameraState':
          _cameraOn = data['enabled'] == true;
          break;
        case 'screenShareState':
          _screenSharing = data['enabled'] == true;
          break;
      }
    });
  }

  Future<void> _runControl(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? 'Call control failed.');
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _leave() async {
    await _runControl(_bridge.leave);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eventSubscription?.cancel();
    unawaited(_bridge.leave());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localTile = _tiles.entries
        .where((entry) => entry.value['isLocal'] == true)
        .firstOrNull;
    final remoteAttendees = _attendees.entries.toList();
    final remoteTiles = _tiles.entries
        .where((entry) => entry.value['isLocal'] != true)
        .toList();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101923),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101923),
          foregroundColor: Colors.white,
          title: const Text('Interview room'),
          actions: [
            IconButton(
              tooltip: 'Leave interview',
              onPressed: _leave,
              icon: const Icon(
                Icons.call_end_rounded,
                color: Color(0xFFFF7777),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_reconnecting)
                const MaterialBanner(
                  backgroundColor: Color(0xFF5C421E),
                  content: Text(
                    'Reconnecting…',
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: Icon(Icons.wifi_off_rounded, color: Colors.white),
                  actions: [SizedBox.shrink()],
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 9,
                      color: _connecting
                          ? const Color(0xFFFFB547)
                          : Colors.greenAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connecting
                            ? 'Connecting to meeting…'
                            : '$_formattedTime · ${remoteAttendees.length + 1} participants',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      _formattedTime,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Material(
                    color: const Color(0xFF492B31),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (_joiningFailed)
                            TextButton(
                              onPressed: _leave,
                              child: const Text('Close'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_joiningFailed)
                const Expanded(
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white70,
                      size: 56,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: remoteAttendees.isEmpty && remoteTiles.isEmpty
                              ? _nameTile(
                                  'Waiting for interviewer',
                                  'Their video will appear here',
                                )
                              : remoteAttendees.isNotEmpty
                              ? _remoteParticipant(
                                  remoteAttendees.first,
                                  remoteTiles,
                                )
                              : _videoTile(
                                  remoteTiles.first.key,
                                  'Interviewer',
                                ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: _cameraOn && localTile != null
                                    ? _videoTile(localTile.key, 'You')
                                    : _nameTile(
                                        'You',
                                        _cameraOn
                                            ? 'Starting camera…'
                                            : 'Camera off',
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 82,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D2A37),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.groups_rounded,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${remoteAttendees.length + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Text(
                                      'people',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_joiningFailed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallButton(
                        icon: _micOn
                            ? Icons.mic_rounded
                            : Icons.mic_off_rounded,
                        label: _micOn ? 'Mute' : 'Unmute',
                        onTap: () =>
                            _runControl(() => _bridge.setMuted(_micOn)),
                      ),
                      _CallButton(
                        icon: _cameraOn
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        label: _cameraOn ? 'Camera off' : 'Camera on',
                        onTap: () => _runControl(
                          () => _bridge.setCameraEnabled(!_cameraOn),
                        ),
                      ),
                      _CallButton(
                        icon: Icons.cameraswitch_rounded,
                        label: 'Switch',
                        onTap: () => _runControl(_bridge.switchCamera),
                      ),
                      _CallButton(
                        icon: _screenSharing
                            ? Icons.stop_screen_share
                            : Icons.screen_share,
                        label: _screenSharing ? 'Stop share' : 'Share',
                        onTap: () => _runControl(
                          _screenSharing
                              ? _bridge.stopScreenShare
                              : _bridge.startScreenShare,
                        ),
                      ),
                      _CallButton(
                        icon: Icons.call_end_rounded,
                        label: 'Leave',
                        danger: true,
                        onTap: _leave,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _remoteParticipant(
    MapEntry<String, String> attendee,
    List<MapEntry<int, Map<String, dynamic>>> videoTiles,
  ) {
    final tile = videoTiles
        .where((entry) => entry.value['attendeeId'] == attendee.key)
        .firstOrNull;
    return tile == null
        ? _nameTile(attendee.value, 'Camera off')
        : _videoTile(tile.key, attendee.value);
  }

  Widget _videoTile(int tileId, String name) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF243444)),
        AndroidView(
          viewType: 'jobzshala/chime_video',
          creationParams: {'tileId': tileId},
          creationParamsCodec: const StandardMessageCodec(),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(name, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _nameTile(String name, String subtitle) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF243444),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFF3D566D),
          child: Icon(Icons.person_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white60)),
      ],
    ),
  );
}

class _PermissionToggle extends StatelessWidget {
  const _PermissionToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: SwitchListTile(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    ),
  );
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Material(
        color: danger ? const Color(0xFFB8323A) : const Color(0xFF2D4052),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
          iconSize: 24,
          padding: const EdgeInsets.all(12),
        ),
      ),
      const SizedBox(height: 7),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ],
  );
}

class InterviewEntryCard extends StatelessWidget {
  const InterviewEntryCard({super.key, this.onJoin});
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF173F6B), Color(0xFF2875A8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F173F6B),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.video_call_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your interview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Get ready for your upcoming interview',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onJoin,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF173F6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Join'),
        ),
      ],
    ),
  );
}
