import 'package:xmpp_stone/xmpp_stone.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

import '../models/cube_message.dart';
import '../realtime/utils/jid_utils.dart';
import '../realtime/utils/messages_utils.dart';

abstract class CubeXmppElement extends XmppElement {
  get elementName;

  get nameSpace;

  CubeXmppElement() {
    addAttribute(XmppAttribute('xmlns', nameSpace));
  }

  @override
  get name => elementName;

  @override
  String getNameSpace() => nameSpace;
}

class ExtraParamsElement extends CubeXmppElement {
  static const String ELEMENT_NAME = 'extraParams';
  static const String NAME_SPACE = 'jabber:client';

  ExtraParamsElement.fromStanza(XmppElement stanza) {
    stanza.attributes.forEach((attribute) => addAttribute(attribute));
    stanza.children.forEach((child) => addChild(child));
  }

  ExtraParamsElement() : super();

  void addParam(String name, String value) {
    XmppElement customParam = XmppElement();
    customParam.name = name;
    customParam.textValue = value;

    children.add(customParam);
  }

  void addParams(Map<String, String> params) {
    params.forEach((key, value) => addParam(key, value));
  }

  Map<String, String> getParams() {
    Map<String, String> params = Map();

    children.forEach((xmppElement) {
      if (xmppElement.name != AttachmentElement.ELEMENT_NAME) {
        params[xmppElement.name] = xmppElement.textValue;
      }
    });

    return params;
  }

  List<CubeAttachment> getAttachments() {
    return children
        .where(
            (xmppElement) => AttachmentElement.ELEMENT_NAME == xmppElement.name)
        .map((xmppElement) {
      AttachmentElement attachmentElement =
          AttachmentElement.fromStanza(xmppElement);
      return attachmentElement.toAttachment();
    }).toList();
  }

  @override
  get elementName => ELEMENT_NAME;

  @override
  get nameSpace => NAME_SPACE;
}

class AttachmentElement extends XmppElement {
  static const String ELEMENT_NAME = 'attachment';

  @override
  get name => ELEMENT_NAME;

  AttachmentElement.fromStanza(XmppElement stanza) {
    stanza.attributes.forEach((attribute) => addAttribute(attribute));
    stanza.children.forEach((child) => addChild(child));
  }

  AttachmentElement.fromAttachment(CubeAttachment attachment) {
    attachment.toJson().forEach((key, value) {
      if (value != null) {
        if (key == 'data') {
          value = Uri.encodeComponent(value);
        }
        addAttribute(XmppAttribute(key, value.toString()));
      }
    });
  }

  CubeAttachment toAttachment() {
    Map<String, dynamic> attachmentAttributes = Map();

    attributes.forEach((attribute) {
      String name = attribute.name;
      String stringValue = attribute.value;

      dynamic value;

      switch (name) {
        case 'data':
          value = Uri.decodeComponent(stringValue);
          break;
        default:
          value = stringValue;
      }
      attachmentAttributes[name] = value;
    });

    return CubeAttachment.fromJson(attachmentAttributes);
  }
}

class SelfDestroyElement extends CubeXmppElement {
  static const String ELEMENT_NAME = 'destroy';
  static const String NAME_SPACE = 'urn:xmpp:message-destroy-after:0';

  int _after;

  SelfDestroyElement(int destroyAfter) {
    addAttribute(XmppAttribute('after', destroyAfter.toString()));
  }

  SelfDestroyElement.fromStanza(XmppElement stanza) {
    this._after = int.parse(stanza.getAttribute('after').value);
  }

  get after => _after;

  @override
  get elementName => ELEMENT_NAME;

  @override
  get nameSpace => NAME_SPACE;
}

class RemoveMessageElement extends CubeXmppElement {
  static const String ELEMENT_NAME = 'remove';
  static const String NAME_SPACE = 'urn:xmpp:message-delete:0';

  RemoveMessageElement(String originalMsgId) {
    addAttribute(XmppAttribute('id', originalMsgId));
  }

  @override
  get elementName => ELEMENT_NAME;

  @override
  get nameSpace => NAME_SPACE;
}

class EditMessageElement extends CubeXmppElement {
  static const String ELEMENT_NAME = 'replace';
  static const String NAME_SPACE = 'urn:xmpp:message-correct:0';

  EditMessageElement(String originalMsgId, bool isLastMessage) {
    addAttribute(XmppAttribute('id', originalMsgId));
    addAttribute(XmppAttribute('last', isLastMessage.toString()));
  }

  @override
  get elementName => ELEMENT_NAME;

  @override
  get nameSpace => NAME_SPACE;
}

class JoinPresenceStanza extends AbstractStanza {
  JoinPresenceStanza(String dialogId, int currentUserId) {
    id = AbstractStanza.getRandomId();

    children.add(JoinXElement());

    toJid = Jid.fromFullJid("${getJidForGroupChat(dialogId)}/$currentUserId");
  }

  @override
  set toJid(Jid value) {
    super.toJid = value;
    addAttribute(XmppAttribute('to', value.fullJid));
  }

  @override
  get name => 'presence';
}

class LeavePresenceStanza extends AbstractStanza {
  LeavePresenceStanza(String dialogId, int currentUserId) {
    id = AbstractStanza.getRandomId();
    addAttribute(XmppAttribute("type", "unavailable"));

    toJid = Jid.fromFullJid("${getJidForGroupChat(dialogId)}/$currentUserId");
  }

  @override
  set toJid(Jid value) {
    super.toJid = value;
    addAttribute(XmppAttribute('to', value.fullJid));
  }

  @override
  get name => 'presence';
}

class JoinXElement extends CubeXmppElement {
  static const String ELEMENT_NAME = 'x';
  static const String NAME_SPACE = 'http://jabber.org/protocol/muc';

  @override
  get elementName => ELEMENT_NAME;

  @override
  get nameSpace => NAME_SPACE;
}

class MessageMarkerElement extends CubeXmppElement {
  static const String NAME_SPACE = 'urn:xmpp:chat-markers:0';
  String _markerName;
  String _id;

  MessageMarkerElement.fromStanza(XmppElement stanza) {
    _markerName = stanza.name;
    stanza.attributes.forEach((attribute) => addAttribute(attribute));
    stanza.children.forEach((child) => addChild(child));
  }

  MessageMarkerElement(this._markerName, [this._id]) : super() {
    if (_id != null) {
      addAttribute(XmppAttribute('id', _id));
    }
  }

  String getMessageId() {
    return getAttribute('id').value;
  }

  @override
  get elementName => _markerName;

  @override
  get nameSpace => NAME_SPACE;

  @override
  get name => elementName;
}

class ChatStateElement extends CubeXmppElement {
  static const String NAME_SPACE = 'http://jabber.org/protocol/chatstates';
  ChatState state;

  ChatStateElement.fromStanza(XmppElement stanza) {
    state = stateFromString(stanza.name);
    stanza.attributes.forEach((attribute) => addAttribute(attribute));
    stanza.children.forEach((child) => addChild(child));
  }

  ChatStateElement(this.state) : super();

  @override
  get elementName => state.toString().split('.').last.toLowerCase();

  @override
  get nameSpace => NAME_SPACE;

  @override
  get name => elementName;
}

class LastActivityQuery extends CubeXmppElement {
  static const String ELEMENT_NAME = 'query';
  static const String NAME_SPACE = 'jabber:iq:last';

  LastActivityQuery.fromStanza(XmppElement stanza) {
    stanza.attributes.forEach((attribute) => addAttribute(attribute));
    stanza.children.forEach((child) => addChild(child));
  }

  LastActivityQuery() : super();

  int getSeconds() {
    return int.parse(getAttribute('seconds').value);
  }

  @override
  get elementName => ELEMENT_NAME;

  @override
  get nameSpace => NAME_SPACE;
}
