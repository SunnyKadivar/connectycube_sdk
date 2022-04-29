import 'package:connectycube_sdk/connectycube_chat.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chat_test_utils.dart';

Future<void> main() async {
  await beforeTestPreparations();

  group("Tests CREATE dialogs", () {
    test("testCreateGroup", () async {
      String groupName = 'New GROUP chat';
      String groupDescription = 'Test dialog';
      List<int> occupantsIds = [config['user_1_id'], config['user_2_id'], config['user_3_id']];
      int integerData = 65432;
      String stringData = 'custom string';
      CubeDialogCustomData data = CubeDialogCustomData('TestDialogCustom');
      data.fields = {'integer': integerData, 'string': stringData};

      CubeDialog newDialog = CubeDialog(CubeDialogType.GROUP);
      newDialog.name = groupName;
      newDialog.description = groupDescription;
      newDialog.occupantsIds = occupantsIds;
      newDialog.customData = data;

      await createDialog(newDialog).then((createdDialog) async {
        logTime("Success CREATE_GROUP");
        assert(createdDialog != null);
        assert(createdDialog.name == groupName);
        assert(createdDialog.description == groupDescription);
        occupantsIds.forEach((userId) {
          assert(createdDialog.occupantsIds.contains(userId));
        });

        assert(createdDialog.customData != null);

        TestDialogCustom data =
            TestDialogCustom.fromJson(createdDialog.customData.fields);

        assert(data.integer == integerData);
        assert(data.string == stringData);

        await deleteDialog(createdDialog.dialogId, true);
      }).catchError((onError) {
        logTime("Error CREATE_GROUP");
        assert(onError == null);
      });
    });
  });
}

class TestDialogCustom {
  int integer;
  String string;

  TestDialogCustom.fromJson(Map<String, dynamic> json) {
    this.integer = json['integer'];
    this.string = json['string'];
  }

  Map<String, dynamic> toJson() => {
        'integer': integer,
        'string': string,
      };

  @override
  toString() => toJson().toString();
}
