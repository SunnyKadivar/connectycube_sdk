import 'dart:async';
import 'dart:io';

import 'package:connectycube_sdk/connectycube_calls.dart';
import 'package:connectycube_sdk/connectycube_core.dart';
import 'package:connectycube_sdk/src/calls/conference/conference_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/io.dart';

Future<void> createSession() {
  ConferenceConfig.instance.url = "wss://janus.connectycube.com:8989";

  Completer completer = Completer<void>();
  var client = ConferenceClient.instance;
  client.createCallSession(500).then((session) {
    logTime("createSession OK");
    session.disposeSession();
    completer.complete();
  }).catchError((onError) {
    logTime("createSession onError= $onError");
    completer.completeError(onError);
  });
  return completer.future;
}

void main() {
  ConferenceConfig.instance.url = "";
  group('Tests CONFERENCE connection', () {
    test('createSession', () async {
      await createSession().then((value) {
        assert(true);
      }).catchError((onError) {
        assert(onError == null);
      });
    });

    test('WS connection', () async {
      await connect().then((value) {
        assert(true);
      }).catchError((onError) {
        assert(onError == null);
      });
    });
  });
}

Future<void> connect() {
  Completer completer = Completer<void>();
  var channel = IOWebSocketChannel.connect('ws://echo.websocket.org');
  channel.sink.add("connected!");
  channel.stream.listen((message) async {
    logTime("Connection onMessage message= ${message}");
    await channel.sink.close();
    completer.complete();
  }, onError: (err) {
    logTime("Connection onError err= ${err}");
    completer.completeError(err);
  });
  return completer.future;
}
