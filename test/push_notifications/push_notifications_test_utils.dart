import 'package:connectycube_sdk/connectycube_core.dart';

Map<String, dynamic> config = prodConfig; //select test server here

initConfig(Map<String, dynamic> newConfig){
  config = newConfig;
}

initCubeFramework() {
  CubeSettings.instance.apiEndpoint = config["api_endpoint"];
  CubeSettings.instance.chatEndpoint = config["chat_endpoint"];
  CubeSettings.instance.applicationId = config["app_id"];
  CubeSettings.instance.authorizationKey = config["auth_key"];
  CubeSettings.instance.authorizationSecret = config["auth_secret"];
  // CubeSettings.instance.onSessionRestore = createTestSession;
}

Future<CubeSession> createTestSession() async {
  return createSession(CubeUser(login: config["user_1_login"], password: config["user_1_pass"]));
}

Future<void> beforeTestPreparations() async {
  initCubeFramework();
  await createTestSession();
}

Map<String, dynamic> prodConfig = {
  "app_id": "476",
  "auth_key": "PDZjPBzAO8WPfCp",
  "auth_secret": "6247kjxXCLRaua6",
  "api_endpoint": "https://api.connectycube.com",
  "chat_endpoint": "chat.connectycube.com",
  "user_1_login": "flutter_sdk_tests_user",
  "user_1_pass": "flutter_sdk_tests_user",
  "user_1_id": 2325293,
  "user_2_login": "test_user5",
  "user_2_pass": "test_user5",
  "user_2_id": 563541,
  "user_3_login": "test_user6",
  "user_3_pass": "test_user6",
  "user_3_id": 563543,
};


Map<String, dynamic> api2Config = {
  "app_id": "7",
  "auth_key": "v6NdWLdvfs5QcyU",
  "auth_secret": "JdSzvFsYhXqAagv",
  "api_endpoint": "https://api2.connectycube.com",
  "chat_endpoint": "chat2.connectycube.com",
  "user_1_login": "flutter_sdk_tests_user",
  "user_1_pass": "flutter_sdk_tests_user",
  "user_1_id": 55,
  "user_2_login": "flutter_sdk_tests_user_2",
  "user_2_pass": "flutter_sdk_tests_user_2",
  "user_2_id": 56,
  "user_3_login": "flutter_sdk_tests_user_3",
  "user_3_pass": "flutter_sdk_tests_user_3",
  "user_3_id": 58,
};
