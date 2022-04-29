import 'package:flutter_test/flutter_test.dart';

import 'package:connectycube_sdk/connectycube_core.dart';
import 'package:connectycube_sdk/connectycube_custom_objects.dart';

import '../custom_objects/custom_object_test_class.dart';
import 'core_test_utils.dart';


Future<void> main() async {
  await initCubeFramework();

  group("Tests SESSION AUTO MANAGEMENT", () {
    test("testAutoCreateEmptySession", () async {
      await signIn(CubeUser(login: "flutter_sdk_tests_user", password: "flutter_sdk_tests_user")).then((cubeUser) async {
        assert(cubeUser != null);

        await deleteSession(CubeSessionManager.instance.activeSession.id);
      }).catchError((onError) {
        logTime(onError.toString());
        assert(onError == null);
      });
    });

    test("testUseUsersSession", () async {
      CubeSettings.instance.onSessionRestore = () => createTestSession();

      await getCustomObjectsByClassName(testClassName).then((result) async {
        assert(result != null);

        await deleteSession(CubeSessionManager.instance.activeSession.id);
      }).catchError((onError) {
        logTime(onError.toString());
        assert(onError == null);
      });
    });
  });
}

