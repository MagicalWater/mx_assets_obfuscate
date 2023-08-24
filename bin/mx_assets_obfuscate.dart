import 'dart:io';

import 'package:args/args.dart';
import 'package:mx_assets_obfuscate/mx_assets_obfuscate.dart';

void main(List<String> arguments) {
  var parser = ArgParser();
  parser.addOption('length', abbr: 'l', defaultsTo: '10', help: '混淆字串長度');
  parser.addOption('path',
      abbr: 'p', defaultsTo: 'assets/images', help: '進行壓縮混淆的資料夾(相對路徑)');
  parser.addOption('exclude', abbr: 'e', help: '排除的路徑(相對路徑), 多個路徑以,分隔');
  parser.addFlag('help', abbr: 'h', help: '幫助');

  final result = parser.parse(arguments);

  if (result['help']) {
    print(parser.usage);
    return;
  }

  final excludePath = result['exclude']?.split(',');
  final assetsPath = result['path'];
  final length = int.tryParse(result['length']) ?? 10;

  final rootPath = Directory.current.path;

  // 混淆檔案
  final assetsDetector = AssetsDetector(
    randomStringLength: length,
    assetsPath: assetsPath,
    excludePath: excludePath,
  );

  // 套用混淆到專案
  final projectDetector = ProjectDetector(
    assetsPath: assetsPath,
  );

  final assetsSuccess = assetsDetector.searchImage(rootPath);
  projectDetector.search(rootPath);

  if (assetsSuccess) {
    print('混淆開始...');
    assetsDetector.obfuscate();

    if (projectDetector.pubspecYamlPath != null) {
      print('套用至pubspec.yaml...');
      projectDetector.applyToPubspec(assetsDetector.randomStringMap);
    }

    if (projectDetector.imagesDartPath != null) {
      print('套用至images.dart...');
      projectDetector.applyToImages(assetsDetector.randomStringMap);
    }

    final obfuscateMapPath = assetsDetector.outputObfuscateMap();
    print('混淆路徑映射表: $obfuscateMapPath');
    print('混淆完畢');
  }
}
