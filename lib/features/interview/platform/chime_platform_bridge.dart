import 'package:flutter/services.dart';
import '../data/chime_credentials.dart';
import 'chime_event.dart';

/// Dart-facing contract for the native Kotlin Chime bridge.
class ChimePlatformBridge {
  ChimePlatformBridge._();
  static final ChimePlatformBridge instance = ChimePlatformBridge._();
  static const MethodChannel _methods = MethodChannel('jobzshala/chime');
  static const EventChannel _eventChannel = EventChannel(
    'jobzshala/chime_events',
  );

  Stream<ChimeEvent> get events =>
      _eventChannel.receiveBroadcastStream().map(ChimeEvent.fromDynamic);

  Future<void> join(
    ChimeCredentials credentials, {
    required bool micOn,
    required bool cameraOn,
  }) async {
    await _methods.invokeMethod<void>('join', {
      'credentials': credentials.toJson(),
      'micOn': micOn,
      'cameraOn': cameraOn,
    });
  }

  Future<void> leave() => _methods.invokeMethod<void>('leave');
  Future<void> setMuted(bool muted) =>
      _methods.invokeMethod<void>(muted ? 'mute' : 'unmute');
  Future<void> setCameraEnabled(bool enabled) =>
      _methods.invokeMethod<void>(enabled ? 'cameraOn' : 'cameraOff');
  Future<void> switchCamera() => _methods.invokeMethod<void>('switchCamera');
  Future<void> startScreenShare() =>
      _methods.invokeMethod<void>('startScreenShare');
  Future<void> stopScreenShare() =>
      _methods.invokeMethod<void>('stopScreenShare');
}
