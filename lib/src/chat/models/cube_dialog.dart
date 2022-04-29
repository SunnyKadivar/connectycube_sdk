import 'dart:async';

import '../../../connectycube_core.dart';
import '../../../connectycube_custom_objects.dart';

import 'cube_message.dart';
import '../chat_connection_service.dart';
import '../realtime/managers/chat_managers.dart';

class CubeDialog extends CubeEntity {
  String dialogId;
  String lastMessage;
  int lastMessageDateSent;
  int lastMessageUserId;
  String photo;
  int userId;
  String roomJid;
  int unreadMessageCount;
  String name;
  List<int> occupantsIds;
  List<String> pinnedMessagesIds;
  int type;
  List<int> adminsIds;
  CubeDialogCustomData customData;
  String description;
  int occupantsCount;

  AbstractChat currentChat;
  CubeDialog(this.type,
      {this.dialogId,
      this.name,
      this.description,
      this.occupantsIds,
      this.photo,
      this.pinnedMessagesIds,
      this.adminsIds,
      this.customData});

  CubeDialog.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    dialogId = json['_id'];
    lastMessage = json['last_message'];
    lastMessageDateSent = json['last_message_date_sent'];
    lastMessageUserId = json['last_message_user_id'];
    photo = json['photo'];
    userId = json['user_id'];
    roomJid = json['xmpp_room_jid'];
    unreadMessageCount = json['unread_messages_count'];
    name = json['name'];
    type = json['type'];
    description = json['description'];
    occupantsCount = json['occupants_count'];

    var occupantsIdsRaw = json['occupants_ids'];
    if (occupantsIdsRaw != null) {
      occupantsIds = List.of(occupantsIdsRaw).map((id) => id as int).toList();
    }

    var pinnedMessagesIdsRaw = json['pinned_messages_ids'];
    if (pinnedMessagesIdsRaw != null) {
      pinnedMessagesIds =
          List.of(pinnedMessagesIdsRaw).map((id) => id.toString()).toList();
    }

    var adminsIdsRaw = json['admins_ids'];
    if (adminsIdsRaw != null) {
      adminsIds = List.of(adminsIdsRaw).map((id) => id as int).toList();
    }

    var customDataRaw = json['data'];
    if (customDataRaw != null) {
      customData = CubeDialogCustomData.fromJson(customDataRaw);
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      '_id': dialogId,
      'last_message': lastMessage,
      'last_message_date_sent': lastMessageDateSent,
      'last_message_user_id': lastMessageUserId,
      'photo': photo,
      'user_id': userId,
      'xmpp_room_jid': roomJid,
      'unread_messages_count': unreadMessageCount,
      'name': name,
      'type': type,
      'description': description,
      'occupants_count': occupantsCount,
      'occupants_ids': occupantsIds,
      'pinned_messages_ids': pinnedMessagesIds,
      'admins_ids': adminsIds,
      'data': customData
    };

    json.addAll(super.toJson());

    return json;
  }

  @override
  toString() => toJson().toString();

  int getRecipientId() {
    if (CubeDialogType.PRIVATE != type || isEmptyList(occupantsIds)) {
      return -1;
    }

    CubeChatConnection chatConnection = CubeChatConnection.instance;

    if (chatConnection.currentUser == null) return -1;

    for (int occupantId in occupantsIds) {
      if (occupantId != chatConnection.currentUser.id) return occupantId;
    }

    return -1;
  }

  Future<void> sendText(String text) {
    CubeMessage message = CubeMessage();
    message.body = text;

    return sendMessage(message);
  }

  Future<CubeMessage> sendMessage(CubeMessage message) {
    Completer completer = Completer<CubeMessage>();

    checkInit().then((chat) {
      message.dialogId = dialogId;
      completer.complete(chat.sendMessage(message));
    }).catchError((onError) {
      completer.completeError(onError);
    });

    return completer.future;
  }

  Future<void> deliverMessage(CubeMessage message) {
    Completer completer = Completer<void>();

    checkInit().then((chat) {
      message.dialogId = dialogId;
      chat.deliverMessage(message);
      completer.complete();
    }).catchError((onError) {
      completer.completeError(onError);
    });

    return completer.future;
  }

  Future<void> readMessage(CubeMessage message) {
    Completer completer = Completer<void>();

    checkInit().then((chat) {
      message.dialogId = dialogId;
      chat.readMessage(message);
      completer.complete();
    }).catchError((onError) {
      completer.completeError(onError);
    });

    return completer.future;
  }

  void sendIsTypingStatus() {
    checkInit().then((chat) {
      chat.sendIsTypingNotification();
    });
  }

  void sendStopTypingStatus() {
    checkInit().then((chat) {
      chat.sendStopTypingNotification();
    });
  }

  Future<AbstractChat> checkInit() {
    Completer completer = Completer<AbstractChat>();

    if (currentChat != null) {
      completer.complete(currentChat);
      return completer.future;
    }

    if (CubeDialogType.PRIVATE == type) {
      int recipientId = getRecipientId();
      if (recipientId == -1)
        completer.completeError(IllegalStateException(
            "Check you set participant and login to the chat"));

      PrivateChatManager privateChatManager =
          CubeChatConnection.instance.privateChatManager;
      if (privateChatManager == null)
        completer.completeError(IllegalStateException(
            "Need login to the chat before perform chat related operations"));

      PrivateChat privateChat = privateChatManager.getChat(recipientId);

      currentChat = privateChat;

      completer.complete(privateChat);
    } else {
      if (isEmpty(dialogId))
        completer.completeError(IllegalStateException(
            "'dialog_id' can't be empty or null for this dialog type"));

      GroupChatManager groupChatManager =
          CubeChatConnection.instance.groupChatManager;
      if (groupChatManager == null)
        completer.completeError(IllegalStateException(
            "Need login to the chat before perform chat related operations"));

      GroupChat groupChat = groupChatManager.getChat(dialogId);

      if (CubeSettings.instance.isJoinEnabled) {
        _joinInternal(groupChat).then((groupChat) {
          currentChat = groupChat;
          completer.complete(groupChat);
        }).catchError((error) => completer.completeError(error));
      } else {
        completer.complete(groupChat);
      }
    }

    return completer.future;
  }

  Future<GroupChat> _joinInternal(GroupChat groupChat) {
    Completer completer = Completer<GroupChat>();

    if (CubeDialogType.PRIVATE == type) {
      completer.completeError(
          IllegalStateException('Unavailable operation for \'PRIVATE\' chat'));
    } else {
      groupChat.join().then((groupChat) {
        completer.complete(groupChat);
      }).catchError((error) => completer.completeError(error));
    }

    return completer.future;
  }

  Future<CubeDialog> join() {
    Completer completer = Completer<CubeDialog>();

    checkInit().then((currentChat) {
      completer.complete(this);
    }).catchError((error) => completer.completeError(error));

    return completer.future;
  }

  Future<void> leave() {
    Completer completer = Completer();

    if (CubeDialogType.PRIVATE == type) {
      completer.complete(null);
    } else {
      (currentChat as GroupChat).leave().then((result) {
        completer.complete((null));
      }).catchError((onError) => completer.completeError(onError));
    }

    return completer.future;
  }
}

class CubeDialogType {
  static const int BROADCAST = 1;
  static const int GROUP = 2;
  static const int PRIVATE = 3;
  static const int PUBLIC = 4;
}

class CubeDialogCustomData extends CubeBaseCustomObject {
  CubeDialogCustomData(String className) : super(className);

  CubeDialogCustomData.fromJson(Map<String, dynamic> json)
      : super.fromJson(json);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['class_name'] = className;

    return json;
  }

  @override
  toString() => toJson().toString();
}
