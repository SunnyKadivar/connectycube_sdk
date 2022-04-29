class RTCMediaConfig {
  static final RTCMediaConfig _instance = RTCMediaConfig._internal();

  RTCMediaConfig._internal();

  static RTCMediaConfig get instance => _instance;

  int minWidth = 640;
  int minHeight = 480;
  int minFrameRate = 30;
}
