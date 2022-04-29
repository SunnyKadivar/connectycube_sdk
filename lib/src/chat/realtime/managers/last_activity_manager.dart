import 'dart:async';

import 'package:xmpp_stone/xmpp_stone.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';

import 'base_managers.dart';
import '../extentions.dart';
import '../../chat_connection_service.dart';
import '../../realtime/utils/jid_utils.dart';

class LastActivityManager extends Manager {
  static Map<Connection, LastActivityManager> _instances = Map();

  LastActivityManager._private(Connection connection) : super(connection);

  static getInstance(Connection connection) {
    LastActivityManager manager = _instances[connection];
    if (manager == null) {
      manager = LastActivityManager._private(connection);
      _instances[connection] = manager;
    }

    return manager;
  }

  Future<int> getLastActivity(int userId) {
    Completer completer = Completer<int>();

    String id = AbstractStanza.getRandomId();
    Jid toJid = Jid.fromFullJid(getJidForUser(userId));
    LastActivityQuery lastActivityQuery = LastActivityQuery();

    IqStanza lastActivityStanza = IqStanza(id, IqStanzaType.GET);
    lastActivityStanza.toJid = toJid;
    lastActivityStanza.addChild(lastActivityQuery);

    CubeChatConnection.instance.asyncStanzaSender?.sendAsync(lastActivityStanza,
        (resultStanza, exception) {
      if (resultStanza == null) {
        completer.completeError(exception);
      } else {
        LastActivityQuery response = LastActivityQuery.fromStanza(
            resultStanza.getChild(LastActivityQuery.ELEMENT_NAME));
        int seconds = response.getSeconds();
        completer.complete(seconds);
      }
    });

    return completer.future;
  }

  @override
  void destroy() {
    _instances.remove(connection);
  }
}
