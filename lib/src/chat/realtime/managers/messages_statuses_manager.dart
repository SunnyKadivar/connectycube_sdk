import 'dart:async';

import 'package:xmpp_stone/xmpp_stone.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

import '../extentions.dart';
import '../managers/messages_manager.dart';
import '../../models/message_status_model.dart';
import '../../realtime/utils/jid_utils.dart';

class MessagesStatusesManager extends MessagesManager {
  static Map<Connection, MessagesStatusesManager> _instances = Map();

  StreamController<MessageStatus> _deliveredStreamController;
  StreamController<MessageStatus> _readStreamController;

  Stream<MessageStatus> get deliveredStream =>
      _deliveredStreamController.stream;

  Stream<MessageStatus> get readStream => _readStreamController.stream;

  MessagesStatusesManager._private(Connection connection) : super(connection) {
    _deliveredStreamController = StreamController.broadcast();
    _readStreamController = StreamController.broadcast();
  }

  static getInstance(Connection connection) {
    MessagesStatusesManager manager = _instances[connection];
    if (manager == null) {
      manager = MessagesStatusesManager._private(connection);
      _instances[connection] = manager;
    }

    return manager;
  }

  @override
  bool acceptMessage(MessageStanza stanza) {
    XmppElement stateElement = stanza.children.firstWhere(
        (element) =>
            element.getAttribute("xmlns")?.value ==
            MessageMarkerElement.NAME_SPACE,
        orElse: () => null);
    if (stateElement != null) {
      MessageMarkerElement marker =
          MessageMarkerElement.fromStanza(stateElement);

      String messageStatus = marker.name;

      if ('markable' == messageStatus) {
        return false;
      }

      String messageId = marker.getMessageId();
      String dialogId = _getDialogIdFromExtraParams(stanza);

      Jid from = stanza.fromJid;
      int userId = getUserIdFromJid(from);

      if ('received' == messageStatus) {
        _deliveredStreamController
            .add(MessageStatus(userId, messageId, dialogId));
        return true;
      } else if ('displayed' == messageStatus) {
        _readStreamController.add(MessageStatus(userId, messageId, dialogId));
        return true;
      }
    }

    return false;
  }

  @override
  void closeStreams() {
    _deliveredStreamController.close();
    _readStreamController.close();
  }

  @override
  void destroy() {
    _instances.remove(connection);
  }
}

String _getDialogIdFromExtraParams(MessageStanza stanza) {
  String dialogId;
  var extraParamsElement = stanza.getChild(ExtraParamsElement.ELEMENT_NAME);
  if (extraParamsElement != null) {
    ExtraParamsElement extraParams =
        ExtraParamsElement.fromStanza(extraParamsElement);
    dialogId = extraParams.getParams()['dialog_id'];
  }

  return dialogId;
}
