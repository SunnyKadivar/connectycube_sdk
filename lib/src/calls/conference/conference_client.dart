import 'dart:async';

import '../../../connectycube_sdk.dart';
import 'conference_session.dart';
import 'ws_exeptions.dart';
import 'conference_config.dart';

import '../../../connectycube_core.dart';
import '../signaling/janus_signaler.dart';

class ConferenceClient {
  static final ConferenceClient _instance = ConferenceClient._privateConstructor();
  ConferenceClient._privateConstructor();
  static ConferenceClient get instance => _instance;

  JanusSignaler _signaler;
  int currentUserId;

  Future<ConferenceSession> createCallSession(int userId, [int callType = CallType.VIDEO_CALL]) async {
    log("createSession userId= $userId");
    currentUserId = userId;
    _signaler = new JanusSignaler(ConferenceConfig.instance.url, ConferenceConfig.instance.protocol, ConferenceConfig.instance.socketTimeOutMs, ConferenceConfig.instance.keepAliveValueSec);
    Completer<ConferenceSession> completer = Completer<ConferenceSession>();
    try {
      await _signaler.startSession();
      await _attachPlugin('janus.plugin.videoroom');
      _signaler.startAutoSendPresence();
      ConferenceSession session = ConferenceSession(this, _signaler, callType);
      completer.complete(session);
    } on WsException catch(ex) {
      completer.completeError(ex);
    }
    return completer.future;
  }

  Future<void> _attachPlugin(String plugin) {
    return _signaler.attachPlugin(plugin, currentUserId);
  }
}
