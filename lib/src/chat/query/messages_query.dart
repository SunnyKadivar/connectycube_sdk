import 'dart:convert';

import '../../../connectycube_core.dart';

import '../models/cube_message.dart';

class GetMessageQuery extends AutoManagedQuery<PagedResult<CubeMessage>> {
  String dialogId;
  Map<String, dynamic> params;

  GetMessageQuery(this.dialogId, [this.params]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, MESSAGE_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    parameters['chat_dialog_id'] = dialogId;

    if (params != null && params.isNotEmpty) {
      for (String key in params.keys) {
        putValue(parameters, key, params[key]);
      }
    }
  }

  @override
  PagedResult<CubeMessage> processResult(String response) {
    return PagedResult<CubeMessage>(
        response, (element) => CubeMessage.fromJson(element));
  }
}

class GetMessagesCountQuery extends AutoManagedQuery<int> {
  String dialogId;

  GetMessagesCountQuery(this.dialogId);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, MESSAGE_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    putValue(parameters, 'chat_dialog_id', dialogId);
    putValue(parameters, 'count', 1);
  }

  @override
  int processResult(String response) {
    return jsonDecode(response)['items']['count'];
  }
}

class GetUnreadMessagesCountQuery extends AutoManagedQuery<Map<String, int>> {
  List<String> dialogsIds;

  GetUnreadMessagesCountQuery([this.dialogsIds]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, MESSAGE_ENDPOINT, "unread"]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    if (dialogsIds != null && dialogsIds.isNotEmpty) {
      parameters['chat_dialog_ids'] = dialogsIds.join(",");
    }
  }

  @override
  Map<String, int> processResult(String response) {
    Map<String, dynamic> responseMap = jsonDecode(response);
    return responseMap.map((key, value) => MapEntry(key, value as int));
  }
}

class CreateMessageQuery extends AutoManagedQuery<CubeMessage> {
  CubeMessage message;
  bool sendToChat;

  CreateMessageQuery(this.message, [this.sendToChat = false]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.POST);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, MESSAGE_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    if (message.dialogId == null && message.recipientId == null) {
      throw IllegalArgumentException(
          "'chat_dialog_id' or 'recipient_id' required");
    } else if (message.dialogId != null) {
      parameters['chat_dialog_id'] = message.dialogId;
    } else if (message.recipientId != null) {
      parameters['recipient_id'] = message.recipientId;
    }

    if (!isEmpty(message.body)) {
      parameters['message'] = message.body;
    }

    if (sendToChat) putValue(parameters, 'send_to_chat', 1);

    if (message.properties != null && message.properties.isNotEmpty) {
      parameters.addAll(message.properties);
    }

    Map<String, dynamic> attachments;
    if (message.attachments != null && message.attachments.isNotEmpty) {
      attachments = Map();

      for (int i = 0; i < message.attachments.length; i++) {
        attachments[i.toString()] = message.attachments[i];
      }

      putValue(parameters, 'attachments', attachments);
    }
  }

  @override
  CubeMessage processResult(String response) {
    return CubeMessage.fromJson(jsonDecode(response));
  }
}

class UpdateMessageQuery extends AutoManagedQuery<void> {
  String messageId;
  String dialogId;
  Map<String, dynamic> params;

  UpdateMessageQuery(this.messageId, this.dialogId, [this.params]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.PUT);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, MESSAGE_ENDPOINT, messageId]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    if (params == null || params.isEmpty) {
      throw IllegalArgumentException(
          "Need spicify parameters for update message");
    }

    Map<String, dynamic> parameters = request.params;
    parameters.addAll(params);

    putValue(parameters, 'chat_dialog_id', dialogId);
  }

  @override
  void processResult(String response) {}
}

class DeleteMessagesQuery extends AutoManagedQuery<DeleteItemsResult> {
  List<String> messagesIds;
  bool force;

  DeleteMessagesQuery(this.messagesIds, [this.force]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.DELETE);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl(
        [CHAT_ENDPOINT, MESSAGE_ENDPOINT, messagesIds.join(',')]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    if (force) {
      putValue(request.params, 'force', 1);
    }
  }

  @override
  DeleteItemsResult processResult(String response) {
    return DeleteItemsResult.fromJson(jsonDecode(response));
  }
}

class GetMessagesParameters {
  int limit;
  int skip;
  bool markAsRead = true;
  RequestSorter sorter;
  List<RequestFilter> filters;
  Map<String, dynamic> additionalParams;

  Map<String, dynamic> getRequestParameters() {
    Map<String, dynamic> result = Map();

    if (limit != null) result['limit'] = limit;
    if (skip != null) result['skip'] = skip;
    if (!markAsRead) result['mark_as_read'] = 0;
    if (sorter != null) result['sort_${sorter.sortType}'] = sorter.fieldName;

    if (filters != null && filters.isNotEmpty) {
      for (RequestFilter filter in filters) {
        result['${filter.fieldName}[${filter.rule}]'] = filter.fieldValue;
      }
    }

    if (additionalParams != null && additionalParams.isNotEmpty) {
      result.addAll(additionalParams);
    }

    return result;
  }
}

class UpdateMessageParameters {
  bool read = false;
  bool delivered = false;
  String newBody;

  Map<String, dynamic> getRequestParameters() {
    Map<String, dynamic> result = Map();

    if (read) result['read'] = 1;
    if (delivered) result['delivered'] = 1;
    if (newBody != null) result['message'] = newBody;

    return result;
  }
}
