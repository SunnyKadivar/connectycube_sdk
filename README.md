# Flutter Getting Started

ConnectyCube helps you implement real-time chat, video chat, push notifications and user authorization to any app with ease - no server side implementation required.  
You can concentrate fully on your mobile app development. Our Flutter SDK provides you with many helpful methods to build the chat and video chat from the client side.

This page presents a quick overview of the SDK’s functionalities and logic, then let you go through the easy steps of implementing ConnectyCube in your own app.

ConnectyCube Flutter SDK can be used on the following OS:

- Android
- iOS

## Create ConnectyCube app

Register a FREE ConnectyCube account at [https://connectycube.com/signup](https://connectycube.com/signup), then create your 1st app and obtain an app credentials.  
These credentials will be used to identify your app.

All users within the same ConnectyCube app can communicate by chat or video chat with each other, across all platforms - iOS, Android, Web, etc.

## When building a new app

If you are just starting your app and developing it from scratch, we recommend to use our Code Samples projects.

[Download Code Samples](https://developers.connectycube.com/flutter/code-samples)

These code samples are ready-to-go apps with an appropriate functionality and simple enough that even novice developers will be able to understand them.

## When integrating SDK into existing app

If you already have an app, do the following for integration.

### Connect SDK

Navigate to [Installing](https://pub.dev/packages/connectycube_sdk#-installing-tab-) tab to find out detailed guide.

### Initialize

Initialize framework with your ConnectyCube application credentials. You can access your application credentials
in [ConnectyCube Dashboard](https://admin.connectycube.com):

```dart
String appId = "";
String authKey = "";
String authSecret = "";

init(appId, authKey, authSecret);
```

### Configuration

An additional configs can be passed via `CubeSettings`:

```dart
CubeSettings.instance.isDebugEnabled = true; // to enable ConnectyCube SDK logs; 
CubeSettings.instance.setEndpoints(customApiEndpoint, customChatEndpoint); // to set custom endpoints
```

### Now integrate messaging & calling capabilities

Follow the API guides on how to integrate chat and calling features into your app:

- [Messaging API documentation](https://developers.connectycube.com/flutter/messaging)
- [Calling API documentation](https://developers.connectycube.com/flutter/videocalling)

## SDK Changelog

The complete SDK changelog is available on [ConnectyCube pub.dev page](https://pub.dev/packages/connectycube_sdk#-changelog-tab-)
