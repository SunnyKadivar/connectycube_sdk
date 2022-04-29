import 'package:connectycube_sdk/connectycube_core.dart';
import 'package:connectycube_sdk/connectycube_custom_objects.dart';

import 'custom_object_test_class.dart';

TestClass testObject = TestClass(
  integerField: 1,
  floatField: 1.23,
  booleanField: true,
  stringField: 'some string',
  locationField: [34.56, 78.90],
  dateField: null,
  fileField: null,
  arrayIntegers: [9, 8, 7, 6],
  arrayFloats: [9.8, 8.7, 7.6, 6.5],
  arrayBooleans: [true, false, true],
  arrayStrings: ["first string", "second string", "3rd string"],
);

initCubeFramework() {
  CubeSettings.instance.applicationId = "476";
  CubeSettings.instance.authorizationKey = "PDZjPBzAO8WPfCp";
  CubeSettings.instance.authorizationSecret = "6247kjxXCLRaua6";
}

Future<void> createTestSession() async {
  await createSession(CubeUser(
      login: "flutter_sdk_tests_user", password: "flutter_sdk_tests_user"));
}

Future<void> beforeTestPreparations() async {
  initCubeFramework();
  await createTestSession();
}

Future<CubeCustomObject> createTestCustomObject() {
  CubeCustomObject cubeCustomObject = CubeCustomObject(testClassName);
  cubeCustomObject.fields = testObject.toJson();

  return createCustomObject(cubeCustomObject);
}