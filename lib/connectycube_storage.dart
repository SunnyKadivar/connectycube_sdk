import 'dart:io';

import 'connectycube_core.dart';
import 'src/storage/models/cube_file.dart';
import 'src/storage/query/storage_queries.dart';

export 'connectycube_core.dart';

export 'src/storage/models/cube_file.dart';
export 'src/storage/query/storage_queries.dart';
export 'src/storage/utils/storage_utils.dart';

Future<CubeFile> uploadFile(File file, [bool public]) {
  return uploadFileWithProgress(file, isPublic: public);
}

Future<CubeFile> uploadFileWithProgress(File file,
    {bool isPublic, Function(int progress) onProgress}) {
  return UploadFileQuery(file, isPublic: isPublic, onProgress: onProgress)
      .perform();
}

Future<CubeFile> getCubeFile(int fileId) {
  return GetBlobByIdQuery(fileId).perform();
}

Future<PagedResult<CubeFile>> getCubeFiles([Map<String, dynamic> params]) {
  return GetBlobsQuery(params).perform();
}

Future<CubeFile> updateCubeFile(CubeFile file, [bool isNew]) {
  return UpdateBlobQuery(file, isNew).perform();
}

Future<void> deleteFile(int fileId) {
  return DeleteBlobByIdQuery(fileId).perform();
}
