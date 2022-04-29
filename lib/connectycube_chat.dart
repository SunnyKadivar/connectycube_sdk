export 'connectycube_core.dart';

export 'src/chat/chat_connection_service.dart';

export 'src/chat/models/cube_message.dart';
export 'src/chat/models/cube_dialog.dart';
export 'src/chat/models/message_status_model.dart';
export 'src/chat/models/typing_status_model.dart';

export 'src/chat/query/dialogs_query.dart';
export 'src/chat/query/global_search.dart';
export 'src/chat/query/messages_query.dart';

export 'src/chat/realtime/extentions.dart';

export 'src/chat/realtime/managers/chat_messages_manager.dart';
export 'src/chat/realtime/managers/global_messages_manager.dart';
export 'src/chat/realtime/managers/messages_statuses_manager.dart';
export 'src/chat/realtime/managers/system_messages_manager.dart';
export 'src/chat/realtime/managers/typing_statuses_manager.dart';

export 'src/chat/realtime/utils/chat_constants.dart';
export 'src/chat/realtime/utils/jid_utils.dart';

import 'connectycube_core.dart';

import 'src/chat/models/cube_dialog.dart';
import 'src/chat/models/cube_message.dart';
import 'src/chat/query/dialogs_query.dart';
import 'src/chat/query/global_search.dart';
import 'src/chat/query/messages_query.dart';

Future<PagedResult<CubeDialog>> getDialogs([Map<String, dynamic> params]) {
  return GetDialogsQuery(params).perform();
}

Future<CubeDialog> createDialog(CubeDialog newDialog) {
  return CreateDialogQuery(newDialog).perform();
}

/// [params] - additional parameters for request. Use class-helper [UpdateDialogParams] to simple config request.
///
Future<CubeDialog> updateDialog(String dialogId, Map<String, dynamic> params) {
  return UpdateDialogQuery(dialogId, params).perform();
}

Future<void> deleteDialog(String dialogId, [bool force]) {
  return DeleteDialogQuery(dialogId, force).perform();
}

Future<DeleteItemsResult> deleteDialogs(Set<String> dialogsIds, [bool force]) {
  return DeleteDialogsQuery(dialogsIds, force).perform();
}

Future<CubeDialog> subscribeToPublicDialog(String dialogId) {
  return SubscribeToPublicDialogQuery(dialogId).perform();
}

Future<void> unSubscribeFromPublicDialog(String dialogId) {
  return UnSubscribeFromPublicDialogQuery(dialogId).perform();
}

Future<CubeDialog> addRemoveAdmins(String dialogId,
    {Set<int> toAddIds, Set<int> toRemoveIds}) {
  return AddRemoveAdminsQuery(dialogId,
          addedIds: toAddIds, removedIds: toRemoveIds)
      .perform();
}

Future<bool> updateDialogNotificationsSettings(String dialogId, bool enable) {
  return UpdateNotificationsSettingsQuery(dialogId, enable).perform();
}

Future<bool> getDialogNotificationsSettings(String dialogId) {
  return GetNotificationsSettingsQuery(dialogId).perform();
}

Future<PagedResult<CubeUser>> getDialogOccupants(String dialogId) {
  return GetDialogOccupantsQuery(dialogId).perform();
}

Future<int> getDialogsCount() {
  return GetDialogsCountQuery().perform();
}

/// [params] - additional parameters for request. Use class-helper [GlobalSearchParams] to simple config search request
///
Future<GlobalSearchResult> searchText(String searchText,
    [Map<String, dynamic> params]) {
  return GlobalSearchQuery(searchText, params).perform();
}

Future<CubeMessage> createMessage(CubeMessage message, [bool sendToChat]) {
  return CreateMessageQuery(message).perform();
}

/// [params] - additional parameters for request. Use class-helper [GetMessagesParameters] to simple config request
///
Future<PagedResult<CubeMessage>> getMessages(String dialogId,
    [Map<String, dynamic> params]) {
  return GetMessageQuery(dialogId, params).perform();
}

Future<int> getMessagesCount(String dialogId) {
  return GetMessagesCountQuery(dialogId).perform();
}

Future<Map<String, int>> getUnreadMessagesCount([List<String> dialogsIds]) {
  return GetUnreadMessagesCountQuery(dialogsIds).perform();
}

/// [params] - additional parameters for request. Use class-helper [UpdateMessageParameters] to simple config request
///
Future<void> updateMessage(String messageId, String dialogId,
    [Map<String, dynamic> params]) {
  return UpdateMessageQuery(messageId, dialogId, params).perform();
}

/// [params] - additional parameters for request. Use class-helper [UpdateMessageParameters] to simple config request
///
Future<void> updateMessages(String dialogId, Map<String, dynamic> params,
    [Set<String> messagesIds]) {
  String msgIdsString = "";
  if (messagesIds?.isNotEmpty ?? false) {
    msgIdsString = messagesIds.join(',');
  }

  return UpdateMessageQuery(msgIdsString, dialogId, params).perform();
}

Future<DeleteItemsResult> deleteMessages(List<String> messagesIds,
    [bool force]) {
  return DeleteMessagesQuery(messagesIds, force).perform();
}
