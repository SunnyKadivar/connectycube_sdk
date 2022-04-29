import 'package:crossplat_objectid/crossplat_objectid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import '../../../connectycube_core.dart';

import '../realtime/extentions.dart';
import '../realtime/utils/jid_utils.dart';

class CubeMessage extends CubeEntity {
  String messageId;
  String dialogId;
  int dateSent = 0;
  String body;
  List<int> readIds;
  List<int> deliveredIds;
  int viewsCount;
  int recipientId;
  int senderId;
  bool markable = false;
  bool delayed = false;
  Map<String, String> properties = Map();
  List<CubeAttachment> attachments;
  bool saveToHistory = true;
  int destroyAfter;
  bool isRead;

  CubeMessage() {
    messageId = ObjectId().toHexString();
  }

  CubeMessage.fromStanza(MessageStanza stanza) {
    body = stanza.body;

    var stanzaExtraParams = stanza.getChild(ExtraParamsElement.ELEMENT_NAME);
    if (stanzaExtraParams != null) {
      ExtraParamsElement extraParams =
          ExtraParamsElement.fromStanza(stanzaExtraParams);

      properties = extraParams.getParams();

      dialogId = properties['dialog_id'];

      var dateSentRaw = properties['date_sent'];
      if (dateSentRaw != null) {
        try {
          dateSent = int.parse(dateSentRaw);
        } catch (e) {
          dateSent = double.parse(dateSentRaw).toInt();
        }
      }

      attachments = extraParams.getAttachments();
    }

    String packetId = stanza.id;
    messageId =
        ObjectId.isValid(packetId) ? packetId : properties['message_id'];

    markable = stanza.getChild('markable') != null;

    var destroyElement = stanza.getChild(SelfDestroyElement.ELEMENT_NAME);
    if (destroyElement != null) {
      destroyAfter = SelfDestroyElement.fromStanza(destroyElement).after;
    }

    Jid senderJid = stanza.fromJid;
    if (MessageStanzaType.CHAT == stanza.type) {
      senderId = getUserIdFromJid(senderJid);
    } else if (MessageStanzaType.GROUPCHAT == stanza.type) {
      senderId = getUserIdFromGroupChatJid(senderJid);
    } else if (MessageStanzaType.HEADLINE == stanza.type)
      senderId = getUserIdFromJid(senderJid);

    recipientId = getUserIdFromJid(stanza.toJid);
  }

  MessageStanza toStanza(MessageStanzaType type) {
    MessageStanza messageStanza = MessageStanza(messageId, type);
    messageStanza.body = body;

    ExtraParamsElement extraParams = ExtraParamsElement();

    if (dateSent != null && dateSent != 0) {
      extraParams.addParam('date_sent', dateSent.toString());
    } else {
      extraParams.addParam(
          'date_sent', DateTime.now().millisecondsSinceEpoch.toString());
    }

    if (destroyAfter != null && destroyAfter != 0) {
      messageStanza.addChild(SelfDestroyElement(destroyAfter));
    } else if (saveToHistory) {
      extraParams.addParam('save_to_history', '1');
    }

    if (properties != null && properties.isNotEmpty) {
      extraParams.addParams(properties);
    }

    if (!isEmpty(dialogId)) {
      extraParams.addParam('dialog_id', dialogId);
    }

    if (!isEmptyList(attachments)) {
      attachments.forEach((attachment) =>
          extraParams.addChild(AttachmentElement.fromAttachment(attachment)));
    }

    messageStanza.addChild(extraParams);

    if (markable) {
      messageStanza.addChild(MessageMarkerElement('markable'));
    }

    return messageStanza;
  }

  CubeMessage.fromJson(Map<String, dynamic> json) {
    for (String property in json.keys) {
      switch (property) {
        case '_id':
          messageId = json[property];
          break;
        case 'chat_dialog_id':
          dialogId = json[property];
          break;
        case 'message':
          body = json[property];
          break;
        case 'date_sent':
          dateSent = json[property];
          break;
        case 'sender_id':
          senderId = json[property];
          break;
        case 'recipient_id':
          recipientId = json[property];
          break;
        case 'views_count':
          viewsCount = json[property];
          break;
        case 'read_ids':
          readIds = List.of(json[property]).map((id) => id as int).toList();
          break;
        case 'delivered_ids':
          deliveredIds =
              List.of(json[property]).map((id) => id as int).toList();
          break;
        case 'attachments':
          attachments = List.of(json[property])
              .map((element) => CubeAttachment.fromJson(element))
              .toList();
          break;
        case 'read':
          isRead = json[property] == 1;
          break;
        case 'created_at':
          createdAt = DateTime.parse(json[property]);
          break;
        case 'updated_at':
          updatedAt = DateTime.parse(json[property]);
          break;
        default:
          properties[property] = json[property].toString();
      }
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      '_id': messageId,
      'chat_dialog_id': dialogId,
      'message': body,
      'date_sent': dateSent,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'read_ids': readIds,
      'delivered_ids': deliveredIds,
      'views_count': viewsCount,
      'attachments': attachments
    };

    json.addAll(super.toJson());
    json.addAll(properties);

    return json;
  }

  @override
  toString() => toJson().toString();
}

class CubeAttachment {
  String type;
  String id;
  String uid;
  String url;
  String contentType;

  String name;
  String data;
  double size;
  int height;
  int width;
  int duration;

  CubeAttachment();

  CubeAttachment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    type = json['type'];
    url = json['url'];
    contentType = json['content-type'];
    size = json['size'] != null ? double.parse(json['size']) : null;
    name = json['name'];
    data = json['data'];
    width = json['width'] != null ? int.parse(json['width']) : null;
    height = json['height'] != null ? int.parse(json['height']) : null;
    duration = json['duration'] != null ? int.parse(json['duration']) : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'type': type,
        'url': url,
        'content-type': contentType,
        'size': size,
        'name': name,
        'data': data,
        'width': width,
        'height': height,
        'duration': duration
      };

  @override
  toString() => toJson().toString();
}

class CubeAttachmentType {
  static const String AUDIO_TYPE = "audio";
  static const String VIDEO_TYPE = "video";
  static const String IMAGE_TYPE = "image";
  static const String LOCATION_TYPE = "location";
}
