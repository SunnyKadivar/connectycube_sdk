import 'package:connectycube_sdk/connectycube_core.dart';
import 'package:connectycube_sdk/connectycube_custom_objects.dart';
import 'package:connectycube_sdk/src/custom_objects/models/cube_custom_object_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'custom_objects_test_utils.dart';
import 'custom_object_test_class.dart';

Future<void> main() async {
  await beforeTestPreparations();

  group("Tests CREATE custom objects", () {
    test("testCreate", () async {
      await createTestCustomObject().then((object) async {
        logTime(object.toString());

        TestClass createdObject = TestClass.fromJson(object.fields);
        assert(createdObject.booleanField == testObject.booleanField);
        assert(createdObject.integerField == testObject.integerField);
        assert(createdObject.floatField == testObject.floatField);
        assert(createdObject.stringField == testObject.stringField);
        assert(createdObject.locationField.skipWhile((value) => testObject.locationField.contains(value)).isEmpty);
        assert(createdObject.arrayBooleans.skipWhile((value) => testObject.arrayBooleans.contains(value)).isEmpty);
        assert(createdObject.arrayFloats.skipWhile((value) => testObject.arrayFloats.contains(value)).isEmpty);
        assert(createdObject.arrayIntegers.skipWhile((value) => testObject.arrayIntegers.contains(value)).isEmpty);
        assert(createdObject.arrayStrings.skipWhile((value) => testObject.arrayStrings.contains(value)).isEmpty);

        await deleteCustomObjectById(testClassName, object.id);
      }).catchError((onError) {
        logTime(onError.toString());
        assert(onError == null);
      });
    });

    test("testCreateWithPermissions", () async {
      List<int> userIds = [1253162, 563541, 563543];
      CubeCustomObject cubeCustomObject = CubeCustomObject(testClassName);
      cubeCustomObject.fields = testObject.toJson();

      CubeCustomObjectPermission updatePermission = CubeCustomObjectPermission(Level.OPEN_FOR_USERS_IDS, ids: userIds);
      CubeCustomObjectPermissions permissions = CubeCustomObjectPermissions(updatePermission: updatePermission);

      cubeCustomObject.permissions = permissions;

      await createCustomObject(cubeCustomObject).then((object) async {
        logTime(object.toString());

        CubeCustomObjectPermissions permissionsCreated = object.permissions;
        CubeCustomObjectPermission updatePermissionCreated = permissionsCreated.updatePermission;

        assert(updatePermissionCreated.ids.skipWhile((value) => userIds.contains(value)).isEmpty);

        await deleteCustomObjectById(testClassName, object.id);
      }).catchError((onError) {
        logTime(onError.toString());
        assert(onError == null);
      });
    });
  });
}

