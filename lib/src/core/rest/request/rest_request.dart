import 'dart:convert';

import 'package:http/http.dart';
import 'package:uuid/uuid.dart';

import '../response/rest_response.dart';
import '../../utils/string_utils.dart';

class RestRequest {
  String _uuid = Uuid().v4();
  Map<String, String> _headers = {'Content-type': 'application/json'};
  Map<String, dynamic> _params = Map();
  String _body;
  RequestMethod _method = RequestMethod.GET;
  String _url;

  Map<String, dynamic> get params => _params;

  get headers => _headers;

  set method(RequestMethod method) => _method = method;

  Future<RestResponse> perform() {
    Future<Response> response;

    switch (_method) {
      case RequestMethod.GET:
        response = get(_getUrl(), headers: _headers);
        break;

      case RequestMethod.POST:
        response = post(_getUrl(), headers: _headers, body: _getBody());
        break;

      case RequestMethod.PUT:
        response =
            put(_getUrl(), headers: _headers, body: _getBody(), encoding: utf8);
        break;

      case RequestMethod.PATCH:
        response = patch(_getUrl(),
            headers: _headers, body: _getBody(), encoding: utf8);
        break;

      case RequestMethod.DELETE:
        response = delete(_getUrl(), headers: _headers);
        break;

      default:
        response = get(_getUrl(), headers: _headers);
    }

    return RestResponse(response, _uuid).getResponse();
  }

  setUrl(String url) => this._url = url;

  setMethod(RequestMethod method) => this._method = method;

  setBody(String body) => this._body = body;

  String _getUrl() {
    if (_method == RequestMethod.GET || _method == RequestMethod.DELETE) {
      String stringParams = _prepareParamsUrl(_params);
      if (!isEmpty(stringParams) && !_url.contains(stringParams)) {
        _url = _url + "?$stringParams";
      }
    }

    return _url;
  }

  String _getBody() {
    if (_body != null && _body.isNotEmpty) return _body;

    return _body = _prepareBody();
  }

  @override
  String toString() {
    return "=========================================================\n" +
        "=== REQUEST ==== $_uuid ===\n"
            "REQUEST\n  ${_method.toString().split('.').last} ${_getUrl()} \n"
            "HEADERS\n  $_headers\n"
            "BODY\n  ${_method == RequestMethod.GET || _method == RequestMethod.DELETE ? "" : _getBody()}\n";
  }

  String _prepareBody() {
    return jsonEncode(_params);
  }
}

// Returns params string only, e.g.
// application_id=774&auth_key=aY7WwSRmu2-GbfA&nonce=1451135156
String _prepareParamsUrl(Map<String, dynamic> parameters) {
  StringBuffer stringBuffer = StringBuffer();

  // Add parameters
  //
  if (parameters == null || parameters.isEmpty) return EMPTY_STRING;

  for (String key in parameters.keys) {
    String value = parameters[key].toString();
    if (value != null) {
      String encodedValue = value;
      try {
        encodedValue = Uri.encodeComponent(value);
      } catch (e) {
        e.printStackTrace();
        encodedValue = value;
      }
      stringBuffer.write("$key=$encodedValue&");
    }
  }

  String resultString = stringBuffer.toString();

  return stringBuffer.toString().substring(0, resultString.length - 1);
}

enum RequestMethod { GET, POST, PUT, PATCH, DELETE }
