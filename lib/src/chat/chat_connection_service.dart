import 'dart:async';

import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'package:xmpp_stone/src/features/ConnectionNegotatiorManager.dart';

import '../../connectycube_core.dart';

import 'chat_exceptions.dart';
import 'realtime/managers/base_managers.dart';
import 'realtime/managers/chat_managers.dart';
import 'realtime/managers/chat_messages_manager.dart';
import 'realtime/managers/global_messages_manager.dart';
import 'realtime/managers/last_activity_manager.dart';
import 'realtime/managers/messages_statuses_manager.dart';
import 'realtime/managers/rtc_signaling_manager.dart';
import 'realtime/managers/system_messages_manager.dart';
import 'realtime/managers/typing_statuses_manager.dart';
import 'realtime/utils/async_stanza_sender.dart';
import 'realtime/utils/jid_utils.dart';

class CubeChatConnection {
  static final CubeChatConnection _singleton = CubeChatConnection._internal();

  CubeChatConnection._internal();

  static CubeChatConnection get instance => _singleton;

  // ignore: non_constant_identifier_names
  static final String TAG = "CubeChatConnection";

  CubeUser _currentUser;

  CubeUser get currentUser => _currentUser;

  StreamSubscription<xmpp.XmppConnectionState> _chatLoginStateSubscription;

  PrivateChatManager _privateChatManager;
  GroupChatManager _groupChatManager;
  ChatMessagesManager _chatMessagesManager;
  GlobalMessagesManager _globalMessagesManager;
  SystemMessagesManager _systemMessagesManager;
  MessagesStatusesManager _messagesStatusesManager;
  TypingStatusesManager _typingStatusesManager;
  LastActivityManager _lastActivityManager;
  RTCSignalingManager _rtcSignalingManager;
  AsyncStanzaSender _asyncStanzaSender;

  xmpp.Connection _connection;

  xmpp.RosterManager _rosterManager;
  xmpp.MessageHandler _messageHandler;
  xmpp.PresenceManager _presenceManager;
  xmpp.VCardManager _vCardManager;

  CubeChatConnectionState _chatConnectionState = CubeChatConnectionState.Idle;

  CubeChatConnectionState get chatConnectionState => _chatConnectionState;

  StreamController<CubeChatConnectionState> _connectionStateStreamController =
      StreamController.broadcast();

  Stream<CubeChatConnectionState> get connectionStateStream {
    return _connectionStateStreamController.stream;
  }

  Future<CubeUser> login(CubeUser cubeUser, {String resourceId}) async {
    Completer completer = Completer<CubeUser>();

    String resource = isEmpty(resourceId)
        ? CubeSettings.instance.chatDefaultResource
        : resourceId;
    String userJid = getJidForUser(cubeUser.id, resource);

    xmpp.Jid jid = xmpp.Jid.fromFullJid(userJid);
    xmpp.XmppAccountSettings account = xmpp.XmppAccountSettings(
        userJid, jid.local, jid.domain, cubeUser.password, 5222,
        resource: resource);
    account.reconnectionTimeout =
        CubeChatConnectionSettings.instance.reconnectionTimeout;
    account.totalReconnections =
        CubeChatConnectionSettings.instance.totalReconnections;

    _connection = xmpp.Connection.getInstance(account);
    // replace user data for case when used the same user with different passwords
    _connection.account = account;
    _connection.connectionNegotatiorManager = ConnectionNegotiatorManager(_connection, account);

    _chatLoginStateSubscription =
        _connection.connectionStateStream.listen((state) {
      _onConnectionStateChangedInternal(state, completer, cubeUser);
    });

    _connection.connect();

    return completer.future;
  }

  void _initCurrentUser(CubeUser cubeUser) {
    _currentUser = cubeUser;
  }

  void _initGlobalMessagesManager(xmpp.Connection connection) {
    _globalMessagesManager = GlobalMessagesManager.getInstance(connection);
  }

  void _initRosterManager(xmpp.Connection connection) {
    _rosterManager = xmpp.RosterManager.getInstance(connection);

//    _rosterManager.addRosterItem(xmpp.Buddy(receiverJid)).then((result) {
//      if (result.description != null) {
//        print("add roster" + result.description);
//      }
//    });
  }

  void _initPresenceManager(xmpp.Connection connection) {
    _presenceManager = xmpp.PresenceManager.getInstance(connection);
    _presenceManager.subscriptionStream.listen((streamEvent) {
//      if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
//        print("Accepting presence request");
//        presenceManager.acceptSubscription(streamEvent.jid);
//      }
    });
  }

  void _initVCardManager(xmpp.Connection connection) {
    _vCardManager = xmpp.VCardManager(connection);
//    _vCardManager.getSelfVCard().then((vCard) {
//      if (vCard != null) {
//        print("Your info" + vCard.buildXmlString());
//      }
//    });

//    _vCardManager.getVCardFor(receiverJid).then((vCard) {
//      if (vCard != null) {
//        print("Receiver info" + vCard.buildXmlString());
//        if (vCard != null && vCard.image != null) {
////            var file = File('test456789.jpg')
////              ..writeAsBytesSync(image.encodeJpg(vCard.image));
////            print("IMAGE SAVED TO: ${file.path}");
//        }
//      }
//    });
  }

  void _onConnectionStateChangedInternal(xmpp.XmppConnectionState state,
      Completer<CubeUser> completer, CubeUser cubeUser) {
    switch (state) {
      case xmpp.XmppConnectionState.Idle:
        log("Chat connection Idle", TAG);
        _setConnectionState(CubeChatConnectionState.Idle);
        break;
      case xmpp.XmppConnectionState.Closed:
        log("Chat connection Closed", TAG);
        _setConnectionState(CubeChatConnectionState.Closed);
        break;
      case xmpp.XmppConnectionState.SocketOpening:
        log("Chat connection SocketOpening", TAG);
        break;
      case xmpp.XmppConnectionState.SocketOpened:
        log("Chat connection SocketOpened", TAG);
        break;
      case xmpp.XmppConnectionState.DoneParsingFeatures:
        log("Chat connection DoneParsingFeatures", TAG);
        break;
      case xmpp.XmppConnectionState.StartTlsFailed:
        log("Chat connection StartTlsFailed", TAG);
        _setConnectionState(CubeChatConnectionState.AuthenticationFailure);
        _notifyChatLoginError(
            completer,
            ChatConnectionException(
                message: "Open connection error: StartTlsFailed"));

        break;
      case xmpp.XmppConnectionState.AuthenticationNotSupported:
        log("Chat connection AuthenticationNotSupported", TAG);
        _setConnectionState(CubeChatConnectionState.AuthenticationFailure);
        _notifyChatLoginError(
            completer,
            ChatConnectionException(
                message: "Open connection error: AuthenticationNotSupported"));

        break;
      case xmpp.XmppConnectionState.PlainAuthentication:
        log("Chat connection PlainAuthentication", TAG);
        break;
      case xmpp.XmppConnectionState.Authenticating:
        log("Chat connection Authenticating", TAG);
        break;
      case xmpp.XmppConnectionState.Authenticated:
        log("Chat connection Authenticated", TAG);
        _setConnectionState(CubeChatConnectionState.Authenticated);

        break;
      case xmpp.XmppConnectionState.AuthenticationFailure:
        log("Chat connection AuthenticationFailure", TAG);
        _setConnectionState(CubeChatConnectionState.AuthenticationFailure);

        _notifyChatLoginError(
            completer,
            ChatConnectionException(
                message: "Open connection error: AuthenticationFailure"));

        break;
      case xmpp.XmppConnectionState.Resumed:
        log("Chat connection Resumed", TAG);
        _setConnectionState(CubeChatConnectionState.Resumed);
        break;
      case xmpp.XmppConnectionState.SessionInitialized:
        log("Chat connection SessionInitialized", TAG);
        break;
      case xmpp.XmppConnectionState.Ready:
        log("Chat connection Ready", TAG);

        _initCurrentUser(cubeUser);
        _initGlobalMessagesManager(_connection);
        _initRosterManager(_connection);
        _initPresenceManager(_connection);
        _initVCardManager(_connection);

        if (!completer.isCompleted) {
          completer.complete(cubeUser);
        }

        _setConnectionState(CubeChatConnectionState.Ready);

        break;
      case xmpp.XmppConnectionState.Closing:
        log("Chat connection Closing", TAG);
        break;
      case xmpp.XmppConnectionState.Closed:
        _setConnectionState(CubeChatConnectionState.ForceClosed);
        log("Chat connection ForcefullyClosed", TAG);
        _notifyChatLoginError(
            completer,
            ChatConnectionException(
                message: "Open connection error: ForcefullyClosed"));

        break;
      case xmpp.XmppConnectionState.Reconnecting:
        _setConnectionState(CubeChatConnectionState.Reconnecting);
        log("Chat connection Reconnecting", TAG);
        break;
      case xmpp.XmppConnectionState.WouldLikeToOpen:
        log("Chat connection WouldLikeToOpen", TAG);
        break;
      case xmpp.XmppConnectionState.WouldLikeToClose:
        log("Chat connection WouldLikeToClose", TAG);
        break;
      default:
    }
  }

  _setConnectionState(CubeChatConnectionState state) {
    if (_chatConnectionState != state) {
      _chatConnectionState = state;
      _connectionStateStreamController.add(state);
    }
  }

  _notifyChatLoginError(
      Completer completer, Exception chatConnectionException) {
    if (!completer.isCompleted) {
      completer.completeError(chatConnectionException);
    }
  }

  relogin() {
    if (currentUser == null) {
      throw IllegalStateException(
          "Call 'login(cubeUser)' first before use 'relogin()'");
    }

    if (_connection.state == xmpp.XmppConnectionState.Reconnecting) return;

    if (_connection.state == xmpp.XmppConnectionState.Closed) {
      _connection.reconnect();
    } else if (_connection.state == xmpp.XmppConnectionState.Closed) {
      _setConnectionState(CubeChatConnectionState.Reconnecting);

      login(currentUser);
    }
  }

  logout() {
    _chatLoginStateSubscription?.cancel();
    _chatLoginStateSubscription = null;
    _connection.close();
  }

  destroy() {
    logout();

    _connection = null;

    _currentUser = null;

    _destroyManager(_globalMessagesManager);

    _rosterManager = null;
    _messageHandler = null;
    _presenceManager = null;
    _vCardManager = null;

    _closeManagerStreams(_privateChatManager);
    _closeManagerStreams(_groupChatManager);
    _closeManagerStreams(_chatMessagesManager);
    _closeManagerStreams(_systemMessagesManager);
    _closeManagerStreams(_messagesStatusesManager);
    _closeManagerStreams(_typingStatusesManager);
    _closeManagerStreams(_rtcSignalingManager);

    _destroyManager(_privateChatManager);
    _destroyManager(_groupChatManager);
    _destroyManager(_chatMessagesManager);
    _destroyManager(_systemMessagesManager);
    _destroyManager(_messagesStatusesManager);
    _destroyManager(_typingStatusesManager);
    _destroyManager(_rtcSignalingManager);
    _destroyManager(_asyncStanzaSender);
  }

  bool isAuthenticated() {
    return _connection != null && _connection.authenticated;
  }

  Future<int> getLasUserActivity(int userId) {
    Completer completer = Completer<int>();

    if (isAuthenticated()) {
      _lastActivityManager = LastActivityManager.getInstance(_connection);
    }

    if (_lastActivityManager == null) {
      completer.completeError(ChatConnectionException(
          message:
              "Something went wrong, check login to the chat and try again"));
      return completer.future;
    }

    _lastActivityManager.getLastActivity(userId).then((seconds) {
      completer.complete(seconds);
    }).catchError((onError) => completer.completeError(onError));

    return completer.future;
  }

  /// Useful only for SDK needs
  get globalMessagesManager {
    return _globalMessagesManager;
  }

  get systemMessagesManager {
    if (isAuthenticated()) {
      _systemMessagesManager = SystemMessagesManager.getInstance(_connection);
    }

    return _systemMessagesManager;
  }

  get privateChatManager {
    if (isAuthenticated()) {
      _privateChatManager = PrivateChatManager.getInstance(_connection);
    }

    return _privateChatManager;
  }

  get groupChatManager {
    if (isAuthenticated()) {
      _groupChatManager = GroupChatManager.getInstance(_connection);
    }

    return _groupChatManager;
  }

  get chatMessagesManager {
    if (isAuthenticated()) {
      _chatMessagesManager = ChatMessagesManager.getInstance(_connection);
    }

    return _chatMessagesManager;
  }

  get messagesStatusesManager {
    if (isAuthenticated()) {
      _messagesStatusesManager =
          MessagesStatusesManager.getInstance(_connection);
    }

    return _messagesStatusesManager;
  }

  get typingStatusesManager {
    if (isAuthenticated()) {
      _typingStatusesManager = TypingStatusesManager.getInstance(_connection);
    }

    return _typingStatusesManager;
  }

  get rtcSignalingManager {
    if (isAuthenticated()) {
      _rtcSignalingManager = RTCSignalingManager.getInstance(_connection);
    }

    return _rtcSignalingManager;
  }

  get asyncStanzaSender {
    if (isAuthenticated()) {
      _asyncStanzaSender = AsyncStanzaSender.getInstance(_connection);
    }

    return _asyncStanzaSender;
  }

  void _closeManagerStreams(StreamedManager manager) {
    manager?.closeStreams();
  }

  void _destroyManager(Manager manager) {
    manager?.destroy();
    manager = null;
  }
}

class CubeChatConnectionSettings {
  static final CubeChatConnectionSettings _singleton =
      CubeChatConnectionSettings._internal();

  CubeChatConnectionSettings._internal();

  static CubeChatConnectionSettings get instance => _singleton;

  int totalReconnections = 3;
  int reconnectionTimeout = 5000;
}

enum CubeChatConnectionState {
  Idle,
  Authenticated,
  AuthenticationFailure,
  Reconnecting,
  Resumed,
  Ready,
  ForceClosed,
  Closed
}
