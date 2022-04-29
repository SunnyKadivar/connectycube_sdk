import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import '../../../connectycube_chat.dart';

import 'p2p_client.dart';
import '../call_session.dart';
import '../models/call_base_session.dart';
import '../models/cube_rtc_session_description.dart';
import '../peer_connection.dart';
import '../utils/signaling_messages_utils.dart';

class P2PSession extends BaseSession<P2PClient, PeerConnection>
    implements P2PCallSession {
  static const String TAG = "P2PSession";

  @override
  UserActionCallback<P2PSession> onCallAcceptedByUser;
  @override
  UserActionCallback<P2PSession> onCallRejectedByUser;
  @override
  UserActionCallback<P2PSession> onReceiveHungUpFromUser;
  @override
  UserConnectionStateCallback<P2PSession> onUserNoAnswer;
  CubeRTCSessionDescription cubeSdp;

  int get callerId => cubeSdp.callerId;

  String get sessionId => cubeSdp.sessionId;

  Set<int> get opponentsIds => cubeSdp.opponents;

  @override
  int get callType => cubeSdp.conferenceType;

  P2PSession(client, this.cubeSdp) : super(client) {
    setState(RTCSessionState.RTC_SESSION_NEW);
    _createChannelsForOpponents(cubeSdp.opponents);
  }

  void _createChannelsForOpponents(Set<int> opponentIds) {
    CubeUser currentUser = CubeChatConnection.instance.currentUser;

    opponentIds.forEach((opponentId) {
      if (opponentId != currentUser.id) {
        channels[opponentId] = PeerConnection(opponentId, this, true);
      } else {
        channels[callerId] = PeerConnection(callerId, this, true);
      }
    });
  }

  @override
  Future<void> acceptCall([Map<String, String> userInfo]) async {
    setState(RTCSessionState.RTC_SESSION_CONNECTING);
    cubeSdp.userInfo = userInfo;
    await initLocalMediaStream();

    channels.forEach((opponentId, peerConnection) {
      CubeUser currentUser = CubeChatConnection.instance.currentUser;

      if (opponentId == callerId) {
        peerConnection.startAnswer();
      } else if (opponentId < currentUser.id) {
        peerConnection.startOffer();
      } else if (peerConnection.hasRemoteSdp()) {
        peerConnection.startAnswer();
      }
    });
  }

  @override
  void hungUp([Map<String, String> userInfo]) {
    setState(RTCSessionState.RTC_SESSION_GOING_TO_CLOSE);
    channels.forEach((opponentId, peerConnection) {
      _sendHungUpMessage(opponentId, userInfo);
      peerConnection?.close();
    });

    closeCurrentSession();
  }

  @override
  void reject([Map<String, String> userInfo]) {
    setState(RTCSessionState.RTC_SESSION_GOING_TO_CLOSE);
    channels.forEach((opponentId, peerConnection) {
      _sendRejectMessage(opponentId, userInfo);
      peerConnection?.close();
    });

    closeCurrentSession();
  }

  @override
  Future<void> startCall([Map<String, String> userInfo]) async {
    log("start call $userInfo");
    setState(RTCSessionState.RTC_SESSION_CONNECTING);
    cubeSdp.userInfo = userInfo;
    await initLocalMediaStream();

    channels.forEach((opponentId, peerChannel) {
      peerChannel?.startOffer();
    });
  }

  @override
  void onSendAnswer(int userId, RTCSessionDescription sdp) {
    MessageStanza answerMessage = createAnswerMessage(cubeSdp, userId, sdp);
    client.sendSignalingMessage(answerMessage);
  }

  @override
  void onSendOffer(int userId, RTCSessionDescription sdp) {
    MessageStanza offerMessage = createOfferMessage(cubeSdp, userId, sdp);
    client.sendSignalingMessage(offerMessage);
  }

  @override
  void onSendIceCandidate(int userId, RTCIceCandidate iceCandidate) {
    log("sendIceCandidate, _sdp = $cubeSdp");
    onSendIceCandidates(userId, [iceCandidate]);
  }

  @override
  void onSendIceCandidates(int userId, List<RTCIceCandidate> iceCandidates) {
    log("sendIceCandidates, _sdp = $cubeSdp");
    MessageStanza iceCandidatesMessage = createIceCandidatesMessage(
      cubeSdp,
      userId,
      iceCandidates,
    );
    client.sendSignalingMessage(iceCandidatesMessage);
  }

  @override
  void onPeerConnectionStateChanged(int userId, PeerConnectionState state) {
    switch (state) {
      case PeerConnectionState.RTC_CONNECTION_TIMEOUT:
        _sendHungUpMessage(userId, {});

        closeConnectionForOpponent(userId, (userId) {
          if (onUserNoAnswer != null) {
            onUserNoAnswer(this, userId);
          }
        });
        break;
      default:
        super.onPeerConnectionStateChanged(userId, state);
        break;
    }
  }

  void processHungUpFromUser(
    CubeRTCSessionDescription cubeRtcSdp,
    int opponentId,
  ) {
    log(
      "processHungUpFromUser, "
      "sessionId = ${cubeRtcSdp.sessionId}, "
      "senderId = $opponentId",
      TAG,
    );

    closeConnectionForOpponent(opponentId, (opponentId) {
      if (onReceiveHungUpFromUser != null) {
        onReceiveHungUpFromUser(this, opponentId, cubeRtcSdp.userInfo);
      }
    });
  }

  void processRejectFromUser(
    CubeRTCSessionDescription cubeRtcSdp,
    int opponentId,
  ) {
    closeConnectionForOpponent(opponentId, (opponentId) {
      if (onCallRejectedByUser != null) {
        onCallRejectedByUser(this, opponentId, cubeRtcSdp.userInfo);
      }
    });
  }

  void processIceCandidates(
    List<RTCIceCandidate> candidates,
    int opponentId,
  ) {
    log("processIceCandidates, _sdp = $cubeSdp");
    PeerConnection peerConnection = channels[opponentId];
    if (peerConnection == null) return;

    peerConnection.processIceCandidates(candidates);
  }

  Future<void> processAcceptCall(
    CubeRTCSessionDescription cubeRtcSdp,
    int opponentId,
    RTCSessionDescription sdp,
  ) async {
    PeerConnection peerConnection = channels[opponentId];
    if (peerConnection == null) return;

    await peerConnection.processAnswer(sdp);
  }

  void _sendHungUpMessage(
    int opponentId,
    Map<String, String> userInfo,
  ) {
    MessageStanza hungUpMessage =
        createHungUpMessage(cubeSdp, opponentId, userInfo);
    client.sendSignalingMessage(hungUpMessage);
  }

  void _sendRejectMessage(
    int opponentId,
    Map<String, String> userInfo,
  ) {
    MessageStanza rejectMessage =
        createRejectMessage(cubeSdp, opponentId, userInfo);
    client.sendSignalingMessage(rejectMessage);
  }

  void processNewCall(
    int opponentId,
    RTCSessionDescription sdp,
  ) {
    PeerConnection peerConnection = channels[opponentId];
    if (peerConnection == null) return;

    if (!peerConnection.hasRemoteSdp()) {
      peerConnection.setRemoteSdp(sdp);
    }

    if (state == RTCSessionState.RTC_SESSION_CONNECTING ||
        state == RTCSessionState.RTC_SESSION_CONNECTED) {
      peerConnection.startAnswer();
    }
  }

  @override
  void notifySessionClosed() {
    client.removeSession(this);
    super.notifySessionClosed();
  }
}
