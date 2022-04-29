import 'package:connectycube_sdk/connectycube_pushnotifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'push_notifications_test_utils.dart';

Future<void> main() async {
  setUpAll(initCubeFramework);


  group("Tests CREATE events", () {
    test("testCreateEvent", () async {
      await createTestSession();

      CreateEventParams params = CreateEventParams();
      params.parameters = {
        'ios_voip': 0,
        'message': "Test message", // Change this to a name
        'dialog_id': "erhfehfbjbjwvjnw-vdws",
        'isVideo': true,
        'callerId': config['user_1_id'],
      };

      params.notificationType = NotificationType.PUSH;
      params.environment = CubeEnvironment.DEVELOPMENT;
      params.usersIds = [
        317688,
        893225,
        1898894,
        config['user_3_id']
      ];

      await createEvent(params.getEventForRequest()).then((cubeEvent) {
        log("Event sent successfully.", "CCM:createEvent:success:");
      }).catchError((error) {
        log("Error sending event.", "CCM:createEvent:error:");
      });
    });
  });
}
