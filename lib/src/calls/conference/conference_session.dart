
import 'dart:async';

import '../../../connectycube_chat.dart';
import 'conference_client.dart';
import '../signaling/janus_signaler.dart';
import '../models/call_base_session.dart';
import '../conference/conference_config.dart';
import '../conference/ws_exeptions.dart';
import '../models/cube_rtc_session_description.dart';

import '../../../connectycube_calls.dart';
import '../peer_connection.dart';
import 'conference_peer_connection.dart';

class ConferenceSession extends BaseSession<ConferenceClient, ConferencePeerConnection> implements JanusResponseEventCallback, ConferenceCallSession {
  static const String _TAG = "ConferenceSession";
  static const String JOIN_JANUS_ROLE = "publisher";
  JanusSignaler _signaler;
  CubeConferenceSessionDescription sessionDescription;
  int joinSenderId;
  Set<int> allActivePublishers = Set();
  Set<int> joinEventPublishers = Set();
  Set<int> allActiveSubscribers = Set();
  Function _joinCallback;
  @override
  var onError;

  @override
  var onPublisherLeft;

  @override
  var onPublishersReceived;

  @override
  var onSlowLink;

  ConferenceSession(client, this._signaler, int conferenceType): super(client)  {
    sessionDescription = CubeConferenceSessionDescription(conferenceType);
    _signaler.setJanusResponseEventCallback(this);
  }

  int get currentUserId => client.currentUserId;

  Future<void> joinDialog(String dialogId, callback(List<int> publishers), {ConferenceRole conferenceRole = ConferenceRole.PUBLISHER}) {
    _joinCallback = callback;
    sessionDescription.conferenceRole = conferenceRole;
    return _signaler.joinDialog(dialogId, client.currentUserId, JOIN_JANUS_ROLE);
  }

  Future<void> subscribeToPublisher(int publisherId) async {
    logTime("subscribeToPublisher =$publisherId", _TAG);
    Completer<void> result = Completer();
    try {
      await _signaler.attachPlugin(
          ConferenceConfig.instance.plugin, publisherId);
      await _signaler.subscribe(_signaler.dialogId, publisherId);
      result.complete();
    } on WsException catch(ex) {
      logTime("subscribeToPublisher error: =$ex", _TAG);
      notifySessionError(ex);
    }
    return result.future;
  }

  void unsubscribeFromPublisher(int publisherId) {
    cleanUpPeerConnection(publisherId);
    detachHandleId(publisherId);
  }

  void leave() {
    if (state != RTCSessionState.RTC_SESSION_GOING_TO_CLOSE && state != RTCSessionState.RTC_SESSION_CLOSED) {
      setState(RTCSessionState.RTC_SESSION_GOING_TO_CLOSE);
    _signaler.stopAutoSendPresence();
    _leaveSession();
      disposeSession();
    } else {
      logTime("Trying to leave from room, while session has been already closed", _TAG);
    }
  }

  void _leaveSession() async {
    logTime("signaler leave", _TAG);
    await _signaler.leave(client.currentUserId);
    logTime("signaler detachHandleIdAll", _TAG);
    _signaler.detachHandleIdAll();
    logTime("signaler destroySession", _TAG);
    _signaler.destroySession();
  }

  void disposeSession() {
    channels.keys.toList().forEach((opponentId) {
      logTime("disposeSession opponentId $opponentId", _TAG);
      closeConnectionForOpponent(opponentId, ((opponentId) {
        logTime("closeConnectionForOpponent opponentId $opponentId success", _TAG);
      }));
    });
  }

  void notifySessionError(WsException exception) {
    if(onError != null) onError(exception);
  }

  @override
  void onEventError(String error, int code) {
    notifySessionError(WsException(error));
  }

  @override
  void onGetOnlineParticipants(Map<int, bool> participants) {
    // TODO: implement onGetOnlineParticipants
  }

  @override
  void onHangUp(String reason) {
    notifySessionError(WsHangUpException(reason));
  }

  @override
  void onJoinEvent(List<int> publishersList, List<int> subscribersList, int senderId) {
    logTime("onJoinEvent");
    joinSenderId = senderId;
    joinEventPublishers.addAll(publishersList);
    allActivePublishers.addAll(publishersList);
    allActiveSubscribers.addAll(subscribersList);
    selectJoinStrategy();
    notifyJoinedSuccessListeners(publishersList);
  }

  @override
  void onJoiningEvent(int participantId, ConferenceRole conferenceRole) {
    logTime("onJoiningEvent participantId= $participantId", _TAG);
    if (ConferenceRole.LISTENER == conferenceRole) {
      allActiveSubscribers.add(participantId);
    }
  }

  @override
  void onLeaveCurrentUserEvent(bool success) {
    logTime("onLeaveCurrentUserEvent success= $success", _TAG);
  }

  @override
  void onLeaveParticipantEvent(int participantId) {
    logTime("onLeaveParticipantEvent participantId= $participantId", _TAG);
    if (allActivePublishers.contains(participantId)) {
      allActivePublishers.remove(participantId);
      detachHandleId(participantId);
      cleanUpPeerConnection(participantId);
      if (onPublisherLeft != null) onPublisherLeft(participantId);
      logTime("onLeaveParticipantEvent publisherId= $participantId cleaning all stuff", _TAG);
    } else if (allActiveSubscribers.contains(participantId)) {
      allActiveSubscribers.remove(participantId);
      logTime("onLeaveParticipantEvent subscriberId= $participantId");
    } else {
      logTime("onLeaveParticipantEvent publisherId= $participantId already left", _TAG);
    }
  }

  @override
  void onMediaReceived(String type, bool success) {
    logTime("onMediaReceived", _TAG);
  }

  @override
  void onPacketError(String error) {
    logTime("onPacketError error= $error", _TAG);
  }

  @override
  void onPublishedEvent(List<int> publishersList) {
    logTime("onPublishedEvent publishersList= $publishersList", _TAG);
    allActivePublishers.addAll(publishersList);
    if(onPublishersReceived != null) onPublishersReceived(publishersList);
  }

  @override
  void onRemoteSDPEventAnswer(String sdp) {
    logTime("onRemoteSDPEventAnswer", _TAG);
    ConferencePeerConnection channel = channels[currentUserId];
    if (channel != null) {
      channel.setRemoteSdpToChannel(RTCSessionDescription(sdp, "answer"));
    }
  }

  @override
  void onRemoteSDPEventOffer(int opponentId, String sdp) {
    logTime("onRemoteSDPEventOffer", _TAG);
    // set CallType.VIDEO_CALL for getting video in any call mode (audio, video)
    _makeAndAddNewChannelForOpponent(opponentId, CallType.VIDEO_CALL);
    createAnswer(opponentId, sdp);
  }

  @override
  void onSlowLinkReceived(bool uplink, int lost) {
    logTime("onSlowLinkReceived", _TAG);
    if(onSlowLink != null) onSlowLink(uplink, lost);
  }

  @override
  void onStartedEvent(String started) {
    logTime("onStartedEvent started= $started", _TAG);
  }

  @override
  void onUnPublishedEvent(int publisherId) {
    logTime("onUnPublishedEvent publisherID= $publisherId", _TAG);
  }

  @override
  void onVideoRoomEvent(String event) {
    // TODO: implement onVideoRoomEvent
    logTime("onVideoRoomEvent event= $event", _TAG);
  }

  @override
  void onWebRTCUpReceived(int senderId) {
    logTime("onWebRTCUpReceived senderId= $senderId", _TAG);
    if (isPublisherEvent(senderId)) {
      logTime("became a publisher");
      autoSubscribeToPublisher(true);
    }
  }

  void notifyJoinedSuccessListeners(List<int> publishers) {
    _joinCallback(publishers);
  }

  void detachHandleId(covariant userId) async {
    try {
    await _signaler.detachHandleId(userId);
    } on WsException catch (ex) {
      logTime("detachHandleIdSync error: = $ex");
      notifySessionError(ex);
    }
  }

  void cleanUpPeerConnection(int userId) {
    ConferencePeerConnection channel = channels[userId];
    if (channel != null) {
      channel.close();
    }
  }

  void autoSubscribeToPublisher(bool autoSubscribe) async {
    if (autoSubscribe) {
      logTime("autoSubscribeToPublisher enabled");
      for (int publisher in joinEventPublishers) {
       await subscribeToPublisher(publisher);
      }
      joinEventPublishers.clear();
    }
  }

  void selectJoinStrategy() {
    if (ConferenceRole.PUBLISHER == sessionDescription.conferenceRole) {
      performSendOffer();
    } else if (ConferenceRole.LISTENER == sessionDescription.conferenceRole) {
//      proceedAsListener();
    }
  }

  void performSendOffer() {
    setState(RTCSessionState.RTC_SESSION_CONNECTING);
    _makeAndAddNewChannelForOpponent(currentUserId, sessionDescription.conferenceType);
    createOffer(currentUserId);
  }

  void _makeAndAddNewChannelForOpponent(int opponentId, int conferenceType) {
    if (!channels.containsKey(opponentId)) {
      ConferencePeerConnection newChannel = new ConferencePeerConnection(opponentId, this);

      channels[opponentId] = newChannel;
      logTime("Make new channel for opponent: $opponentId, $newChannel", _TAG);
    } else {
      logTime("Channel with this opponent $opponentId, already exists", _TAG);
    }
  }

  void createOffer(int opponentId) async {
    await initLocalMediaStream();
    channels[opponentId].startOffer();
//    if (RTCConfig.instance.getStatsReportTimeInterval() > 0) {//ToDo need to implement StatsReport
//      startFetchStatsReport();
//    }
  }

  void createAnswer(int opponentId, String sdp) {
    ConferencePeerConnection channel = channels[opponentId];
    if (channel != null) {
      logTime("setRemoteSdpToChannel", _TAG);
      channel.setRemoteSdp(RTCSessionDescription(sdp, "offer"));
      channel.startAnswer();
    }
  }

  void sendIceCandidateComplete(int userId) async {
    logTime("signaler sendIceCandidateComplete for userId= $userId", _TAG);
    try {
      await _signaler.sendIceCandidateComplete(userId);
    } on WsException catch (ex) {
      logTime("sendIceCandidateComplete error: = $ex");
      notifySessionError(ex);
    }
  }

  @override
  void onPeerConnectionStateChanged(int userId, PeerConnectionState state) {
    switch (state) {
      case PeerConnectionState.RTC_CONNECTION_CONNECTED:
        super.onPeerConnectionStateChanged(userId, state);
        logTime("onPeerConnectionStateChanged can send sendIceCandidateComplete()", _TAG);
        break;
      default:
        super.onPeerConnectionStateChanged(userId, state);
        break;
    }
  }

  @override
  void onSendAnswer(int userId, RTCSessionDescription sdp) async{
    logTime("onSendAnswer", _TAG);
    try {
      await _signaler.sendAnswer(userId, sdp, sessionDescription.conferenceType);
    } on WsException catch (ex) {
      logTime("onSendAnswer error: = $ex");
      notifySessionError(ex);
    }
  }

  @override
  void onSendOffer(int userId, RTCSessionDescription sdp) async {
    logTime("onSendOffer", _TAG);
    try {
      await _signaler.sendOffer(userId, sdp, sessionDescription.conferenceType);
    } on WsException catch (ex) {
      logTime("onSendOffer error: = $ex");
      notifySessionError(ex);
    }
  }

  @override
  void onSendIceCandidate(int userId, RTCIceCandidate iceCandidate) async {
    logTime("onSendIceCandidate", _TAG);
    if (isConnectionActive()) {
      try {
        await _signaler.sendIceCandidate(userId, iceCandidate);
      } on WsException catch(ex) {
        logTime("onSendIceCandidate error: = $ex");
      notifySessionError(ex);
      }
    }
  }

  @override
  void onSendIceCandidates(int userId, List<RTCIceCandidate> iceCandidates) {
    logTime("onSendIceCandidates", _TAG);
    iceCandidates.forEach((iceCandidate) {
      onSendIceCandidate(userId, iceCandidate);
    });
  }

  @override
  void onIceGatheringStateChanged(int userId, RTCIceGatheringState state) {
    super.onIceGatheringStateChanged(userId, state);
    if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      sendIceCandidateComplete(userId);
    }
  }

  bool isConnectionActive() {
    return _signaler.isActive();
  }

  @override
  int get callType => sessionDescription.conferenceType;

  bool isPublisherEvent(int senderId) {
    return joinSenderId == senderId;
  }
}