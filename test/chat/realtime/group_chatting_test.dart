import 'package:connectycube_sdk/connectycube_chat.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chat_test_utils.dart';

Future<void> main() async {
  setUpAll(beforeTestPreparations);

  group("Tests GROUP chatting", () {
    test("testSendEmptyMessage", () async {
      String groupName = 'New GROUP chat 3======';
      String groupDescription = 'Test dialog';
      List<int> occupantsIds = [
        config['user_1_id'],
        config['user_2_id'],
        config['user_3_id']
      ];

      CubeDialog newDialog = CubeDialog(CubeDialogType.GROUP);
      newDialog.name = groupName;
      newDialog.description = groupDescription;
      newDialog.occupantsIds = occupantsIds;

      CubeDialog createdDialog = await createDialog(newDialog);

      await CubeChatConnection.instance.login(
          CubeUser(id: config["user_1_id"], password: config["user_1_pass"]));

      CubeMessage message = CubeMessage()
        // ..body = 'Body'
        ..saveToHistory = true
        ..dialogId = createdDialog.dialogId
        ..properties = {
          'papam1': 'value1',
          'papam2': 'value2',
        };

      CubeSettings.instance.isJoinEnabled = false;
      await createdDialog.sendMessage(message).then((sentMessage) async {
        logTime("Success SENT MESSAGE: ${sentMessage.messageId}");
      }).catchError((onError) async {
        logTime("Error SENT MESSAGE");
        assert(onError == null);
      }).whenComplete(() {
        CubeChatConnection.instance.destroy();
        // deleteDialog(createdDialog.dialogId, true);
      });
    });
  });

  tearDownAll(deleteSession);
}
