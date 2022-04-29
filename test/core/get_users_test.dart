import 'package:flutter_test/flutter_test.dart';

import 'package:connectycube_sdk/connectycube_core.dart';

import 'core_test_utils.dart';

Future<void> main() async {
  setUpAll(initCubeFramework);
  setUp(createTestSession);

  group("Tests GET USERS", () {
    test("testGetUserByID", () async {
      await getUserById(config['user_2_id']).then((cubeUser) async {
        assert(cubeUser != null);
        assert(cubeUser.login == config['user_2_login']);
        assert(cubeUser.id == config['user_2_id']);
      }).catchError((onError) {
        logTime(onError.toString());
        assert(onError == null);
      });
    });

    test("testGetUserByLOGIN", () async {
      await getUserByLogin(config['user_2_login']).then((cubeUser) async {
        assert(cubeUser != null);
        assert(cubeUser.login == config['user_2_login']);
        assert(cubeUser.id == config['user_2_id']);
      }).catchError((onError) {
        logTime(onError.toString());
        assert(onError == null);
      });
    });
  });

  tearDown(deleteSession);
}
