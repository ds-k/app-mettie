import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mettie/data/legacy_model_cleanup.dart';

void main() {
  late Directory docs, support;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('docs');
    support = Directory.systemTemp.createTempSync('support');
  });

  tearDown(() {
    docs.deleteSync(recursive: true);
    support.deleteSync(recursive: true);
  });

  test('v1.0 모델 파일과 다운로드 조각만 지운다', () async {
    File('${docs.path}/gemma-4-E2B-it.litertlm').writeAsBytesSync(List.filled(1000, 1));
    File('${docs.path}/old.task').writeAsBytesSync(List.filled(10, 1));
    File('${docs.path}/keep.json').writeAsStringSync('{}');
    File('${support.path}/com.bbflight.background_downloader123').writeAsBytesSync(List.filled(5, 1));
    File('${support.path}/other.db').writeAsStringSync('x');

    final freed = await cleanupLegacyModelFiles(documents: docs, support: support);

    expect(freed, 1015);
    expect(File('${docs.path}/gemma-4-E2B-it.litertlm').existsSync(), isFalse);
    expect(File('${docs.path}/keep.json').existsSync(), isTrue);
    expect(File('${support.path}/other.db').existsSync(), isTrue);
  });

  test('지울 파일이 없으면 0', () async {
    expect(await cleanupLegacyModelFiles(documents: docs, support: support), 0);
  });
}
