import '../../../connectycube_core.dart';

class CubeSubscription extends CubeEntity {
  String notificationChannel;
  PushToken token;
  CubeDeviceModel device;

  CubeSubscription.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    notificationChannel = json['notification_channel']['name'];
    device = CubeDeviceModel.fromJson(json['device']);
  }

  Map<String, dynamic> toJson() => {
        'notification_channel': notificationChannel,
        'push_token': token,
        'device': device
      };

  @override
  toString() => toJson().toString();
}

class PushToken {
  String environment;
  String bundleIdentifier;
  String clientIdentificationSequence;

  PushToken(this.environment, this.clientIdentificationSequence,
      [this.bundleIdentifier]);

  PushToken.fromJson(Map<String, dynamic> json) {
    environment = json['environment'];
    bundleIdentifier = json['bundle_identifier'];
    clientIdentificationSequence = json['client_identification_sequence'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'environment': environment,
      'client_identification_sequence': clientIdentificationSequence
    };

    if (!isEmpty(bundleIdentifier)) {
      result['bundle_identifier'] = bundleIdentifier;
    }

    return result;
  }

  @override
  toString() => toJson().toString();
}

class CubeDeviceModel {
  String udid;
  String platform;
  String bundleIdentifier;
  String clientIdentificationSequence;

  CubeDeviceModel(this.udid, this.platform);

  CubeDeviceModel.fromJson(Map<String, dynamic> json) {
    udid = json['udid'];
    platform = CubePlatformModel.fromJson(json['platform']).name;
    bundleIdentifier = json['bundle_identifier'];
    clientIdentificationSequence = json['client_identification_sequence'];
  }

  Map<String, dynamic> toJson() => {'udid': udid, 'platform': platform};

  @override
  toString() => toJson().toString();
}

class CubePlatformModel {
  String name;

  CubePlatformModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }

  Map<String, dynamic> toJson() => {'name': name};

  @override
  toString() => toJson().toString();
}
