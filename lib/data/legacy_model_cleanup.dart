import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// v1.0 온디바이스 AI(flutter_gemma)가 남긴 파일을 지운다.
///
/// - 모델: 앱 문서 폴더의 `*.litertlm`·`*.task` (v1.0은 약 2GB의 gemma-4-E2B-it.litertlm)
/// - Android 이어받기 조각: 앱 지원 폴더의 `com.bbflight.background_downloader*`
///
/// 앱을 켤 때마다 호출해도 지울 파일이 없으면 폴더 목록만 한 번 읽고 끝난다.
/// 실패해도 앱 동작에는 영향이 없으므로 예외를 밖으로 던지지 않는다.
Future<int> cleanupLegacyModelFiles({Directory? documents, Directory? support}) async {
  var freedBytes = 0;
  try {
    final docs = documents ?? await getApplicationDocumentsDirectory();
    final sup = support ?? await getApplicationSupportDirectory();
    final targets = <File>[
      ..._files(docs).where((f) => f.path.endsWith('.litertlm') || f.path.endsWith('.task')),
      ..._files(sup).where((f) => f.uri.pathSegments.last.startsWith('com.bbflight.background_downloader')),
    ];
    for (final f in targets) {
      try {
        freedBytes += await f.length();
        await f.delete();
      } catch (e) {
        debugPrint('legacy model cleanup: ${f.path} 삭제 실패 $e');
      }
    }
  } catch (e) {
    debugPrint('legacy model cleanup 실패: $e');
  }
  return freedBytes;
}

Iterable<File> _files(Directory dir) =>
    dir.existsSync() ? dir.listSync(followLinks: false).whereType<File>() : const [];
