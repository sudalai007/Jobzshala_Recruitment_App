package com.example.jobzshala_assignment

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.media.projection.MediaProjectionManager
import android.view.View
import com.amazonaws.services.chime.sdk.meetings.audiovideo.AudioVideoObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.AttendeeInfo
import com.amazonaws.services.chime.sdk.meetings.audiovideo.contentshare.ContentShareSource
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.DefaultVideoRenderView
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoTileObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoTileState
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.capture.DefaultScreenCaptureSource
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.capture.DefaultSurfaceTextureCaptureSourceFactory
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.gl.DefaultEglCoreFactory
import com.amazonaws.services.chime.sdk.meetings.realtime.RealtimeObserver
import com.amazonaws.services.chime.sdk.meetings.session.CreateAttendeeResponse
import com.amazonaws.services.chime.sdk.meetings.session.CreateMeetingResponse
import com.amazonaws.services.chime.sdk.meetings.session.DefaultMeetingSession
import com.amazonaws.services.chime.sdk.meetings.session.MeetingSession
import com.amazonaws.services.chime.sdk.meetings.session.MeetingSessionConfiguration
import com.amazonaws.services.chime.sdk.meetings.session.MeetingSessionStatus
import com.amazonaws.services.chime.sdk.meetings.utils.logger.ConsoleLogger
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {
    private val methodChannelName = "jobzshala/chime"
    private val eventChannelName = "jobzshala/chime_events"
    private val screenCaptureRequest = 7132
    private var pendingScreenResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var session: MeetingSession? = null
    private var screenCaptureSource: DefaultScreenCaptureSource? = null
    private var micOn = true
    private var cameraOn = false
    private val renderViews = mutableMapOf<Int, DefaultVideoRenderView>()
    private val logger by lazy { ConsoleLogger() }

    private val audioVideoObserver = object : AudioVideoObserver {
        override fun onAudioSessionStartedConnecting(reconnecting: Boolean) {
            emit("sessionConnecting", mapOf("reconnecting" to reconnecting))
        }

        override fun onAudioSessionStarted(reconnecting: Boolean) {
            emit("sessionStarted", mapOf("reconnecting" to reconnecting))
        }

        override fun onAudioSessionDropped() {
            emit("connectionPoor")
        }

        override fun onAudioSessionStopped(status: MeetingSessionStatus) {
            when (status.statusCode) {
                com.amazonaws.services.chime.sdk.meetings.session.MeetingSessionStatusCode.NetworkBecamePoor,
                com.amazonaws.services.chime.sdk.meetings.session.MeetingSessionStatusCode.ConnectionHealthReconnect ->
                    emit("connectionPoor")
                else -> emit("sessionStopped", mapOf("status" to status.statusCode.toString()))
            }
        }

        override fun onAudioSessionCancelledReconnect() {
            emit("sessionStopped", mapOf("status" to "reconnectCancelled"))
        }

        override fun onConnectionRecovered() {
            emit("connectionRecovered")
        }

        override fun onConnectionBecamePoor() {
            emit("connectionPoor")
        }

        override fun onVideoSessionStartedConnecting() = Unit
        override fun onVideoSessionStarted(status: MeetingSessionStatus) = Unit
        override fun onVideoSessionStopped(status: MeetingSessionStatus) = Unit
        override fun onRemoteVideoSourceUnavailable(sources: List<com.amazonaws.services.chime.sdk.meetings.audiovideo.video.RemoteVideoSource>) = Unit
        override fun onRemoteVideoSourceAvailable(sources: List<com.amazonaws.services.chime.sdk.meetings.audiovideo.video.RemoteVideoSource>) = Unit
        override fun onCameraSendAvailabilityUpdated(available: Boolean) = Unit
    }

    private val videoTileObserver = object : VideoTileObserver {
        override fun onVideoTileAdded(state: VideoTileState) {
            emit(
                "videoTileAdded",
                mapOf(
                    "tileId" to state.tileId,
                    "attendeeId" to state.attendeeId,
                    "isLocal" to state.isLocalTile,
                    "isContent" to state.isContent,
                ),
            )
        }

        override fun onVideoTileRemoved(state: VideoTileState) {
            emit("videoTileRemoved", mapOf("tileId" to state.tileId, "attendeeId" to state.attendeeId))
        }

        override fun onVideoTilePaused(state: VideoTileState) {
            emit("videoTilePaused", mapOf("tileId" to state.tileId, "attendeeId" to state.attendeeId))
        }

        override fun onVideoTileResumed(state: VideoTileState) {
            emit("videoTileResumed", mapOf("tileId" to state.tileId, "attendeeId" to state.attendeeId))
        }

        override fun onVideoTileSizeChanged(state: VideoTileState) = Unit
    }

    private val realtimeObserver = object : RealtimeObserver {
        override fun onVolumeChanged(updates: Array<com.amazonaws.services.chime.sdk.meetings.audiovideo.VolumeUpdate>) = Unit
        override fun onSignalStrengthChanged(updates: Array<com.amazonaws.services.chime.sdk.meetings.audiovideo.SignalUpdate>) = Unit

        override fun onAttendeesJoined(attendees: Array<AttendeeInfo>) {
            attendees.forEach {
                emit("attendeeJoined", mapOf("attendeeId" to it.attendeeId, "name" to it.externalUserId))
            }
        }

        override fun onAttendeesLeft(attendees: Array<AttendeeInfo>) {
            attendees.forEach {
                emit("attendeeLeft", mapOf("attendeeId" to it.attendeeId, "name" to it.externalUserId))
            }
        }

        override fun onAttendeesDropped(attendees: Array<AttendeeInfo>) {
            attendees.forEach {
                emit("attendeeLeft", mapOf("attendeeId" to it.attendeeId, "name" to it.externalUserId))
            }
        }

        override fun onAttendeesMuted(attendees: Array<AttendeeInfo>) {
            attendees.forEach { emit("attendeeMuteState", mapOf("attendeeId" to it.attendeeId, "muted" to true)) }
        }

        override fun onAttendeesUnmuted(attendees: Array<AttendeeInfo>) {
            attendees.forEach { emit("attendeeMuteState", mapOf("attendeeId" to it.attendeeId, "muted" to false)) }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result -> handle(call, result) }
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "jobzshala/chime_video",
            ChimeVideoViewFactory(),
        )
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "join" -> join(call, result)
                "leave" -> {
                    stopSession()
                    emit("sessionStopped", mapOf("status" to "left"))
                    result.success(null)
                }
                "mute" -> {
                    requireSession().audioVideo.realtimeLocalMute()
                    micOn = false
                    emit("muteState", mapOf("muted" to true))
                    result.success(null)
                }
                "unmute" -> {
                    requireSession().audioVideo.realtimeLocalUnmute()
                    micOn = true
                    emit("muteState", mapOf("muted" to false))
                    result.success(null)
                }
                "cameraOn" -> {
                    requireSession().audioVideo.startLocalVideo()
                    cameraOn = true
                    emit("cameraState", mapOf("enabled" to true))
                    result.success(null)
                }
                "cameraOff" -> {
                    requireSession().audioVideo.stopLocalVideo()
                    cameraOn = false
                    emit("cameraState", mapOf("enabled" to false))
                    result.success(null)
                }
                "switchCamera" -> {
                    requireSession().audioVideo.switchCamera()
                    result.success(null)
                }
                "startScreenShare" -> requestScreenCapture(result)
                "stopScreenShare" -> {
                    requireSession().audioVideo.stopContentShare()
                    screenCaptureSource?.stop()
                    screenCaptureSource?.release()
                    screenCaptureSource = null
                    emit("screenShareState", mapOf("enabled" to false))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("CHIME_ERROR", error.message ?: "Chime operation failed.", null)
        }
    }

    private fun join(call: MethodCall, result: MethodChannel.Result) {
        val credentials = call.argument<Map<String, Any?>>("credentials")
        if (credentials == null) {
            result.error("BAD_ARGS", "Missing meeting credentials.", null)
            return
        }
        try {
            val gson = Gson()
            val meetingJson = gson.toJson(credentials["Meeting"])
            val attendeeJson = gson.toJson(credentials["Attendee"])
            val meeting = gson.fromJson(meetingJson, CreateMeetingResponse::class.java)
            val attendee = gson.fromJson(attendeeJson, CreateAttendeeResponse::class.java)
            val newSession = DefaultMeetingSession(
                MeetingSessionConfiguration(meeting, attendee),
                logger,
                applicationContext,
            )
            stopSession()
            session = newSession
            micOn = call.argument<Boolean>("micOn") ?: true
            cameraOn = call.argument<Boolean>("cameraOn") ?: false
            newSession.audioVideo.addAudioVideoObserver(audioVideoObserver)
            newSession.audioVideo.addVideoTileObserver(videoTileObserver)
            newSession.audioVideo.addRealtimeObserver(realtimeObserver)
            newSession.audioVideo.start()
            if (!micOn) newSession.audioVideo.realtimeLocalMute()
            if (cameraOn) newSession.audioVideo.startLocalVideo()
            newSession.audioVideo.startRemoteVideo()
            emit("joinStarted", mapOf("micOn" to micOn, "cameraOn" to cameraOn))
            result.success(null)
        } catch (error: Exception) {
            emit("joinFailed", mapOf("message" to (error.message ?: "Could not join the meeting.")))
            result.error("JOIN_FAILED", error.message ?: "Could not join the meeting.", null)
        }
    }

    private fun requestScreenCapture(result: MethodChannel.Result) {
        if (session == null) {
            result.error("NO_SESSION", "Join a meeting before sharing your screen.", null)
            return
        }
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        pendingScreenResult = result
        startActivityForResult(manager.createScreenCaptureIntent(), screenCaptureRequest)
    }

    @Deprecated("Deprecated in Android API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != screenCaptureRequest) return
        val result = pendingScreenResult
        pendingScreenResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result?.error("SCREEN_CAPTURE_DENIED", "Screen sharing permission was not granted.", null)
            return
        }
        try {
            val captureSource = DefaultScreenCaptureSource(
                applicationContext,
                logger,
                DefaultSurfaceTextureCaptureSourceFactory(logger, DefaultEglCoreFactory()),
                15,
                data,
                getSystemService(Context.DISPLAY_SERVICE) as DisplayManager,
                getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager,
            )
            val shareSource = ContentShareSource().apply { videoSource = captureSource }
            screenCaptureSource = captureSource
            requireSession().audioVideo.startContentShare(shareSource)
            emit("screenShareState", mapOf("enabled" to true))
            result?.success(null)
        } catch (error: Exception) {
            result?.error("SCREEN_SHARE_FAILED", error.message ?: "Could not start screen sharing.", null)
        }
    }

    private fun requireSession(): MeetingSession =
        session ?: throw IllegalStateException("Join a meeting before using call controls.")

    private fun stopSession() {
        screenCaptureSource?.stop()
        screenCaptureSource?.release()
        screenCaptureSource = null
        session?.let { active ->
            renderViews.keys.toList().forEach { active.audioVideo.unbindVideoView(it) }
            active.audioVideo.removeAudioVideoObserver(audioVideoObserver)
            active.audioVideo.removeVideoTileObserver(videoTileObserver)
            active.audioVideo.removeRealtimeObserver(realtimeObserver)
            active.audioVideo.stopLocalVideo()
            active.audioVideo.stopContentShare()
            active.audioVideo.stop()
        }
        session = null
        micOn = false
        cameraOn = false
        renderViews.clear()
    }

    private fun emit(type: String, data: Map<String, Any?> = emptyMap()) {
        runOnUiThread { eventSink?.success(mapOf("type" to type, "data" to data)) }
    }

    override fun onDestroy() {
        stopSession()
        super.onDestroy()
    }

    private inner class ChimeVideoViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            val tileId = (args as? Map<*, *>)?.get("tileId") as? Int ?: -1
            val renderView = DefaultVideoRenderView(context)
            if (tileId >= 0) {
                renderViews[tileId] = renderView
                session?.audioVideo?.bindVideoView(renderView, tileId)
            }
            return object : PlatformView {
                override fun getView(): View = renderView

                override fun dispose() {
                    if (tileId >= 0) {
                        session?.audioVideo?.unbindVideoView(tileId)
                        renderViews.remove(tileId)
                    }
                }
            }
        }
    }
}
