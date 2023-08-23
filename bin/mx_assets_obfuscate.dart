import 'dart:io';

import 'package:args/args.dart';
import 'package:mx_assets_obfuscate/mx_assets_obfuscate.dart';

void main(List<String> arguments) {
  var parser = ArgParser();
  parser.addOption('length', abbr: 'l', defaultsTo: '10', help: '混淆字串長度');
  parser.addFlag('help', abbr: 'h', help: '幫助');

  var result = parser.parse(arguments);

  print('${result['length']}');
  if (result['help']) {
    print(parser.usage);
    return;
  }

  final length = int.tryParse(result['length']) ?? 10;

  final rootPath = Directory.current.path;

  // 混淆檔案
  final assetsDetector = AssetsDetector(length);

  // 套用混淆到專案
  final projectDetector = ProjectDetector();

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
