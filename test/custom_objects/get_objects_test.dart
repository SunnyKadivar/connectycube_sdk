import 'package:connectycube_sdk/connectycube_core.dart';
import 'package:connectycube_sdk/connectycube_custom_objects.dart';
import 'package:flutter_test/flutter_test.dart';

import 'custom_object_test_class.dart';
import 'custom_objects_test_utils.dart';

Future<void> main() async {
  await beforeTestPreparations();

  group("Tests GET custom objects", () {
    test("testGetByClassName", () async {
      await createTestCustomObject().then((createdObject) async {
        await getCustomObjectsByClassName(testClassName).then((result) async {
          logTime("Success GET_BY_CLASS_NAME");
          assert(result.items.length > 0);

          List<String> gotIds =
              result.items.map((object) => object.id).toList();
          assert(gotIds.contains(createdObject.id));

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error GET_BY_CLASS_NAME");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error GET_BY_CLASS_NAME");
        assert(onError == null);
      });
    });

    test("testGetByParameters", () async {
      String currentTime = DateTime.now().toIso8601String();
      CubeCustomObject cubeCustomObject = CubeCustomObject(testClassName);
      cubeCustomObject.fields = testObject.toJson();
      cubeCustomObject.fields['stringField'] = currentTime;

      await createCustomObject(cubeCustomObject).then((createdObject) async {
        Map<String, dynamic> params = {'stringField[in]': currentTime};
        await getCustomObjectsByClassName(testClassName, params)
            .then((result) async {
          logTime("Success GET_BY_PARAMETERS");
          assert(result.items.length == 1);

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error GET_BY_PARAMETERS");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error GET_BY_PARAMETERS");
        assert(onError == null);
      });
    });

    test("testGetByIds", () async {
      await createTestCustomObject().then((createdObject) async {
        List<String> ids = [createdObject.id, '5f985984ca8bf43530e81233'];
        await getCustomObjectsByIds(testClassName, ids).then((result) async {
          logTime("Success GET_BY_IDS");
          assert(result.items.length == 1);
          assert(result.className == testClassName);

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error GET_BY_IDS");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error GET_BY_IDS");
        assert(onError == null);
      });
    });

    test("testGetById", () async {
      await createTestCustomObject().then((createdObject) async {
        String id = createdObject.id;
        await getCustomObjectById(testClassName, id).then((object) async {
          logTime("Success GET_BY_ID");
          assert(object.id == id);

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error GET_BY_ID");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error GET_BY_ID");
        assert(onError == null);
      });
    });

    test("testGetPermissions", () async {
      await createTestCustomObject().then((createdObject) async {
        await getCustomObjectPermissions(testClassName, createdObject.id)
            .then((permissions) async {
          logTime("Success GET_PERMISSIONS");
          assert(permissions.recordId == createdObject.id);
          assert(permissions.permissions.readPermission != null);
          assert(permissions.permissions.updatePermission != null);
          assert(permissions.permissions.deletePermission != null);

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error GET_PERMISSIONS");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error GET_PERMISSIONS");
        assert(onError == null);
      });
    });



  });
}
