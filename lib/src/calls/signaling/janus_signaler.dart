import 'dart:async';
import 'dart:collection';

import '../../../connectycube_calls.dart';
import 'web_socket_connection.dart';
import 'web_socket_packets.dart';
import 'web_socket_packets.dart' as web_socket_packets;

import '../../../connectycube_core.dart';

class JanusSignaler implements WsPacketListener {
  static const String TAG = "JanusSignaler";
  static const KEEP_ALIVE_PERIOD = const Duration(seconds:30);
  int _userId;
  String dialogId;
  WebSocketConnection socketConnection;
  HashMap<int, int> handleIDs = HashMap();
  JanusResponseEventCallback _janusResponseCallback;
  Timer _keepAliveTimer;

  JanusSignaler(
      String url, String protocol, int socketTimeOutMs, int keepAliveValueSec) {
    socketConnection = new WebSocketConnection(url, protocol);
    socketConnection.addPacketListener(this);
  }

  void setJanusResponseEventCallback(JanusResponseEventCallback callback){
    _janusResponseCallback = callback;
  }

  Future<void> startSession() {
    Completer completer = Completer<void>();
    socketConnection.connect();
    socketConnection.authenticate(completer);
    return completer.future;
  }

  void startAutoSendPresence() {
    logTime("startAutoSendPresence", TAG);
    if(_keepAliveTimer == null) {
      _keepAliveTimer = Timer.periodic(KEEP_ALIVE_PERIOD, (Timer t) => sendKeepAlive());
    }
  }

  void stopAutoSendPresence() {
    if (_keepAliveTimer.isActive) _keepAliveTimer.cancel();
  }

  Future<void> leave(int userId) {
    WsRoomPacket requestPacket = WsRoomPacket();
    requestPacket.messageType = Type.message;
    requestPacket.handleId = handleIDs[userId];
    requestPacket.body = new Body();
    requestPacket.body.room = dialogId;
    requestPacket.body.userId = userId;
    requestPacket.body.request = WsRoomPacketType.leave;
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  void detachHandleIdAll() {
    handleIDs.forEach((key, value) => detachPlugin(value));
  }

  Future<void> detachHandleId(int userId) {
    if (handleIDs.containsKey(userId)) {
      int handleId = handleIDs.remove(userId);
       return detachPlugin(handleId);
    } return Future.value();
  }

  Future<void> detachPlugin(int handleId) {
    WsDetach packet = new WsDetach();
    packet.messageType = Type.detach;
    packet.handleId = handleId;
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(packet, Type.success, completer);
    return completer.future;
//    socketConnection.send(packet);
  }

  Future<void> attachPlugin(String pluginId, int userID) {
    WsPluginPacket packet = new WsPluginPacket();
    packet.messageType = Type.attach;
    packet.plugin = pluginId;
    Completer<void> result = Completer();
    Completer<WsDataPacket> completer = Completer();
    socketConnection.createCollectorAndSend(packet, Type.success, completer);
    completer.future.then((wsDataPacket) {
      logTime("attachPlugin wsDataPacket= $wsDataPacket", TAG);
      int handleId = wsDataPacket
          .getData()
          .id;
      handleIDs[userID] = handleId;
      result.complete();
    });
    return result.future;
  }

  Future<void> joinDialog(String dialogId, int userId, String janusRole) {
    this._userId = userId;
    this.dialogId = dialogId;
    WsRoomPacket requestPacket = joinPacket(janusRole);
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  Future<void> subscribe(String dialogId, int feedId) {
    this.dialogId = dialogId;
    WsRoomPacket requestPacket = new WsRoomPacket();
    requestPacket.messageType = Type.message;
    requestPacket.handleId = handleIDs[feedId];
    requestPacket.body = Body();
    requestPacket.body.room = dialogId;
    requestPacket.body.ptype = "subscriber";
    requestPacket.body.request = WsRoomPacketType.join;
    requestPacket.body.feed = feedId;
    requestPacket.body.userId = _userId;
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  Future<void> sendIceCandidate(int userId, RTCIceCandidate iceCandidate) {
    WsCandidate requestPacket =  WsCandidate();
    requestPacket.messageType = Type.trickle;
    requestPacket.handleId = handleIDs[userId];
    requestPacket.candidate = web_socket_packets.Candidate();
    requestPacket.candidate.candidate = iceCandidate.candidate;
    requestPacket.candidate.sdpMLineIndex = iceCandidate.sdpMlineIndex;
    requestPacket.candidate.sdpMid = iceCandidate.sdpMid;
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  Future<void> sendIceCandidateComplete(int userId) {
    WsCandidate requestPacket = new WsCandidate();
    requestPacket.messageType = Type.trickle;
    requestPacket.handleId = handleIDs[userId];
    requestPacket.candidate = web_socket_packets.Candidate();
    requestPacket.candidate.completed = true;
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  Future<void> sendOffer(int userId, RTCSessionDescription rtcSdp, int callType) {
    bool isVideoType = callType == CallType.VIDEO_CALL;
    WsOffer requestPacket = WsOffer();
    requestPacket.messageType = Type.message;
    requestPacket.handleId = handleIDs[userId];
    requestPacket.body = WsOfferBody();
    requestPacket.body.audio = true;
    requestPacket.body.video = isVideoType;
    requestPacket.body.request = WsOfferAnswerType.configure;
    requestPacket.jsep = Jsep();
    requestPacket.jsep.type = rtcSdp.type;
    requestPacket.jsep.sdp = rtcSdp.sdp;
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  Future<void> sendAnswer(int userId, RTCSessionDescription rtcSdp, int callType) {
    WsAnswer requestPacket = WsAnswer();
    requestPacket.messageType = Type.message;
    requestPacket.handleId = handleIDs[userId];
    requestPacket.body = WsAnswerBody();
    requestPacket.body.room = dialogId;
    requestPacket.body.request = WsOfferAnswerType.start;
    requestPacket.jsep = Jsep();
    requestPacket.jsep.type = rtcSdp.type;
    requestPacket.jsep.sdp = rtcSdp.sdp;
    Completer completer = Completer();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  void destroySession() {
    socketConnection.closeSession();
  }

  Future<void> sendKeepAlive() {
    WsKeepAlive requestPacket = WsKeepAlive();
    requestPacket.messageType = Type.keepalive;
    Completer completer = Completer<void>();
    socketConnection.createCollectorAndSend(requestPacket, Type.ack, completer);
    return completer.future;
  }

  bool isActive() {
    return socketConnection.isActiveSession();
  }

  WsRoomPacket joinPacket(String janusRole) {
    WsRoomPacket requestPacket = new WsRoomPacket();
    requestPacket.messageType = Type.message;
    requestPacket.handleId = handleIDs[_userId];
    requestPacket.body = Body();
    requestPacket.body.room = dialogId;
    requestPacket.body.ptype = janusRole;
    requestPacket.body.request = WsRoomPacketType.join;
    requestPacket.body.userId = _userId;
    return requestPacket;
  }

  void packetParser (WsPacket packet) {
    if (packet is WsEvent) {
    eventParser(packet);
    } else if (packet is WsWebRTCUp) {
    logTime("WsWebRTCUp packet sender= ${packet.sender.toString()}", TAG);
    _janusResponseCallback.onWebRTCUpReceived(packet.sender);
    } else if (packet is WsMedia) {
    logTime("WsMedia packet type= ${packet.type}, receiving= ${packet.receiving.toString()}", TAG);
    _janusResponseCallback.onMediaReceived(packet.type, packet.receiving);
    } else if (packet is WsHangUp) {
     logTime("WsHangUp packet reason= " + packet.reason, TAG);
    _janusResponseCallback.onHangUp(packet.reason);
    } else if (packet is WsSlowLink) {
     logTime("WsSlowLink packet uplink= ${packet.uplink}", TAG);
    _janusResponseCallback.onSlowLinkReceived(packet.uplink, packet.lost);
    } else if(packet is WsDataPacket) {
    if(packet.isGetParticipant()){
    List<Map<String,Object>> participants = packet.plugindata.data.participants;
    _janusResponseCallback.onGetOnlineParticipants(convertParticipantListToArray(participants));
    } else if(packet.isVideoRoomEvent()) {
    _janusResponseCallback.onVideoRoomEvent(packet.plugindata.data.error);
    }
    } else if (packet is WsError && _janusResponseCallback != null) {
    _janusResponseCallback.onEventError(packet.error.reason, packet.error.code);
    }
  }

  Map<int, bool> convertParticipantListToArray(List<Map<String, Object>> participants) {
    Map<int, bool> publishersMap = HashMap<int, bool>();
    participants.forEach((element) {
      int id = element["id"];
      bool isPublisher = element["publisher"];
      publishersMap[id] = isPublisher;
    });
    return publishersMap;
  }

  List<int> convertPublishersToArray(List<Publisher> publishers) {
    List<int> publishersArray = new List<int>();
    publishers.forEach((publisher){
      publishersArray.add(publisher.id);
    });
    return publishersArray;
  }

  List<int> convertSubscribersToArray(List<Subscriber> subscribers) {
    List<int> subscribersArray = new List<int>();

    subscribers.forEach((subscriber){
      subscribersArray.add(subscriber.id);
    });
//    subscribers.map((subscriber) => subscriber.id);//or try this
//    return subscribers;
    return subscribersArray;
  }

  void eventParser(WsEvent wsEvent) {
    if (wsEvent.isRemoteSDPEventAnswer()) {
      logTime("RemoteSDPEventAnswer wsEvent with sdp type= ${wsEvent.jsep.type}", TAG);
      _janusResponseCallback.onRemoteSDPEventAnswer(wsEvent.jsep.sdp);

    } else if (wsEvent.isRemoteSDPEventOffer()){
      int opponentId = wsEvent.plugindata.data.id;
      logTime("RemoteSDPEventOffer wsEvent with sdp type= ${wsEvent.jsep.type}, opponentId= $opponentId",TAG);
      _janusResponseCallback.onRemoteSDPEventOffer(opponentId, wsEvent.jsep.sdp);
    }
    else if (wsEvent.isJoiningEvent()) {
      int participantId = wsEvent.plugindata.data.participant.id;
      String displayRole = wsEvent.plugindata.data.participant.display;
      ConferenceRole conferenceRole;
      if (displayRole != null) {
        conferenceRole = ConferenceRole.values.firstWhere((e) => e.toString() == 'ConferenceRole.'+ displayRole);
      }
      logTime("isJoiningEvent participantId= $participantId , conferenceRole= $displayRole", TAG);
      _janusResponseCallback.onJoiningEvent(participantId, conferenceRole);
    }
    else if (wsEvent.isJoinEvent()) {
      List<Publisher> publishers = wsEvent.plugindata.data.publishers;
      List<Subscriber> subscribers = wsEvent.plugindata.data.subscribers;
      logTime("JoinEvent publishers= $publishers , subscribers= $subscribers", TAG);

      List<int> publishersList = convertPublishersToArray(publishers);
      List<int> subscribersList = convertSubscribersToArray(subscribers);
      _janusResponseCallback.onJoinEvent(publishersList, subscribersList, wsEvent.sender);
    }
    else if (wsEvent.isEventError()) {
      _janusResponseCallback.onEventError(wsEvent.plugindata.data.error, wsEvent.plugindata.data.errorCode);
    }
    else if(wsEvent.isPublisherEvent()){
      List<Publisher> publishers = wsEvent.plugindata.data.publishers;
      logTime("PublisherEvent wsEvent publishers= $publishers", TAG);
      _janusResponseCallback.onPublishedEvent(convertPublishersToArray(publishers));
    }
    else if(wsEvent.isUnPublishedEvent()){
      int usedId = wsEvent.plugindata.data.unpublished;
      logTime("UnPublishedEvent  unpublished usedId= $usedId", TAG);
      _janusResponseCallback.onUnPublishedEvent(usedId);
    }
    else if (wsEvent.isStartedEvent()){
      logTime("StartedEvent subscribed started= ${wsEvent.plugindata.data.started}", TAG);
      _janusResponseCallback.onStartedEvent(wsEvent.plugindata.data.started);
    }
    else if (wsEvent.isLeaveParticipantEvent()) {
      final leaving = wsEvent.plugindata.data.leaving;
      int userId = leaving is String ? int.tryParse(leaving) : leaving;
      logTime("LeavePublisherEvent left userId= ${userId.toString()}", TAG);
      _janusResponseCallback.onLeaveParticipantEvent(userId);
    } else if (wsEvent.isLeaveCurrentUserEvent() || wsEvent.isLeftCurrentUserEvent()) {
      bool leavingOk = wsEvent.plugindata.data.leaving == "ok" || wsEvent.plugindata.data.left == "ok";
      logTime("isLeaveCurrentUserEvent leavingOk? $leavingOk", TAG);
      _janusResponseCallback.onLeaveCurrentUserEvent(leavingOk);
    }
  }

  @override
  onPacketReceived(WsPacket packet) {
    log("_onPacketReceived= ${packet}");
        packetParser(packet);
  }

  @override
  onPacketError(WsPacket packet, String error) {
    log("onPacketError= ${packet}, error=$error");
  }

}

abstract class JanusResponseEventCallback {

void onRemoteSDPEventAnswer(String sdp);

void onRemoteSDPEventOffer(int opponentId, String sdp);

void onJoiningEvent(int participantId, ConferenceRole conferenceRole);

void onJoinEvent(List<int> publishersList, List<int> subscribersList, int senderID);

void onPublishedEvent(List<int> publishersList);

void onUnPublishedEvent(int publisherID);

void onStartedEvent(String started);

void onLeaveParticipantEvent(int publisherID);

void onLeaveCurrentUserEvent(bool success);

void onWebRTCUpReceived(int senderID);

void onMediaReceived(String type, bool success);

void onSlowLinkReceived(bool uplink, int lost);

void onHangUp(String reason);

void onEventError(String error, int code);

void onPacketError(String error);

//    returns map with ids participants and boolean is this participant a publisher
void onGetOnlineParticipants(Map<int, bool> participants);

void onVideoRoomEvent(String event);
}

enum ConferenceRole {
  PUBLISHER,
  LISTENER
}
