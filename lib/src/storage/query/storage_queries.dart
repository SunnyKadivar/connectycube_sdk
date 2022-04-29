import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../connectycube_core.dart';

import '../models/cube_file.dart';

class UploadFileQuery extends AutoManagedQuery<CubeFile> {
  File _file;
  bool isPublic;
  void Function(int progress) onProgress;
  int _progress;

  UploadFileQuery(this._file, {this.isPublic, this.onProgress});

  @override
  Future<CubeFile> perform() async {
    Completer completer = new Completer<CubeFile>();

    try {
      String uuid = Uuid().v4();

      CubeFile toCreate = CubeFile();
      toCreate.isPublic = isPublic ?? false;
      toCreate.name = basename(_file.path);
      toCreate.contentType = lookupMimeType(basename(_file.path));

      _CreateBlobQuery(toCreate).perform().then((cubeBlob) {
        toCreate.id = cubeBlob.id;
        toCreate.uid = cubeBlob.uid;

        _file.length().then((length) {
          String amazonParams = cubeBlob.fileObjectAccess.params;
          Uri decodedUri = Uri.parse(amazonParams);

          Map<String, String> params = decodedUri.queryParameters.map(
              (key, value) => MapEntry(key, Uri.decodeQueryComponent(value)));

          MultipartRequestProgressed multipartRequest =
              MultipartRequestProgressed(
            "POST",
            Uri(
                scheme: decodedUri.scheme,
                host: decodedUri.host,
                path: decodedUri.path),
            onProgress: (int bytes, int total) {
              final int newProgress = ((bytes / total) * 100).toInt();
              if (newProgress != _progress) {
                if (onProgress != null) {
                  onProgress(newProgress);
                }
                _progress = newProgress;
              }
            },
          );

          ByteStream stream = ByteStream(StreamView(_file.openRead()));
          MultipartFile multipartFile = MultipartFile('file', stream, length,
              filename: basename(_file.path),
              contentType: MediaType.parse(cubeBlob.contentType));

          multipartRequest.files.add(multipartFile);
          multipartRequest.fields.addAll(params);

          _logAmazonRequest(multipartRequest, uuid);

          multipartRequest.send().then((response) {
            _logAmazonResponse(response, uuid).then((voidValue) {
              if (response.statusCode == 201) {
                toCreate.size = length;

                DeclareBlobCompletedQuery(cubeBlob.id, length)
                    .perform()
                    .then((voidResult) {
                  toCreate.completedAt = DateTime.now();
                  completer.complete(toCreate);
                });
              }
            });
          });
        });
      }).catchError((error) {
        handelError(error);
        completer.completeError(error);
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  CubeFile processResult(String responseBody) {
    // not need override, in this case all logic process in UploadFileQuery class
    return null;
  }
}

void _logAmazonRequest(
    MultipartRequestProgressed multipartRequest, String uuid) {
  log("=========================================================\n" +
      "=== REQUEST ==== AMAZON === $uuid ===\n"
          "REQUEST\n  ${multipartRequest.method} ${multipartRequest.url.toString()} \n"
          "HEADERS\n  ${multipartRequest.headers}\n"
          "FIELDS\n  ${multipartRequest.fields}\n");
}

Future<void> _logAmazonResponse(StreamedResponse response, String uuid) async {
  String responseBody = await response.stream.bytesToString();
  log("*********************************************************\n" +
      "*** RESPONSE *** AMAZON *** ${response.statusCode} *** $uuid ***\n"
          "HEADERS\n  ${response.headers}\n"
          "RESPONSE\n  $responseBody\n");
}

class _CreateBlobQuery extends AutoManagedQuery<CubeFile> {
  CubeFile _cubeFile;

  _CreateBlobQuery(this._cubeFile);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.POST);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([BLOBS_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    if (isEmpty(_cubeFile.contentType) || isEmpty(_cubeFile.name)) {
      throw IllegalArgumentException("'content_type' and 'name' are required");
    }

    putValue(parameters, "blob", _cubeFile.toCreateBlobJson());
  }

  @override
  CubeFile processResult(String response) {
    return CubeFile.fromJson(jsonDecode(response)['blob']);
  }
}

class DeclareBlobCompletedQuery extends AutoManagedQuery<void> {
  int _blobId;
  int _blobSize;

  DeclareBlobCompletedQuery(this._blobId, this._blobSize);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.POST);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([BLOBS_ENDPOINT, _blobId, 'complete']));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    CubeFile cubeFile = CubeFile();
    cubeFile.size = _blobSize;

    putValue(parameters, "blob", cubeFile.toCompleteBlobJson());
  }

  @override
  void processResult(String response) {}
}

class GetBlobByIdQuery extends AutoManagedQuery<CubeFile> {
  int _blobId;

  GetBlobByIdQuery(this._blobId);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([BLOBS_ENDPOINT, _blobId]));
  }

  @override
  CubeFile processResult(String response) {
    return CubeFile.fromJson(jsonDecode(response)['blob']);
  }
}

class GetBlobsQuery extends AutoManagedQuery<PagedResult<CubeFile>> {
  Map<String, dynamic> _params;

  GetBlobsQuery([this._params]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.GET);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([BLOBS_ENDPOINT]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    if (_params != null && _params.isNotEmpty) {
      Map<String, dynamic> parameters = request.params;
      parameters.addAll(_params);
    }
  }

  @override
  PagedResult<CubeFile> processResult(String response) {
    return PagedResult<CubeFile>(
        response, (element) => CubeFile.fromJson(element['blob']));
  }
}

class UpdateBlobQuery extends AutoManagedQuery<CubeFile> {
  CubeFile _blob;
  bool _isNew;

  UpdateBlobQuery(this._blob, [this._isNew]);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.PUT);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([BLOBS_ENDPOINT, _blob.id]));
  }

  @override
  setParams(RestRequest request) {
    super.setParams(request);

    Map<String, dynamic> parameters = request.params;

    Map<String, dynamic> blobToUpdate = _blob.toCompleteBlobJson();

    blobToUpdate.remove('public');

    if (_isNew != null && _isNew) {
      blobToUpdate['new'] = 1;
    }

    putValue(parameters, 'blob', blobToUpdate);
  }

  @override
  CubeFile processResult(String response) {
    return CubeFile.fromJson(jsonDecode(response)['blob']);
  }
}

class DeleteBlobByIdQuery extends AutoManagedQuery<void> {
  int _blobId;

  DeleteBlobByIdQuery(this._blobId);

  @override
  void setMethod(RestRequest request) {
    request.setMethod(RequestMethod.DELETE);
  }

  @override
  setUrl(RestRequest request) {
    request.setUrl(buildQueryUrl([BLOBS_ENDPOINT, _blobId]));
  }

  @override
  void processResult(String response) {}
}

class MultipartRequestProgressed extends MultipartRequest {
  MultipartRequestProgressed(
    String method,
    Uri url, {
    this.onProgress,
  }) : super(method, url);

  final void Function(int bytes, int totalBytes) onProgress;

  @override
  ByteStream finalize() {
    final ByteStream byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final int total = this.contentLength;
    int bytes = 0;

    final streamTransformer = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );

    final stream = byteStream.transform(streamTransformer);

    return ByteStream(stream);
  }
}
