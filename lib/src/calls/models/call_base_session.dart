import 'package:flutter/widgets.dart';

import '../../../connectycube_calls.dart';
import '../../../connectycube_chat.dart';
import '../peer_connection.dart';

abstract class BaseSession<C, P extends PeerConnection>
    implements BaseCallSession, CubePeerConnectionStateCallback {
  static const String _TAG = "BaseSession";
  @override
  LocalStreamCallback onLocalStreamReceived;
  @override
  RemoteStreamCallback<BaseSession> onRemoteStreamReceived;
  @override
  RemoteStreamCallback<BaseSession> onRemoteStreamRemoved;
  @override
  SessionClosedCallback<BaseSession> onSessionClosed;
  @protected
  C client;
  @protected
  MediaStream localStream;
  @protected
  Map<int, P> channels = {};

  RTCSessionState state;

  RTCSessionStateCallback _connectionCallback;

  BaseSession(this.client);

  setSessionCallbacksListener(RTCSessionStateCallback callback) {
    if (callback != null) {
      _connectionCallback = callback;
    }
  }

  removeSessionCallbacksListener() {
    _connectionCallback = null;
  }

  @protected
  void setState(RTCSessionState state) {
    if (this.state != state) {
      this.state = state;
    }
  }

  Future<MediaStream> initLocalMediaStream() async {
    return _createStream(false).then((mediaStream) {
      localStream = mediaStream;
      return Future.value(localStream);
    });
  }

  Future<MediaStream> _createStream(bool isScreenSharing) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
    };

    if (CallType.VIDEO_CALL == callType) {
      RTCMediaConfig mediaConfig = RTCMediaConfig.instance;
      mediaConstraints['video'] = {
        'mandatory': {
          'minWidth': mediaConfig.minWidth,
          'minHeight': mediaConfig.minHeight,
          'minFrameRate': mediaConfig.minFrameRate,
        },
        'facingMode': 'user',
        'optional': [],
      };
    }

    MediaStream stream = isScreenSharing
        ? await navigator.mediaDevices.getDisplayMedia(mediaConstraints)
        : await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (this.onLocalStreamReceived != null) {
      this.onLocalStreamReceived(stream);
    }

    return Future.value(stream);
  }

  @override
  Future<MediaStream> getLocalMediaStream() {
    if (localStream != null) return Future.value(localStream);

    return initLocalMediaStream();
  }

  @override
  void onRemoteStreamReceive(int userId, MediaStream remoteMediaStream) {
    if (onRemoteStreamReceived != null) {
      onRemoteStreamReceived(this, userId, remoteMediaStream);
    }
  }

  @override
  void onRemoteStreamRemove(int userId, MediaStream remoteMediaStream) {
    if (onRemoteStreamRemoved != null) {
      onRemoteStreamRemoved(this, userId, remoteMediaStream);
    }
  }

  @override
  void onIceGatheringStateChanged(int userId, RTCIceGatheringState state) {
    log("onIceGatheringStateChanged state= $state for userId= $userId", _TAG);
  }

  @override
  Future<bool> switchCamera() {
    if (CallType.VIDEO_CALL != callType)
      return Future.error(
          IllegalStateException("Can't perform operation for AUDIO call"));

    try {
      return localStream?.getVideoTracks()[0]?.switchCamera();
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  void setVideoEnabled(bool enabled) {
    if (CallType.VIDEO_CALL != callType) return;

    localStream?.getVideoTracks()[0].enabled = enabled;
  }

  @override
  void setMicrophoneMute(bool mute) {
    localStream?.getAudioTracks()[0].setMicrophoneMute(mute);
  }

  @override
  void enableSpeakerphone(bool enable) {
    localStream?.getAudioTracks()[0].enableSpeakerphone(enable);
  }

  @override
  void onPeerConnectionStateChanged(int userId, PeerConnectionState state) {
    switch (state) {
      case PeerConnectionState.RTC_CONNECTION_CONNECTED:
        setState(RTCSessionState.RTC_SESSION_CONNECTED);
        if (_connectionCallback != null)
          _connectionCallback.onConnectedToUser(this, userId);
        break;
      case PeerConnectionState.RTC_CONNECTION_DISCONNECTED:
        if (_connectionCallback != null)
          _connectionCallback.onDisconnectedFromUser(this, userId);
        break;
      case PeerConnectionState.RTC_CONNECTION_CLOSED:
        if (_connectionCallback != null)
          _connectionCallback.onConnectionClosedForUser(this, userId);
        break;
      case PeerConnectionState.RTC_CONNECTION_FAILED:
        closeConnectionForOpponent(userId, (userId) {});
        break;
      default:
        break;
    }
  }

  void closeConnectionForOpponent(
    int opponentId,
    Function(int opponentId) callback,
  ) {
    PeerConnection peerConnection = channels[opponentId];
    if (peerConnection == null) return;

    peerConnection.close();
    channels.remove(opponentId);

    if (callback != null) {
      callback(opponentId);
    }

    log(
      "closeConnectionForOpponent, "
      "_channels.length = ${channels.length}",
      _TAG,
    );

    if (channels.length == 0) {
      closeCurrentSession();
    } else {
      log(
        "closeConnectionForOpponent, "
        "left channels = ${channels.keys.join(", ")}",
        _TAG,
      );
    }
  }

  void closeCurrentSession() {
    log("closeCurrentSession", _TAG);
    setState(RTCSessionState.RTC_SESSION_CLOSED);
    if (localStream != null) {
      localStream.dispose();
      localStream = null;
    }

    notifySessionClosed();
  }

  void notifySessionClosed() {
    log("_notifySessionClosed", _TAG);
    if (onSessionClosed != null) {
      onSessionClosed(this);
    }
  }
}
