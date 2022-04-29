import 'package:xmpp_stone/xmpp_stone.dart';

import 'chat_constants.dart';
import '../extentions.dart';

bool isSystemNotification(MessageStanza message) {
  ExtraParamsElement extension = ExtraParamsElement.fromStanza(
      message.getChild(ExtraParamsElement.ELEMENT_NAME));
  if (extension != null) {
    Map<String, String> properties = extension.getParams();
    String moduleIdentifier = properties[MODULE_IDENTIFIER];
    if (moduleIdentifier != null &&
        moduleIdentifier == MODULE_SYSTEM_NOTIFICATIONS) {
      return true;
    }
  }

  return false;
}

bool isCallNotification(MessageStanza message) {
  ExtraParamsElement extension = ExtraParamsElement.fromStanza(
      message.getChild(ExtraParamsElement.ELEMENT_NAME));
  if (extension != null) {
    Map<String, String> properties = extension.getParams();
    String moduleIdentifier = properties[MODULE_IDENTIFIER];
    if (MODULE_CALL_NOTIFICATIONS == moduleIdentifier) {
      return true;
    }
  }

  return false;
}

ChatState stateFromString(String chatStateString) {
  switch (chatStateString) {
    case "inactive":
      return ChatState.INACTIVE;
    case "active":
      return ChatState.ACTIVE;
    case "gone":
      return ChatState.GONE;
    case "composing":
      return ChatState.COMPOSING;
    case "paused":
      return ChatState.PAUSED;
  }
  return ChatState.INACTIVE;
}
