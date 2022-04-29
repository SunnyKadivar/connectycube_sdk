import 'package:connectycube_sdk/connectycube_core.dart';
import 'package:connectycube_sdk/connectycube_custom_objects.dart';
import 'package:connectycube_sdk/src/custom_objects/models/cube_custom_object_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'custom_object_test_class.dart';
import 'custom_objects_test_utils.dart';

Future<void> main() async {
  await beforeTestPreparations();

  group("Tests UPDATE custom objects", () {
    test("testUpdateById", () async {
      await createTestCustomObject().then((createdObject) async {
        List<String> toAddStrings = ["4th", "5th"];
        double updatedFloatField = 1.56;
        int updatedFirstItemInIntegersArray = 12;
        Map<String, dynamic> params = {
          'floatField': updatedFloatField,
          'push': {'arrayStrings': toAddStrings},
          'arrayIntegers': {'0': updatedFirstItemInIntegersArray}
        };

        await updateCustomObject(testClassName, createdObject.id, params)
            .then((updatedObject) async {
          logTime("Success UPDATE_BY_ID");
          TestClass updatedCustomObject =
              TestClass.fromJson(updatedObject.fields);
          assert(
              updatedCustomObject.arrayStrings.contains(toAddStrings.first) &&
                  updatedCustomObject.arrayStrings.contains(toAddStrings.last));
          assert(updatedCustomObject.floatField == updatedFloatField);
          assert(updatedCustomObject.arrayIntegers[0] ==
              updatedFirstItemInIntegersArray);

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error UPDATE_BY_ID");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error UPDATE_BY_ID");
        assert(onError == null);
      });
    });

    test("testUpdatePermissions", () async {
      await createTestCustomObject().then((createdObject) async {
        List<int> userIds = [1253162, 563541, 563543];

        CubeCustomObjectPermission updatePermission =
            CubeCustomObjectPermission(Level.OPEN_FOR_USERS_IDS, ids: userIds);
        CubeCustomObjectPermissions permissions =
            CubeCustomObjectPermissions(updatePermission: updatePermission);

        Map<String, dynamic> params = {'permissions': permissions};

        await updateCustomObject(testClassName, createdObject.id, params)
            .then((updatedObject) async {
          logTime("Success UPDATE_PERMISSIONS");

          assert(updatedObject.permissions != null);
          assert(updatedObject.permissions.updatePermission.level ==
              Level.OPEN_FOR_USERS_IDS);
          assert(updatedObject.permissions.updatePermission.ids
              .skipWhile((value) => userIds.contains(value))
              .isEmpty);

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error UPDATE_PERMISSIONS");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error UPDATE_PERMISSIONS");
        assert(onError == null);
      });
    });

    test("testUpdateByCriteria", () async {
      String currentTime = DateTime.now().toIso8601String();
      CubeCustomObject cubeCustomObject = CubeCustomObject(testClassName);
      cubeCustomObject.fields = testObject.toJson();
      cubeCustomObject.fields['stringField'] = currentTime;

      await createCustomObject(cubeCustomObject).then((createdObject) async {
        List<int> updaterArrayInt = [10, 11, 12, 13];
        Map<String, dynamic> params = {
          'search_criteria': {
            'stringField': {
              'or': currentTime,
            }
          },
          'arrayIntegers': updaterArrayInt
        };
        await updateCustomObjectsByCriteria(testClassName, params)
            .then((result) async {
          logTime("Success UPDATE_BY_CRITERIA");
          assert(result.items.length == 1);

          TestClass updatedObject = TestClass.fromJson(result.items[0].fields);
          assert(updatedObject.arrayIntegers
              .skipWhile((value) => updaterArrayInt.contains(value))
              .isEmpty);

          await deleteCustomObjectById(testClassName, createdObject.id);
        }).catchError((onError) {
          logTime("Error UPDATE_BY_CRITERIA");
          assert(onError == null);
        });
      }).catchError((onError) {
        logTime("Error UPDATE_BY_CRITERIA");
        assert(onError == null);
      });
    });
  });
}
