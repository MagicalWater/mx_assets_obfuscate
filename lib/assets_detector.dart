import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mx_assets_obfuscate/image_format_detector.dart';
import 'package:image_compression/image_compression.dart';
import 'package:path/path.dart';

class AssetsDetector {
  final allDir = <Directory>[];
  final allFile = <File>[];

  /// 圖片資源入口路徑
  String? imagesPath;

  /// 隨機字串映射表
  final randomStringMap = <String, String>{};

  /// 專案路徑
  String? projectPath;

  /// 混淆路徑
  final obfuscatePathList = <ObfuscatePath>[];

  /// 隨機字串長度
  final int randomStringLength;

  /// 資源路徑
  final String assetsPath;

  /// 排除路徑
  final List<String>? excludePath;

  /// 完整排除的路徑
  List<List<String>>? _excludeAbsolutePathList;

  AssetsDetector({
    required this.randomStringLength,
    required this.assetsPath,
    this.excludePath,
  });

  /// 搜索專案中的圖片資源
  bool searchImage(String projectPath) {
    this.projectPath = projectPath;
    allDir.clear();
    allFile.clear();

    imagesPath = join(projectPath, assetsPath);

    final assetsImageDir = Directory(imagesPath!);

    if (excludePath != null) {
      _excludeAbsolutePathList =
          excludePath!.map((e) => join(projectPath, e).split('/')).toList();
    }

    // 檢測路徑是否存在
    if (!assetsImageDir.existsSync()) {
      print('沒有在以下路徑找到圖片資源資料夾: $imagesPath');
      imagesPath = null;
      return false;
    }

    // 所有的圖片檔案
    assetsImageDir.listSync(recursive: true).forEach((element) {
      final path = element.path;
      // 忽略需要被排除的路徑
      if (_checkExcludePath(path)) {
        return;
      }

      // 忽略.DS_Store
      if (basename(element.path) == '.DS_Store') {
        return;
      }

      if (element.statSync().type == FileSystemEntityType.file) {
        allFile.add(File(element.path));
      } else if (element.statSync().type == FileSystemEntityType.directory) {
        allDir.add(Directory(element.path));
      }
    });

    return true;
  }

  /// 檢查某個路徑是否需要被排除
  bool _checkExcludePath(String path) {
    if (_excludeAbsolutePathList != null) {
      for (var excludePathList in _excludeAbsolutePathList!) {
        // 一個一個檢查是否包含米字旁
        final splitPath = path.split('/');
        if (splitPath.length >= excludePathList.length) {
          // 代表有可能符合排除路徑
          for (var i = 0; i < excludePathList.length; i++) {
            final pathElement = splitPath[i];
            final excludeElement = excludePathList[i].replaceAll('*', '.*');
            // print('檢查 $pathElement 是否符合 $excludeElement');
            final regex = RegExp(excludeElement);

            if (regex.hasMatch(pathElement)) {
              // 符合排除路徑
              // 檢查是否為最後一個路徑, 若是的話代表檢查通過
              if (i == excludePathList.length - 1) {
                return true;
              }
            } else {
              // print('不通過');
              // 不符合排除路徑
              break;
            }
          }
        }
      }
    }

    return false;
  }

  /// 將底下的圖片資源(1. 檔名, 2. 路徑)混淆
  void obfuscate() {
    if (imagesPath == null) {
      print('尚未取得圖片資源路徑, 請先執行 searchImage()');
      return;
    }

    obfuscatePathList.clear();

    // 先將所有的檔案隨機重新命名
    for (var element in allFile) {
      // 先取得檔案的路徑
      final filepath = element.path;

      // 去除圖片資源的路徑
      final relativePath = filepath.replaceAll(imagesPath!, '');

      // 開始針對路徑的每一層進行混淆
      final relativePathList = relativePath.split('/');
      relativePathList.removeAt(0);

      // 混淆後的路徑列表
      final obfuscateRelativePathList =
          relativePathList.map((e) => _randomString(e, 10)).toList();

      // 混淆後的相對路徑
      final obfuscatePath = obfuscateRelativePathList.join('/');

      // 混淆後的絕對路徑
      final obfuscateAbsolutePath = join(imagesPath!, obfuscatePath);

      // print('混淆後絕對: $imagesPath => $obfuscatePath => $obfuscateAbsolutePath');

      // 一層一層檢查資料夾是否存在
      File(obfuscateAbsolutePath).parent.createSync(recursive: true);

      element.renameSync(obfuscateAbsolutePath);

      compressImage(obfuscateAbsolutePath);

      obfuscatePathList.add(ObfuscatePath(filepath, obfuscateAbsolutePath));
    }

    // 接著將所有的資料夾也重新命名
    for (var element in allDir) {
      // 先取得檔案的路徑
      final directoryPath = element.path;

      // 去除圖片資源的路徑
      final relativePath = directoryPath.replaceAll(imagesPath!, '');

      // 開始針對路徑的每一層進行混淆
      final relativePathList = relativePath.split('/');
      relativePathList.removeAt(0);

      // 混淆後的路徑列表
      final obfuscateRelativePathList =
          relativePathList.map((e) => _randomString(e, 10)).toList();

      // 混淆後的相對路徑
      final obfuscatePath = obfuscateRelativePathList.join('/');

      // 混淆後的絕對路徑
      final obfuscateAbsolutePath = join(imagesPath!, obfuscatePath);

      if (!Directory(obfuscateAbsolutePath).existsSync()) {
        // 資料若不存在則創建
        element.renameSync(obfuscateAbsolutePath);
      }

      // 刪除原資料夾
      if (element.existsSync()) {
        element.deleteSync(recursive: true);
      }

      obfuscatePathList.add(ObfuscatePath(element.path, obfuscateAbsolutePath));
    }

    // // 檔案對應
    // for (var element in obfuscatePathList) {
    //   print('${element.originPath} -> ${element.obfuscatePath}');
    // }
    //
    // print('映射表');
    // randomStringMap.forEach((key, value) {
    //   print('$key -> $value');
    // });
  }

  /// 傳入一個字串
  /// 自動產生一個長度為[len]隨機字串
  /// 並將生產出的隨機字串存入映射表
  /// 若之後有重複字串出現, 則直接回傳已經存在的隨機字串
  String _randomString(String seed, int len) {
    if (seed.isEmpty) {
      return seed;
    }
    if (randomStringMap.containsKey(seed)) {
      return randomStringMap[seed]!;
    } else {
      final random = Random();
      final codeUnits = List.generate(len, (index) {
        final isUpper = random.nextBool();
        final charCode = random.nextInt(26) + (isUpper ? 65 : 97);
        return charCode;
      });
      final randomString = String.fromCharCodes(codeUnits);
      randomStringMap[seed] = randomString;
      return randomString;
    }
  }

  void compressImage(String imagePath) {
    final file = File(imagePath);

    final bytes = file.readAsBytesSync();

    // 取得圖片格式
    final imageFormat = ImageFormatDetector.detect(bytes);

    final input = ImageFile(
      rawBytes: file.readAsBytesSync(),
      filePath: file.path,
    );

    // print('檢測檔案格式($imageFormat): $imagesPath');

    switch (imageFormat) {
      case ImageFormat.jpg:
        final output = compress(
          ImageFileConfiguration(
            input: input,
            config: Configuration(outputType: OutputType.jpg),
          ),
        );
        File(imagePath).writeAsBytesSync(output.rawBytes);
        // print('壓縮前: ${input.rawBytes.length} 壓縮後: ${output.rawBytes.length}');
        break;
      case ImageFormat.png:
        final output = compress(
          ImageFileConfiguration(
            input: input,
            config: Configuration(outputType: OutputType.png),
          ),
        );
        File(imagePath).writeAsBytesSync(output.rawBytes);
        // print('壓縮前: ${input.rawBytes.length} 壓縮後: ${output.rawBytes.length}');
        break;
      case ImageFormat.apng:
        // apng壓縮完反而變大了, 不處理
        break;
      default:
        // 其餘不壓縮
        break;
    }
  }

  /// 輸出混淆路徑映射檔
  String outputObfuscateMap() {
    final file = File(join(projectPath!, 'assets_obfuscate_map.json'));
    final encoder = JsonEncoder.withIndent('  ');
    final prettyprint = encoder
        .convert(obfuscatePathList.map((e) => e.toMap(projectPath!)).toList());
    file.writeAsStringSync(prettyprint);
    return file.path;
  }
}

/// 路徑變更
class ObfuscatePath {
  /// 原始路徑
  final String originPath;

  /// 混淆後的路徑
  final String obfuscatePath;

  /// 建構子
  ObfuscatePath(this.originPath, this.obfuscatePath);

  @override
  String toString() {
    return 'originPath: $originPath, obfuscatePath: $obfuscatePath';
  }

  // 轉map, 只顯示相對路徑
  Map<String, dynamic> toMap(String rootPath) {
    String originRelativePath = originPath.replaceAll(rootPath, '');
    String obfuscateRelativePath = obfuscatePath.replaceAll(rootPath, '');

    // 去除開頭的/
    if (originRelativePath.startsWith('/')) {
      originRelativePath = originRelativePath.replaceFirst('/', '');
    }
    if (obfuscateRelativePath.startsWith('/')) {
      obfuscateRelativePath = obfuscateRelativePath.replaceFirst('/', '');
    }

    return {
      'originPath': originRelativePath,
      'obfuscatePath': obfuscateRelativePath,
    };
  }
}
