import 'package:flutter_test/flutter_test.dart';

import 'package:connectycube_sdk/connectycube_core.dart';

import 'core_test_utils.dart';

Future<void> main() async {
  setUpAll(initCubeFramework);

  group("Tests AUTH", () {
    test("testSignInAnotherUserSession", () async {
      await createTestSession();

      await signIn(CubeUser(
              login: config['user_2_login'], password: config['user_2_pass']))
          .then((cubeUser) async {
        assert(cubeUser != null);
        assert(cubeUser.login == config['user_2_login']);
        assert(
            cubeUser.id == CubeSessionManager.instance.activeSession.user.id);
      }).catchError((onError) {
        logTime(onError.toString());
        assert(onError == null);
      });
    });

    test("testSignUpUser", () async {
      // await createSession();
      int createdUserId;

      int currentTime = DateTime.now().millisecondsSinceEpoch;
      CubeUser newUser = CubeUser()
        ..login = currentTime.toString()
        ..password = "test_pass"
        ..phone = "$currentTime"
        ..avatar = "https://admin2.connectycube.com/avatar.jpg"
        ..email = "$currentTime@gmail.com"
        ..fullName = "Test User"
        ..tags = {"tag1", "tag2"}
        ..website = "https://admin2.connectycube.com"
        ..facebookId = "$currentTime"
        // ..externalId = 1234567
        ..twitterId = "$currentTime";

      try {
        CubeUser createdUser = await signUp(newUser);
        assert(createdUser != null);
        assert(createdUser.id != null);

        createdUserId = createdUser.id;

        assert(createdUser.login == newUser.login);
        assert(createdUser.phone == newUser.phone);
        assert(createdUser.avatar == newUser.avatar);
        assert(createdUser.email == newUser.email);
        assert(createdUser.fullName == newUser.fullName);
        assert(createdUser.website == newUser.website);
        assert(createdUser.facebookId == newUser.facebookId);
        assert(createdUser.twitterId == newUser.twitterId);
        // assert(createdUser.externalId == newUser.externalId);
        assert(createdUser.tags?.containsAll(newUser.tags) ?? false);
      } finally {
        if (createdUserId != null) {
          await createSession(newUser);
          await deleteUser(createdUserId);
        }
      }
    });
  });

  tearDown(deleteSession);
}
