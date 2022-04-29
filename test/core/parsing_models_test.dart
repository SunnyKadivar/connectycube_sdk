import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:connectycube_sdk/connectycube_core.dart';

import 'core_test_utils.dart';

Future<void> main() async {
  await initCubeFramework();

  group("Tests SERIALIZATION/DESERIALIZATION MODELS", () {
    test("testSessionSerialization", () async {
      await createTestSession();

      try {
        CubeSession session = CubeSessionManager.instance.activeSession;
        logTime("session before serialization: ${session.toString()}");

        String serializedSession = jsonEncode(session);
        logTime("serialized session: $serializedSession");

        CubeSession deserializedSession =
            CubeSession.fromJson(jsonDecode(serializedSession));
        logTime("session after serialization: ${deserializedSession.toString()}");

        assert(session.toString() == deserializedSession.toString());
      } catch (error) {
        assert(false);
      } finally {
        await deleteSession(CubeSessionManager.instance.activeSession.id);
      }
    });
  });
}
