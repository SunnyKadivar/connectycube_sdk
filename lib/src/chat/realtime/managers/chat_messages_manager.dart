import 'dart:async';

import 'package:xmpp_stone/xmpp_stone.dart';

import '../../../../connectycube_core.dart';

import '../../models/cube_error_packet.dart';
import '../../models/cube_message.dart';
import '../../realtime/managers/messages_manager.dart';

class ChatMessagesManager extends MessagesManager {
  static Map<Connection, ChatMessagesManager> _instances = Map();

  StreamController<CubeMessage> _chatMessagesStreamController;

  Stream<CubeMessage> get chatMessagesStream =>
      _chatMessagesStreamController.stream;

  ChatMessagesManager._private(Connection connection) : super(connection) {
    _chatMessagesStreamController = StreamController.broadcast();
  }

  static getInstance(Connection connection) {
    ChatMessagesManager manager = _instances[connection];
    if (manager == null) {
      manager = ChatMessagesManager._private(connection);
      _instances[connection] = manager;
    }

    return manager;
  }

  @override
  bool acceptMessage(MessageStanza messageStanza) {
    if (MessageStanzaType.CHAT == messageStanza.type) {
      log("Receive PRIVATE chat message ${messageStanza.id}");
      CubeMessage cubeMessage = CubeMessage.fromStanza(messageStanza);
      _chatMessagesStreamController.add(cubeMessage);
      return true;
    } else if (MessageStanzaType.GROUPCHAT == messageStanza.type) {
      log("Receive GROUP chat message ${messageStanza.id}");
      CubeMessage cubeMessage = CubeMessage.fromStanza(messageStanza);
      _chatMessagesStreamController.add(cubeMessage);
      return true;
    } else if (MessageStanzaType.ERROR == messageStanza.type) {
      _chatMessagesStreamController
          .addError(ErrorPacket.fromStanza(messageStanza.getChild('error')));
      return true;
    }

    return false;
  }

  @override
  void closeStreams() {
    _chatMessagesStreamController.close();
  }

  @override
  void destroy() {
    _instances.remove(connection);
  }
}
