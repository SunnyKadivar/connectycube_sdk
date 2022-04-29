## 1.1.3

* Calls:
    - improvements for the getting `localMediaStrem` (there were problems on some devices);

* Chat:
    - fixed login to the chat with the same user but with different passwords;
	- improved sending asynchronous packages (group messages, join group, leave group, get last user activity);
	- disabled join to the group chat by default before sending group message. Now it is not required on the shared server. But if your server requires it, you can enable join via `CubeSettings.instance.isJoinEnabled = true`;

## 1.1.2

* Bugfix

## 1.1.1

* Improvements for background calls;
* Improved parsing of `CubeSubscription` model;
* Fixed conflicts when connecting some dependencies;

## 1.1.0

* New API:
    - added new function `uploadFileWithProgress(File, {bool, Function(int)}` which provides possibility for listening progress of file uploading process;
    - added field `addressBookName` to `CubeUser` model (this field is received on request `getRegisteredUsersFromAddressBook(bool, [String])` in **compact** mode);

* Fixed:
    - receiving same call after it rejection (in some cases);
    - chat reconnection feature;
    - serialization/deserialization for `CubeSession` and `CubeUser` models;

* Improvements:
    - improved data exchange for some signaling messages during P2P calls;
    - update [flutter_webrtc](https://pub.dev/packages/flutter_webrtc) to version 0.5.7;

## 1.0.0

Stable release.

* Added automatic session restoring logic ([details](https://developers.connectycube.com/flutter/authentication-and-users?id=session-expiration));
* Updated all dependencies to actual versions;

## 0.6.0

* Implemented API for [Custom objects](https://developers.connectycube.com/server/custom_objects)

## 0.5.1

* Fixed saving token's expiration date after the session creation.

* Deprecated API:
    - method `saveActiveSession(CubeSession session)` from `CubeSessionManager` - now used just setter for `activeSession` field;
    - method `getActiveSession()` from `CubeSessionManager` - now used just getter for `activeSession` field;

## 0.5.0

* Update dependencies to latest versions;

* Removed API:
    - removed paremeter `objectFit` from `RTCVideoRenderer`;
    - removed paremeter `mirror` from `RTCVideoRenderer`;
* Added API:
    - added paremeter `objectFit` to `RTCVideoView` constructor;
    - added paremeter `mirror` to `RTCVideoView` constructor;

## 0.4.2

* Fixed group chatting after relogin with different users;

## 0.4.1

* Fixed work of chat managers after relogin with different users;
* Fixed receiving calls after relogin with different users;

## 0.4.0

* Added Chat [connection state listener](https://developers.connectycube.com/flutter/messaging?id=connect-to-chat);
* Added Chat [reconnection](https://developers.connectycube.com/flutter/messaging?id=reconnection) functionality;
* Fixed relogin to the Chat;
* Fixed Sign Up users with tags;
* Fixed parsing Attachments during realtime communication;

## 0.3.0-beta1

* Implemented Conference Calls ([documentation](https://developers.connectycube.com/flutter/videocalling-conference), [code sample](https://github.com/ConnectyCube/connectycube-flutter-samples/tree/master/conf_call_sample));

## 0.2.0-beta3

* Improvements for crossplatform calls;

## 0.2.0-beta2

* Fixed 'Accept call' issue when call from Web;

## 0.2.0-beta1

* Implemented P2P Calls ([documentation](https://developers.connectycube.com/flutter/videocalling), [code sample](https://github.com/ConnectyCube/connectycube-flutter-samples/tree/master/p2p_call_sample));
* Improvements for CubeChatConnection;

## 0.1.0-beta5

* Update documentation link

## 0.1.0-beta4

This is a 1st public release.

The following features are covered:

* Authentication and Users;
* Messaging;
* Address Book;
* Push Notifications.

## 0.1.0-beta3

* Add minimal examples.

## 0.1.0-beta2

* Updates by pub.dev recommendations.

## 0.1.0-beta1

* Initial release.
