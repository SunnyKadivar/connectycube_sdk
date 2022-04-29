import 'dart:async';

import 'package:xmpp_stone/xmpp_stone.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

import '../extentions.dart';
import '../managers/messages_manager.dart';
import '../utils/messages_utils.dart';
import '../../models/typing_status_model.dart';
import '../../realtime/utils/jid_utils.dart';

class TypingStatusesManager extends MessagesManager {
  static Map<Connection, TypingStatusesManager> _instances = Map();

  StreamController<TypingStatus> _isTypingStreamController;
  StreamController<TypingStatus> _stopTypingStreamController;

  Stream<TypingStatus> get isTypingStream => _isTypingStreamController.stream;

  Stream<TypingStatus> get stopTypingStream =>
      _stopTypingStreamController.stream;

  TypingStatusesManager._private(Connection connection) : super(connection) {
    _isTypingStreamController = StreamController.broadcast();
    _stopTypingStreamController = StreamController.broadcast();
  }

  static getInstance(Connection connection) {
    TypingStatusesManager manager = _instances[connection];
    if (manager == null) {
      manager = TypingStatusesManager._private(connection);
      _instances[connection] = manager;
    }

    return manager;
  }

  @override
  bool acceptMessage(MessageStanza stanza) {
    XmppElement stateElement = stanza.children.firstWhere(
        (element) =>
            element.getAttribute("xmlns")?.value == ChatStateElement.NAME_SPACE,
        orElse: () => null);
    if (stateElement != null) {
      Jid from = stanza.fromJid;

      int userId;
      String dialogId;

      if (isGroupChatJid(from)) {
        userId = getUserIdFromGroupChatJid(from);
        dialogId = getDialogIdFromGroupChatJid(from);
      } else {
        userId = getUserIdFromJid(from);
      }

      var state = stateFromString(stateElement.name);
      if (ChatState.COMPOSING == state) {
        _isTypingStreamController.add(TypingStatus(userId, dialogId));
        return true;
      } else if (ChatState.PAUSED == state) {
        _stopTypingStreamController.add(TypingStatus(userId, dialogId));
        return true;
      }
    }

    return false;
  }

  @override
  void closeStreams() {
    _isTypingStreamController.close();
    _stopTypingStreamController.close();
  }

  @override
  void destroy() {
    _instances.remove(connection);
  }
}
