import 'package:connectycube_sdk/connectycube_core.dart';
import 'package:connectycube_sdk/connectycube_custom_objects.dart';
import 'package:flutter_test/flutter_test.dart';

import 'custom_object_test_class.dart';
import 'custom_objects_test_utils.dart';

Future<void> main() async {
  await beforeTestPreparations();

  group("Tests DELETE custom objects", () {
    test("testDeleteById", () async {
      await createTestCustomObject().then((object) async {
        logTime("CREATED successfully");
        await deleteCustomObjectById(testClassName, object.id)
            .then((voidResult) {
          logTime("Success DELETE");
        }).catchError((onError) {
          logTime("Error DELETE $onError");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error DELETE $onError");
        assert(onError == null);
      });
    });

    test("testDeleteByIds", () async {
      await createTestCustomObject().then((object) async {
        logTime("CREATED successfully");
        List<String> ids = [object.id, '5f998d3bca8bf4140543f79a'];
        await deleteCustomObjectsByIds(testClassName, ids).then((result) {
          logTime("Success DELETE");
        }).catchError((onError) {
          logTime("Error DELETE $onError");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error DELETE $onError");
        assert(onError == null);
      });
    });

    test("testDeleteByCriteria", () async {
      String currentTime = DateTime.now().toIso8601String();
      CubeCustomObject cubeCustomObject = CubeCustomObject(testClassName);
      cubeCustomObject.fields = testObject.toJson();
      cubeCustomObject.fields['stringField'] = currentTime;

      await createCustomObject(cubeCustomObject).then((object) async {
        logTime("CREATED successfully");

        Map<String, dynamic> params = {'stringField[or]': currentTime};

        await deleteCustomObjectsByCriteria(testClassName, params)
            .then((totalDeleted) {
          logTime("Success DELETE");
          assert(totalDeleted == 1);
        }).catchError((onError) {
          logTime("Error DELETE $onError");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error DELETE $onError");
        assert(onError == null);
      });
    });
  });
}
