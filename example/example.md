### Init ConnectyCube SDK

```dart
String appId = "";
String authKey = "";
String authSecret = "";

init(appId, authKey, authSecret);
```

### Create session
```dart
CubeUser user = CubeUser(login: "user_login", password: "super_sequre_password");

createSession(user).then((cubeSession){
  print("Session was created");
}).catchError((error){
  print("Error was occured during create sessin");
});
```

### Login to the chat
```dart
CubeUser user = CubeUser(id: 123456, login: "user_login", password: "super_sequre_password");
    
CubeChatConnection.instance.login(user).then((user){
  print("Success login to the chat");
}).catchError((error){
  print("Error was occured during login to the chat");
});
```

## Dialogs

All chats between users are organized in dialogs.
The are 3 types of dialogs:

- 1-1 chat - a dialog between 2 users.
- group chat - a dialog between specified list of users.
- public group chat - an open dialog. Any user from your app can chat there.
- broadcast - chat where a message is sent to all users within application at once.
All the users from the application are able to join this group. Broadcast dialogs can be created only via Admin panel.

You need to create a new dialog and then use it to chat with other users. You also can obtain a list of your existing dialogs.

## Create new dialog

### Create 1-1 chat

You need to pass `type = CubeDialogType.PRIVATE` and an id of an opponent you want to create a chat with:

```dart
CubeDialog newDialog = CubeDialog(
    CubeDialogType.PRIVATE,
    occupantsIds: [56]);

createDialog(newDialog)
    .then((createdDialog) {})
    .catchError((error) {});
```

### Create group chat

You need to pass `type = CubeDialogType.GROUP` and ids of opponents you want to create a chat with:

```dart
CubeDialog newDialog = CubeDialog(
    CubeDialogType.GROUP,
    name: "Hawaii relax team",
    description: "Some description",
    occupantsIds: [56, 98, 34],
    photo: "https://some.url/to/avatar.jpeg");

  createDialog(newDialog)
      .then((createdDialog) {})
      .catchError((error) {});
```

### Create public group chat

It's possible to create a public group chat, so any user from you application can join it. There is no a list with occupants,  
this chat is just open for everybody.

You need to pass `type = CubeDialogType.PUBLIC` and ids of opponents you want to create a chat with:

```dart
CubeDialog newDialog = CubeDialog(
    CubeDialogType.PUBLIC,
    name: "Blockchain trends",
    description: "Public dialog Description",
    photo: "https://some.url/to/avatar.jpeg");

createDialog(newDialog)
    .then((createdDialog) {})
    .catchError((error) {});
```

## Send/Receive chat messages

```dart
CubeDialog cubeDialog;  // some dialog, which must contains opponent's id in 'occupantsIds' for CubeDialogType.PRIVATE and
                        // 'dialogId' for other types of dialogs
CubeMessage message = CubeMessage();
message.body = "How are you today?";
message.dateSent = DateTime.now().millisecondsSinceEpoch;
message.markable = true;
message.saveToHistory = true;
      
cubeDialog.sendMessage(message)
    .then((cubeMessage) {})
    .catchError((error) {});

// to listen messages
ChatMessagesManager chatMessagesManager = CubeChatConnection.instance.chatMessagesManager;
chatMessagesManager.chatMessagesStream.listen((newMessage) {
    // new message received
}).onError((error) {
    // error received
});
```

## Calls

### Setup P2PClient
```dart
P2PClient callClient = P2PClient.instance; // returns instance of P2PClient
```

### Create call session

```dart
Set<int> opponentsIds = {};
int callType = CallType.VIDEO_CALL; // or CallType.AUDIO_CALL

P2PSession callSession = callClient.createCallSession(callType, opponentsIds);
```

### Start call

```dart
Map<String, String> additionalInfo = {};
callSession.startCall(additionalInfo);
```

### Accept call

```dart
Map<String, String> additionalInfo = {}; // additional info for other call members
callSession.acceptCall(additionalInfo);
```

## End a call

```dart
Map<String, String> additionalInfo = {}; // additional info for other call members
callSession.hungUp(additionalInfo);
```

## Conference Calls

### Setup ConferenceClient

```dart
ConferenceClient callClient = ConferenceClient.instance; // returns instance of ConferenceClient
```

### Create call session

```dart
ConferenceClient callClient = ConferenceClient.instance;
int callType = CallType.VIDEO_CALL; // or CallType.AUDIO_CALL

ConferenceSession callSession = callClient.createCallSession(currentUserId, callType);
```

### Join video room

```dart
callSession.joinDialog(roomId, ((publishers) {
    startCall(roomId, opponents, callSession.currentUserId);// event by system message e.g.
  }
}));
```

### Subscribe/unsubscribe

```dart
callSession.subscribeToPublisher(publisher)
```

```dart
callSession.unsubscribeFromPublisher(publisher);
```

### Leave

```dart
callSession.leave();
```

## Custom objects

### Create Custom object
```dart
CubeCustomObject cubeCustomObject = CubeCustomObject('TestClassName');
cubeCustomObject.fields = {
    integerField: 987,
    doubleField: 6.54,
    booleanField: true,
    stringField: 'Some string',
};

createCustomObject(cubeCustomObject)
    .then((createdObject) {})
    .catchError((error) {});
```
### Get Custom object
```dart
String id = '5f985984ca8bf43530e81233';
getCustomObjectById('TestClassName', id)
    .then((object) {})
    .catchError((error) {});
```

### Update Custom object
```dart
Map<String, dynamic> params = {
    'stringField': 'Updated string'
};

String id = '5f985984ca8bf43530e81233';
updateCustomObject('TestClassName', id, params)
    .then((updatedObject) {})
    .catchError((error) {});
```

### Delete Custom object
```dart
String id = '5f985984ca8bf43530e81233';
deleteCustomObjectById('TestClassName', id)
    .then((voidResult) {})
    .catchError((error) {});
```