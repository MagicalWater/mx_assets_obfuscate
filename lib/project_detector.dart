import 'dart:io';

import 'package:path/path.dart';

/// 專案檢測
class ProjectDetector {
  /// pubspec.yaml
  String? pubspecYamlPath;

  /// lib/res/images.dart
  String? imagesDartPath;

  /// 搜索pubspec以及images檔案
  void search(String projectPath) {
    pubspecYamlPath = join(projectPath, 'pubspec.yaml');
    imagesDartPath = join(projectPath, 'lib', 'res', 'images.dart');

    if (!File(pubspecYamlPath!).existsSync()) {
      print('沒有在以下路徑找到pubspec.yaml(將忽略套用): $pubspecYamlPath');
      pubspecYamlPath = null;
    }

    if (!File(imagesDartPath!).existsSync()) {
      print('沒有在以下路徑找到images.dart(將忽略套用): $imagesDartPath');
      imagesDartPath = null;
    }
  }

  /// 套用至pubspec.yaml
  void applyToPubspec(Map<String, String> map) {
    final pubspecFile = File(pubspecYamlPath!);
    final allLine = pubspecFile.readAsLinesSync();

    final assetsRegex = RegExp(r'-\x20*assets/images(.+)');
    for (int i = 0; i < allLine.length; i++) {
      final text = allLine[i];

      final match = assetsRegex.firstMatch(text);
      if (match != null && match.groupCount == 1) {
        final relativePath = match.group(1)!;
        final obfuscateRelativePath =
            relativePath.split('/').map((e) => map[e] ?? e).join('/');

        final replaceText =
            '${text.substring(0, match.start)}- assets/images$obfuscateRelativePath';

        allLine[i] = replaceText;
      }
    }

    // 將替換好的文字寫回去
    pubspecFile.writeAsStringSync(allLine.join('\n'));
  }

  /// 套用至images.dart
  void applyToImages(Map<String, String> map) {
    final pubspecFile = File(imagesDartPath!);
    final allLine = pubspecFile.readAsLinesSync();

    final assetsRegex = RegExp(r'assets/images(.+)"');
    for (int i = 0; i < allLine.length; i++) {
      final text = allLine[i];

      final match = assetsRegex.firstMatch(text);
      if (match != null && match.groupCount == 1) {
        final relativePath = match.group(1)!;
        final obfuscateRelativePath =
            relativePath.split('/').map((e) => map[e] ?? e).join('/');

        final replaceText =
            '${text.substring(0, match.start)}assets/images$obfuscateRelativePath";';

        allLine[i] = replaceText;
      }
    }

    // 將替換好的文字寫回去
    pubspecFile.writeAsStringSync(allLine.join('\n'));
  }
}
