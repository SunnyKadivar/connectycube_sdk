export 'src/core/address_book/models/addres_book_result.dart';
export 'src/core/address_book/models/cube_contact.dart';
export 'src/core/address_book/query/address_book_queries.dart';

export 'src/core/auth/models/cube_session.dart';
export 'src/core/auth/query/auth_query.dart';
export 'src/core/auth/query/delete_session_query.dart';
export 'src/core/auth/query/get_session_query.dart';

export 'src/core/cube_exceptions.dart';
export 'src/core/cube_session_manager.dart';

export 'src/core/models/cube_entity.dart';
export 'src/core/models/cube_settings.dart';

export 'src/core/users/models/cube_user.dart';
export 'src/core/users/query/create_user_query.dart';
export 'src/core/users/query/delete_user_query.dart';
export 'src/core/users/query/get_users_query.dart';
export 'src/core/users/query/reset_password_query.dart';
export 'src/core/users/query/update_user_query.dart';

export 'src/core/rest/query/query.dart';
export 'src/core/rest/request/request_help_models.dart';
export 'src/core/rest/request/rest_request.dart';
export 'src/core/rest/response/delete_items_result.dart';
export 'src/core/rest/response/paged_result.dart';
export 'src/core/rest/response/rest_response.dart';

export 'src/core/utils/cube_logger.dart';
export 'src/core/utils/collections_utils.dart';
export 'src/core/utils/consts.dart';
export 'src/core/utils/string_utils.dart';

import 'src/core/address_book/models/addres_book_result.dart';
import 'src/core/address_book/models/cube_contact.dart';
import 'src/core/address_book/query/address_book_queries.dart';
import 'src/core/auth/models/cube_session.dart';
import 'src/core/auth/query/auth_query.dart';
import 'src/core/auth/query/delete_session_query.dart';
import 'src/core/auth/query/get_session_query.dart';
import 'src/core/models/cube_settings.dart';
import 'src/core/rest/request/request_help_models.dart';
import 'src/core/rest/response/paged_result.dart';
import 'src/core/users/models/cube_user.dart';
import 'src/core/users/query/create_user_query.dart';
import 'src/core/users/query/delete_user_query.dart';
import 'src/core/users/query/get_users_query.dart';
import 'src/core/users/query/reset_password_query.dart';
import 'src/core/users/query/update_user_query.dart';
import 'src/core/utils/consts.dart';

init(
    String applicationId, String authorizationKey, String authorizationSecret, {Future<CubeSession> Function() onSessionRestore}) {
  CubeSettings.instance
      .init(applicationId, authorizationKey, authorizationSecret, onSessionRestore: onSessionRestore);
}

setEndpoints(String apiEndpoint, String chatEndpoint) {
  CubeSettings.instance.setEndpoints(apiEndpoint, chatEndpoint);
}

Future<CubeSession> createSession([CubeUser cubeUser]) {
  return CreateSessionQuery(cubeUser).perform();
}

Future<CubeSession> createSessionUsingSocialProvider(
    String socialProvider, String accessToken,
    [String accessTokenSecret]) {
  return CreateSessionQuery.usingSocial(
      socialProvider, List.of({accessToken, accessTokenSecret})).perform();
}

Future<CubeSession> createSessionUsingFirebase(
    String projectId, String accessToken) {
  return CreateSessionQuery.usingSocial(
      CubeProvider.FIREBASE_PHONE, List.of({projectId, accessToken})).perform();
}

Future<void> deleteSession([int sessionId]) {
  return DeleteSessionQuery(sessionId: sessionId).perform();
}

Future<void> deleteSessionsExceptCurrent() {
  return DeleteSessionQuery(exceptCurrent: true).perform();
}

Future<CubeSession> getSession() {
  return GetSessionQuery().perform();
}

Future<CubeUser> signIn(CubeUser user) {
  return SignInQuery(user).perform();
}

Future<CubeUser> signInByLogin(String login, String password) {
  CubeUser user = CubeUser(login: login, password: password);
  return signIn(user);
}

Future<CubeUser> signInByEmail(String email, String password) {
  CubeUser user = CubeUser(email: email, password: password);
  return signIn(user);
}

Future<CubeUser> signInUsingSocialProvider(
    String socialProvider, String accessToken,
    [String accessTokenSecret]) {
  return SignInQuery.usingSocial(
      socialProvider, List.of({accessToken, accessTokenSecret})).perform();
}

Future<CubeUser> signInUsingFirebase(String projectId, String accessToken) {
  return SignInQuery.usingSocial(
      CubeProvider.FIREBASE_PHONE, List.of({projectId, accessToken})).perform();
}

Future<CubeUser> signUp(CubeUser user) {
  return CreateUserQuery(user).perform();
}

Future<void> signOut() {
  return SignOutQuery().perform();
}

Future<CubeUser> updateUser(CubeUser user) {
  return UpdateUserQuery(user).perform();
}

Future<void> deleteUser(int userId) {
  return DeleteUserQuery.byId(userId).perform();
}

Future<void> deleteUserByExternalId(int externalId) {
  return DeleteUserQuery.byExternalId(externalId).perform();
}

Future<void> resetPassword(String email) {
  return ResetPasswordQuery(email).perform();
}

Future<PagedResult<CubeUser>> getAllUsers() {
  return GetUsersQuery.byFilter().perform();
}

Future<PagedResult<CubeUser>> getAllUsersByIds(Set<int> ids) {
  return GetUsersQuery.byFilter(RequestFilter(
          RequestFieldType.NUMBER, "id", QueryRule.IN, ids.join(",")))
      .perform();
}

Future<PagedResult<CubeUser>> getUsersByFullName(String fullName) {
  return GetUsersQuery.byIdentifier(FILTER_FULL_NAME, fullName).perform();
}

Future<PagedResult<CubeUser>> getUsersByTags(Set<String> tags) {
  return GetUsersQuery.byIdentifier(FILTER_TAGS, tags.join(",")).perform();
}

Future<CubeUser> getUserById(int id) {
  return GetUserQuery.byId(id).perform();
}

Future<CubeUser> getUserByIdentifier(
    String identifierName, String identifierValue) {
  return GetUserQuery.byIdentifier(identifierName, identifierValue).perform();
}

Future<CubeUser> getUserByLogin(String login) {
  return getUserByIdentifier(FILTER_LOGIN, login);
}

Future<CubeUser> getUserByEmail(String email) {
  return getUserByIdentifier(FILTER_EMAIL, email);
}

Future<CubeUser> getUserByFacebookId(String id) {
  return getUserByIdentifier(FILTER_FACEBOOK_ID, id);
}

Future<CubeUser> getUserByTwitterId(String id) {
  return getUserByIdentifier(FILTER_TWITTER_ID, id);
}

Future<CubeUser> getUserByPhoneNumber(String phone) {
  return getUserByIdentifier(FILTER_PHONE, phone);
}

Future<CubeUser> getUserByExternalId(int externalId) {
  return GetUserQuery.byExternal(externalId).perform();
}

Future<AddressBookResult> uploadAddressBook(List<CubeContact> contacts,
    [bool force, String udid]) {
  return UploadAddressBookQuery(contacts, force, udid).perform();
}

Future<List<CubeContact>> getAddressBook([String udid]) {
  return GetAddressBookQuery(udid).perform();
}

Future<List<CubeUser>> getRegisteredUsersFromAddressBook(bool compact,
    [String udid]) {
  return GetRegisteredUsers(compact, udid).perform();
}
