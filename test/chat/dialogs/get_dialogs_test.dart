import 'package:connectycube_sdk/connectycube_chat.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chat_test_utils.dart';

Future<void> main() async {

  setUpAll(beforeTestPreparations);

  group("Tests GET dialogs", () {
    test("testGetByDate", () async {
      String groupName = 'New GROUP chat';
      String groupDescription = 'Test dialog';
      List<int> occupantsIds = [config['user_1_id'], config['user_2_id'], config['user_3_id']];

      CubeDialog newDialog = CubeDialog(CubeDialogType.GROUP);
      newDialog.name = groupName;
      newDialog.description = groupDescription;
      newDialog.occupantsIds = occupantsIds;

      CubeDialog createdDialog = await createDialog(newDialog);

      DateTime now = DateTime.now();

      now = now.subtract(Duration(minutes: 10));

      Map<String, dynamic> additionalParams = {
        "created_at[gt]": now.millisecondsSinceEpoch/1000
      };

      await getDialogs(additionalParams).then((dialogs) async {
        logTime("Success GET_DIALOGS: $dialogs");
        assert(dialogs != null);
        assert(dialogs.items.isNotEmpty);

        assert(-1 != dialogs.items.indexWhere((dialog) => dialog.dialogId == createdDialog.dialogId));
      }).catchError((onError) async {
        logTime("Error GET_DIALOGS");
        assert(onError == null);
      }).whenComplete(() => deleteDialog(createdDialog.dialogId, true));
    });
  });

  tearDownAll(deleteSession);
}