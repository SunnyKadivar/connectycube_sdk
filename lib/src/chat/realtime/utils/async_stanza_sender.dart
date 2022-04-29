import 'dart:async';

import 'package:xmpp_stone/xmpp_stone.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

import '../../../../connectycube_core.dart';

import '../../chat_exceptions.dart';
import '../../models/cube_error_packet.dart';
import '../../realtime/managers/base_managers.dart';

class AsyncStanzaSender extends Manager {
  static const int DEFAULT_SOCKET_TIMEOUT = 60;
  static Map<Connection, AsyncStanzaSender> _instances = Map();
  static Map<String, Timer> _timers = Map();
  static Map<String, Function> _tasks = Map();
  StreamSubscription _subscription;

  AsyncStanzaSender._private(Connection connection) : super(connection);

  static getInstance(Connection connection) {
    AsyncStanzaSender manager = _instances[connection];
    if (manager == null) {
      manager = AsyncStanzaSender._private(connection);
      _instances[connection] = manager;
    }

    return manager;
  }

  void sendAsync<S extends AbstractStanza>(S stanza, Function func) {
    String outId = stanza.id;

    log("add new task $outId", "AsyncStanzaSender");
    _tasks[outId] = func;
    _timers[outId] = _startTimeout(DEFAULT_SOCKET_TIMEOUT, outId);

    if (_subscription == null) {
      _subscription = connection.inStanzasStream.listen((responseStanza) {
        log("responseStanza ${responseStanza.id}", "AsyncStanzaSender");
        String inId = responseStanza.id;
        if (!_tasks.containsKey(inId)) return;
        log("run task $inId", "AsyncStanzaSender");
        _timers[inId].cancel();
        _timers.remove(inId);

        Function function = _tasks[inId];
        if (function == null) return;
        _tasks.remove(inId);

        XmppAttribute type = responseStanza.getAttribute("type");
        if (type != null) {
          if ('error' == type.value) {
            function.call(
                null,
                ChatConnectionException(
                    error: ErrorPacket.fromStanza(
                        responseStanza.getChild('error'))));
          } else {
            function.call(responseStanza, null);
          }
        } else {
          function.call(responseStanza, null);
        }

        if (_tasks.isEmpty) {
          log("pause subscription", "AsyncStanzaSender");
          _subscription.pause();
        }
      });
    } else {
      if (_subscription.isPaused) {
        log("unpause subscription", "AsyncStanzaSender");
        _subscription.resume();
      }
    }

    connection.writeStanza(stanza);
  }

  _startTimeout(int seconds, String timerId) {
    log("start timer $timerId", "AsyncStanzaSender");
    return Timer(Duration(seconds: seconds), () => _handleTimeout(timerId));
  }

  void _handleTimeout(String timerId) {
    log("remove task by timer $timerId", "AsyncStanzaSender");
    _timers.remove(timerId);
    Function function = _tasks[timerId];
    if (function == null) return;
    _tasks.remove(timerId);

    function.call(
        null,
        ChatConnectionException(
            message: 'Connection timeout was occured durins end packet'));

    if (_tasks.isEmpty) {
      log("pause subscription by timeout", "AsyncStanzaSender");
      _subscription.pause();
    }
  }

  @override
  void destroy() {
    _subscription.cancel();

    _timers.forEach((key, entry) {
      entry.cancel();
    });
    _timers.clear();

    _tasks.clear();

    _instances.remove(connection);
  }
}
