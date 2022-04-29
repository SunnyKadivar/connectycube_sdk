import 'package:device_id/device_id.dart';
import 'package:package_info/package_info.dart';

import '../auth/models/cube_session.dart';
import '../utils/consts.dart';
import '../utils/string_utils.dart';

class CubeSettings {
  String _versionName = "1.1.3";
  String applicationId;
  String authorizationKey;
  String accountKey;

  String authorizationSecret;

  String chatDefaultResource = "";

  bool isDebugEnabled = true;
  bool isJoinEnabled = false;

  String apiEndpoint = "https://api.connectycube.com";
  String chatEndpoint = "chat.connectycube.com";

  static final CubeSettings _instance = CubeSettings._internal();

  Future<CubeSession> Function() onSessionRestore;

  CubeSettings._internal();

  static CubeSettings get instance => _instance;

  String get versionName => _versionName;

  init(
      String applicationId, String authorizationKey, String authorizationSecret,
      {Future<CubeSession> Function() onSessionRestore}) async {
    this.applicationId = applicationId;
    this.authorizationKey = authorizationKey;
    this.authorizationSecret = authorizationSecret;
    this.onSessionRestore = onSessionRestore;

    await _initDefaultParams();
  }

  setEndpoints(String apiEndpoint, String chatEndpoint) {
    if (isEmpty(apiEndpoint) || isEmpty(chatEndpoint)) {
      throw ArgumentError(
          "'apiEndpoint' and(or) 'chatEndpoint' can not be empty or null");
    }

    if (!apiEndpoint.startsWith("http")) {
      apiEndpoint = "https://" + apiEndpoint;
    }

    this.apiEndpoint = apiEndpoint;
    this.chatEndpoint = chatEndpoint;
  }

  Future<void> _initResourceId() async {
    String resourceId = await DeviceId.getID;
    this.chatDefaultResource = "$PREFIX_CHAT_RESOURCE\_$resourceId";
  }

  Future<void> _initVersionName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    this._versionName = packageInfo.version;
  }

  Future<void> _initDefaultParams() async {
//    await _initVersionName();
    await _initResourceId();
  }
}
