import 'dart:convert';

class WsPacket {
  Type messageType;
  int sessionId;
  String transaction;
  String token;

  WsPacket();

  WsPacket.fromJson(Map<String, dynamic> json)
      : messageType = getTypeFromString(json['janus']),
        sessionId = json['session_id'],
        transaction = json['transaction'],
        token = json['token'];

  Map<String, dynamic> toJson() {
    return {
      'janus': messageType.toString().split('.').last,
      'session_id': sessionId,
      'transaction': transaction,
      'token': token,
    };
  }

  static Type getTypeFromString(String typeAsString) {
    for (Type element in Type.values) {
      if (element.toString().split('.').last == typeAsString) {
        return element;
      }
    }
    return null;
  }

  @override
  String toString() {
    return "WsPacket{" +
        "messageType=" +
        messageType.toString() +
        ", sessionId=" +
        sessionId.toString() +
        '}';
  }
}

enum Type {
  message,
  info,
  trickle,
  detach,
  destroy,
  keepalive,
  create,
  attach,
  event,
  error,
  ack,
  success,
  webrtcup,
  hangup,
  detached,
  media,
  listparticipants,
  timeout,
  slowlink
}

String encode(Map<String, dynamic> map) {
  String raw = jsonEncode(map);
  return raw;
}

WsPacket parse(String rawMessage) {
  Map<String, dynamic> map = jsonDecode(rawMessage);
  String janus = map['janus'];
  return parsePacketType(janus, map);
}

WsPacket parsePacketType(String janus, Map<String, dynamic> jsonMap) {
  Type type = Type.values.firstWhere((e) => e.toString() == 'Type.' + janus);
  switch (type) {
    case Type.ack:
      return createAck(jsonMap);
    case Type.success:
      return createSuccessResponse(jsonMap);
    case Type.event:
      return createEventResponse(jsonMap);
    case Type.webrtcup:
      return createWebrtcUpResponse(jsonMap);
    case Type.media:
      return createWsMediaResponse(jsonMap);
    case Type.hangup:
      return createWsHangUpResponse(jsonMap);
    case Type.slowlink:
      return createWsSlowLink(jsonMap);
    case Type.error:
      return createWsError(jsonMap);
    default:
      return createResponsePacket(jsonMap);
  }
}

T parseToModel<T extends WsPacket>(String raw) {
  T fromJson = jsonDecode(raw);
  return fromJson;
}

WsAck createAck(Map<String, dynamic> jsonMap) {
  return WsAck.fromJson(jsonMap);
}

class WsAck extends WsPacket {
  WsAck.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}

WsEvent createEventResponse(Map<String, dynamic> jsonMap) {
  return WsEvent.fromJson(jsonMap);
}

WsWebRTCUp createWebrtcUpResponse(Map<String, dynamic> jsonMap) {
  return WsWebRTCUp.fromJson(jsonMap);
}

WsMedia createWsMediaResponse(Map<String, dynamic> jsonMap) {
  return WsMedia.fromJson(jsonMap);
}

WsHangUp createWsHangUpResponse(Map<String, dynamic> jsonMap) {
  return WsHangUp.fromJson(jsonMap);
}

WsSlowLink createWsSlowLink(Map<String, dynamic> jsonMap) {
  return WsSlowLink.fromJson(jsonMap);
}

WsPacket createSuccessResponse(Map<String, dynamic> jsonMap) {
  return WsDataPacket.fromJson(jsonMap);
}

WsError createWsError(Map<String, dynamic> jsonMap) {
  return WsError.fromJson(jsonMap);
}

class WsError extends WsPacket {
  Error error;

  WsError.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    error = Error.fromJson(json['error']);
  }
}

class Error {
  int code;
  String reason;

  Error.fromJson(Map<String, dynamic> json)
      : code = json['code'],
        reason = json['reason'];
}

WsPacket createResponsePacket(Map<String, dynamic> jsonMap) {
  return WsPacket.fromJson(jsonMap);
}

class WsDataPacket extends WsPacket {
  SessionData data;
  Plugindata plugindata;

  WsDataPacket() : super();

  WsDataPacket.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    data = json['data'] != null ? SessionData.fromJson(json['data']) : null;
  }

  getData() {
    return data;
  }

  bool isGetParticipant() {
    return plugindata != null &&
        plugindata.data != null &&
        plugindata.data.videoroom == "participants";
  }

  bool isVideoRoomEvent() {
    return plugindata != null &&
        plugindata.data != null &&
        plugindata.data.videoroom == "event";
  }
}

class SessionData {
  int _id;

  SessionData.fromJson(Map<String, dynamic> json) : _id = json['id'];

  get id => _id;
}

class Plugindata {
  Data data;

  Plugindata.fromJson(Map<String, dynamic> json) : data = Data.fromJson(json['data']);
}

class Data {
  Participant participant;//joining
  String videoroom;
  String room;
  String error;
  String started;
  dynamic leaving;
  String left;
  int id;
  int errorCode;//error_code
  int unpublished;
  List<Publisher> publishers;
  List<Subscriber> subscribers;//attendees
  List<Map<String, Object>> participants;//FixME RP not implemented yet!

  Data.fromJson(Map<String, dynamic> json)
      : participant = json['joining'] != null ? Participant.fromJson(json['joining']) : null,
        videoroom = json['videoroom'],
        room = json['room'],
        error = json['error'],
        started = json['started'],
        leaving = json['leaving'],
        left = json['left'],
        id = json['id'],
        errorCode = json['error_code'],
        unpublished = json['unpublished'],
        publishers = json['publishers']!= null ? List.of(json['publishers']).map((json) => Publisher.fromJson(json)).toList(): null,
        subscribers = json['attendees']!= null ? List.of(json['attendees']).map((json) => Subscriber.fromJson(json)).toList(): null;
}

class WsEvent extends WsPacket {
  int sender;
  Plugindata plugindata;
  Jsep jsep;

  WsEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    sender = json['sender'];
    plugindata = Plugindata.fromJson(json['plugindata']);
    jsep = json['jsep']!= null ? Jsep.fromJson(json['jsep']) : null;
  }

  bool isJoiningEvent() {
    return !(!isWithPluginData() || plugindata.data.participant == null);
  }

  bool isJoinEvent() {
    return !(!isEventWithPublishers() || plugindata.data.videoroom != "joined");
  }

  bool isEventError() {
    return !(plugindata.data.videoroom != "event" || plugindata.data.error == null);
  }

  bool isRemoteSDPEventAnswer() {
    return !(!isEventSDP() || jsep.type != "answer");
  }

  bool isRemoteSDPEventOffer() {
    return !(!isEventSDP() || jsep.type != "offer");
  }

  bool isPublisherEvent() {
    return !(!isEventWithPublishers() || plugindata.data.videoroom != "event");
  }

  bool isUnPublishedEvent() {
    return !(!isWithPluginData() || plugindata.data.unpublished == null);
  }

  bool isStartedEvent() {
    return !(!isWithPluginData() || plugindata.data.started == null);
  }

  bool isLeaveParticipantEvent() {
    return !(!isWithPluginData() || plugindata.data.leaving == null || transaction != null);
  }

  bool isLeaveCurrentUserEvent() {
    return !(!isWithPluginData() || plugindata.data.leaving == null || transaction == null);
  }

  bool isLeftCurrentUserEvent() {
    return !(!isWithPluginData() || plugindata.data.left == null || transaction == null);
  }

  bool isEventWithPublishers() {
    return !(!isWithPluginData() || plugindata.data.publishers == null);
  }

  bool isEventSDP() {
    return !(jsep == null || jsep.sdp == null);
  }

  bool isWithPluginData() {
    return !((plugindata == null || plugindata.data == null));
  }
}

class Jsep {
  String type;
  String sdp;

  Jsep();

  Jsep.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        sdp = json['sdp'];

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'sdp': sdp
    };
  }
}

class Participant {
  int id;
  String display;

  Participant.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        display= json['display'];
}

class Publisher {
  int id;
  String audioCodec;//audio_codec
  String videoCodec;//video_codec
  bool talking;

  Publisher.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        audioCodec= json['audio_codec'],
        videoCodec= json['video_codec'],
        talking= json['talking'];

  @override
  String toString() {
    return "{id= $id, audioCodec= $audioCodec, videoCodec= $videoCodec, talking= $talking}";
  }
}
class Subscriber {
  int id;
  String conferenceRole;//display

  Subscriber.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        conferenceRole = json['display'];

  @override
  String toString() {
    return "{userId= $id, conferenceRole= $conferenceRole}";
  }
}
class WsWebRTCUp extends WsPacket {
  int sender;
  WsWebRTCUp.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    sender = json['sender'];
  }
}
class WsMedia extends WsPacket {
  int sender;
  String type;
  bool receiving;
  WsMedia.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    sender = json['sender'];
    type = json['type'];
    receiving = json['receiving'];
  }
}
class WsHangUp extends WsPacket {
  String reason;
  WsHangUp.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    reason = json['reason'];
  }
}
class WsSlowLink extends WsPacket{
  bool uplink;
  int lost;
  WsSlowLink.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    uplink = json['uplink'];
    lost = json['lost'];
  }
}
class WsKeepAlive extends WsPacket{}
class WsPluginPacket extends WsDataPacket {
  String plugin;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['plugin'] = plugin;
    return json;
  }
}
class WsRequestPacket extends WsPacket {
  int handleId;//handle_id
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['handle_id'] = handleId;
    return json;
  }
}

class WsRoomPacket extends WsRequestPacket {
  Body body;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['body'] = body.toJson();
    return json;
  }
}
class Body {
  int userId; //id
  String display;
  int feed;
  String ptype;
  String room;
  WsRoomPacketType request;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonMap = {
      'id': userId,
      'feed': feed,
      'ptype': ptype,
      'room': room,
      'request': request.toString().split('.').last,
    };
    if(display != null) jsonMap['display'] = display;
    return jsonMap;
  }
}
enum WsRoomPacketType {
  join,
  leave
}

class WsDetach extends WsDataPacket {
  int handleId; //handle_id
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['handle_id'] = handleId;
    return json;
  }
}

class WsCandidate extends WsRequestPacket {
  Candidate candidate;
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['candidate'] = candidate.toJson();
    return json;
  }
}

class Candidate {
  String candidate;
  int sdpMLineIndex;
  String sdpMid;
  bool completed;

    Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonMap = Map();
    if(candidate != null) jsonMap['candidate'] = candidate;
    if(sdpMLineIndex != null) jsonMap['sdpMLineIndex'] = sdpMLineIndex;
    if(sdpMid != null) jsonMap['sdpMid'] = sdpMid;
    if(completed != null) jsonMap['completed'] = completed;
    return jsonMap;
  }
}

class WsOfferAnswer extends WsRequestPacket {
  Jsep jsep;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['jsep'] = jsep.toJson();
    return json;
  }
}
enum WsOfferAnswerType {
  configure,
  start
}

class WsOffer extends WsOfferAnswer {
  WsOfferBody body;
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['body'] = body.toJson();
    return json;
  }
}

class WsOfferBody {
  bool audio;
  bool video;
  WsOfferAnswerType request;
  Map<String, dynamic> toJson() {
    return {
      'audio': audio,
      'video': video,
      'request': request.toString().split('.').last,
    };
  }
}

class WsAnswer extends WsOfferAnswer {
  WsAnswerBody body;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['body'] = body.toJson();
    return json;
  }
}

class WsAnswerBody {
  String room;
  WsOfferAnswerType request;

  Map<String, dynamic> toJson() {
    return {
      'room': room,
      'request': request.toString().split('.').last,
    };
  }
}