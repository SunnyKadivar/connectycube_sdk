import 'dart:convert';

import '../../../connectycube_core.dart';

import '../models/cube_dialog.dart';

class GetDialogsQuery extends AutoManagedQuery<PagedResult<CubeDialog>> {
  Map<String, dynamic> params;

  GetDialogsQuery([this.params]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    if (params != null && params.isNotEmpty) {
      for (String key in params.keys) {
        putValue(parameters, key, params[key]);
      }
    }
  }

  @override
  PagedResult<CubeDialog> processResult(String response) {
    return PagedResult<CubeDialog>(
        response, (element) => CubeDialog.fromJson(element));
  }
}

class CreateDialogQuery extends AutoManagedQuery<CubeDialog> {
  CubeDialog dialog;

  CreateDialogQuery(this.dialog);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.POST);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    Map<String, dynamic> dialogToCreate = Map();
    for (String key in dialog.toJson().keys) {
      if (dialog.toJson()[key] != null) {
        dialogToCreate[key] = dialog.toJson()[key];
      }
    }

    parameters.addAll(dialogToCreate);
  }

  @override
  CubeDialog processResult(String response) {
    return CubeDialog.fromJson(jsonDecode(response));
  }
}

class UpdateDialogQuery extends AutoManagedQuery<CubeDialog> {
  String dialogId;
  Map<String, dynamic> updateParams;

  UpdateDialogQuery(this.dialogId, this.updateParams);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.PUT);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    parameters.addAll(updateParams);
  }

  @override
  CubeDialog processResult(String response) {
    return CubeDialog.fromJson(jsonDecode(response));
  }
}

class DeleteDialogQuery extends AutoManagedQuery<void> {
  String dialogId;
  bool force;

  DeleteDialogQuery(this.dialogId, [this.force]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.DELETE);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    if (force != null && force == true) {
      putValue(request.params, "force", 1);
    }
  }

  @override
  void processResult(String response) {}
}

class DeleteDialogsQuery extends AutoManagedQuery<DeleteItemsResult> {
  Set<String> dialogIds;
  bool force;

  DeleteDialogsQuery(this.dialogIds, [this.force]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.DELETE);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(
        buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogIds.join(',')]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    if (force != null && force == true) {
      putValue(request.params, "force", 1);
    }
  }

  @override
  DeleteItemsResult processResult(String response) {
    return DeleteItemsResult.fromJson(jsonDecode(response));
  }
}

class SubscribeToPublicDialogQuery extends AutoManagedQuery<CubeDialog> {
  String dialogId;

  SubscribeToPublicDialogQuery(this.dialogId);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.POST);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(
        buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId, "subscribe"]));
  }

  @override
  CubeDialog processResult(String response) {
    return CubeDialog.fromJson(jsonDecode(response));
  }
}

class UnSubscribeFromPublicDialogQuery extends AutoManagedQuery<void> {
  String dialogId;

  UnSubscribeFromPublicDialogQuery(this.dialogId);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.DELETE);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(
        buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId, "subscribe"]));
  }

  @override
  void processResult(String response) {}
}

class AddRemoveAdminsQuery extends AutoManagedQuery<CubeDialog> {
  String dialogId;
  Set<int> addedIds;
  Set<int> removedIds;

  AddRemoveAdminsQuery(this.dialogId, {this.addedIds, this.removedIds});

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.PUT);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(
        buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId, "admins"]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    if (addedIds != null && addedIds.isNotEmpty) {
      putValue(parameters, "push_all", {'admins_ids': List.of(addedIds)});
    }

    if (removedIds != null && removedIds.isNotEmpty) {
      putValue(parameters, "pull_all", {'admins_ids': List.of(removedIds)});
    }
  }

  @override
  CubeDialog processResult(String response) {
    return CubeDialog.fromJson(jsonDecode(response));
  }
}

class UpdateNotificationsSettingsQuery extends AutoManagedQuery<bool> {
  String dialogId;
  bool enable;

  UpdateNotificationsSettingsQuery(this.dialogId, this.enable);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.PUT);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl(
        [CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId, "notifications"]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    putValue(parameters, "enabled", enable ? 1 : 0);
  }

  @override
  bool processResult(String response) {
    return _processNotificationsSettingsResult(response);
  }
}

class GetNotificationsSettingsQuery extends AutoManagedQuery<bool> {
  String dialogId;

  GetNotificationsSettingsQuery(this.dialogId);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl(
        [CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId, "notifications"]));
  }

  @override
  bool processResult(String response) {
    return _processNotificationsSettingsResult(response);
  }
}

class GetDialogOccupantsQuery extends AutoManagedQuery<PagedResult<CubeUser>> {
  String dialogId;

  GetDialogOccupantsQuery(this.dialogId);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(
        buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT, dialogId, "occupants"]));
  }

  @override
  PagedResult<CubeUser> processResult(String response) {
    return PagedResult<CubeUser>(
        response, (element) => CubeUser.fromJson(element['user']));
  }
}

class GetDialogsCountQuery extends AutoManagedQuery<int> {
  GetDialogsCountQuery();

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([CHAT_ENDPOINT, DIALOG_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    putValue(request.params, "count", 1);
  }

  @override
  int processResult(String response) {
    return jsonDecode(response)['items']['count'];
  }
}

_processNotificationsSettingsResult(String response) {
  var responseObj = jsonDecode(response);
  var notifications = responseObj['notifications'];
  int enabled = notifications['enabled'];
  return enabled == 1;
}

class UpdateDialogParams {
  Map<String, dynamic> _pushAll = Map();
  Map<String, dynamic> _pullAll = Map();

  Set<int> deleteOccupantIds = Set();
  Set<int> addOccupantIds = Set();
  Set<int> deleteAdminIds = Set();
  Set<int> addAdminIds = Set();
  Set<String> deletePinnedMsgIds = Set();
  Set<String> addPinnedMsgIds = Set();

  String newName;
  String newPhoto;
  String newDescription;
  CubeDialogCustomData customData;

  Map<String, dynamic> getUpdateDialogParams() {
    Map<String, dynamic> resultParams = Map();

    if (addOccupantIds.isNotEmpty)
      _pushAll['occupants_ids'] = List.of(addOccupantIds);

    if (addPinnedMsgIds.isNotEmpty)
      _pushAll['pinned_messages_ids'] = List.of(addPinnedMsgIds);

    if (addAdminIds.isNotEmpty) _pushAll['admins_ids'] = List.of(addAdminIds);

    if (deleteOccupantIds.isNotEmpty)
      _pullAll['occupants_ids'] = List.of(deleteOccupantIds);

    if (deletePinnedMsgIds.isNotEmpty)
      _pullAll['pinned_messages_ids'] = List.of(deletePinnedMsgIds);

    if (deleteAdminIds.isNotEmpty)
      _pullAll['admins_ids'] = List.of(deleteAdminIds);

    if (_pushAll.isNotEmpty) resultParams['push_all'] = _pushAll;
    if (_pullAll.isNotEmpty) resultParams['pull_all'] = _pullAll;

    if (!isEmpty(newName)) resultParams['name'] = newName;
    if (newPhoto != null) resultParams['photo'] = newPhoto;
    if (newDescription != null) resultParams['description'] = newDescription;

    if (customData != null) resultParams['data'] = customData;

    return resultParams;
  }
}
