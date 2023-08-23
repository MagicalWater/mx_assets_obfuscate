/// 檢測圖片格式工具
/// 具體檢測方式參考[https://en.wikipedia.org/wiki/List_of_file_signatures]
/// apng檢測方式參考[https://stackoverflow.com/questions/62367134/how-do-i-detect-apng-in-python]
class ImageFormatDetector {

  ImageFormatDetector._();

  /// 檢測一個二進位的檔案是否為圖片的各種格式
  /// [bytes] - 二進位檔案
  static ImageFormat detect(List<int> bytes) {
    // 判斷檔案的開頭是否為PNG檔案
    if (_isPng(bytes)) {
      // 進一步判斷是否為apng
      if (_isApng(bytes)) {
        return ImageFormat.apng;
      } else {
        return ImageFormat.png;
      }
    }

    // 判斷檔案的開頭是否為JPG檔案
    if (_isJpg(bytes)) {
      return ImageFormat.jpg;
    }

    // 判斷檔案的開頭是否為GIF檔案
    if (_isGif(bytes)) {
      return ImageFormat.gif;
    }

    // 判斷檔案的開頭是否為BMP檔案
    if (_isBmp(bytes)) {
      return ImageFormat.bmp;
    }

    // 判斷檔案的開頭是否為WEBP檔案
    if (_isWebp(bytes)) {
      return ImageFormat.webp;
    }

    // 判斷檔案的開頭是否為TIFF檔案
    if (_isTiff(bytes)) {
      return ImageFormat.tiff;
    }

    // 判斷檔案的開頭是否為ICO檔案
    if (_isIco(bytes)) {
      return ImageFormat.ico;
    }

    // 未知的檔案格式
    return ImageFormat.unknown;
  }

  /// 檢測檔案是否為PNG格式
  /// [bytes] - 二進位檔案
  static bool _isPng(List<int> bytes) {
    // png可能擁有的格式
    final pngFormat = [
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    ];

    return _checkFormat(pngFormat, bytes);
  }

  /// 如果是png的話, 需要再往下檢測是否為apng
  /// [bytes] - 二進位檔案
  static bool _isApng(List<int> bytes) {
    // apng的acTL模塊
    final acTLSequence = [0x61, 0x63, 0x54, 0x4C];

    // apng的iDAT模塊
    final iDATSequence = [0x49, 0x44, 0x41, 0x54];

    // 尋找子列表
    int findSublist(List<int> list, List<int> sublist) {
      for (int i = 0; i <= list.length - sublist.length; i++) {
        for (int j = 0; j < sublist.length; j++) {
          if (list[i + j] != sublist[j]) {
            break;
          }
          if (j == sublist.length - 1) {
            return i;
          }
        }
      }
      return -1;
    }

    final acTLIndex = findSublist(bytes, acTLSequence);

    if (acTLIndex >= 0) {
      final iDATIndex = findSublist(bytes, iDATSequence);

      if (iDATIndex >= 0 && acTLIndex < iDATIndex) {
        return true;
      }
    }

    return false;
  }

  /// 檢測檔案是否為JPG格式
  /// [bytes] - 二進位檔案
  static bool _isJpg(List<int> bytes) {
    // jpg可能擁有的格式
    final jpgFormat = [
      [0xFF, 0xD8, 0xFF, 0xE0],
      [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01],
      [0xFF, 0xD8, 0xFF, 0xEE],
      [0xFF, 0xD8, 0xFF, 0xE1, null, null, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00]
    ];

    return _checkFormat(jpgFormat, bytes);
  }

  /// 檢測檔案是否為GIF格式
  /// [bytes] - 二進位檔案
  static bool _isGif(List<int> bytes) {
    // gif可能擁有的格式
    final gifFormat = [
      [0x47, 0x49, 0x46, 0x38, 0x37, 0x61],
      [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]
    ];

    return _checkFormat(gifFormat, bytes);
  }

  /// 檢測檔案是否為BMP格式
  /// [bytes] - 二進位檔案
  static bool _isBmp(List<int> bytes) {
    // bmp可能擁有的格式
    final bmpFormat = [
      [0x42, 0x4D]
    ];

    return _checkFormat(bmpFormat, bytes);
  }

  /// 檢測檔案是否為WEBP格式
  /// [bytes] - 二進位檔案
  static bool _isWebp(List<int> bytes) {
    // webp可能擁有的格式
    final webpFormat = [
      [0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x45, 0x42, 0x50]
    ];

    return _checkFormat(webpFormat, bytes);
  }

  /// 檢測檔案是否為TIFF格式
  /// [bytes] - 二進位檔案
  static bool _isTiff(List<int> bytes) {
    // tiff可能擁有的格式
    final tiffFormat = [
      [0x49, 0x49, 0x2A, 0x00],
      [0x4D, 0x4D, 0x00, 0x2A]
    ];

    return _checkFormat(tiffFormat, bytes);
  }

  /// 檢測檔案是否為ICO格式
  /// [bytes] - 二進位檔案
  static bool _isIco(List<int> bytes) {
    // ico可能擁有的格式
    final icoFormat = [
      [0x00, 0x00, 0x01, 0x00]
    ];

    return _checkFormat(icoFormat, bytes);
  }

  /// 檢測格式是否包含在列表內
  static bool _checkFormat(List<List<int?>> formats, List<int> bytes) {
    // 檢測檔案是否為jpg格式
    for (final format in formats) {
      final bytesLength = bytes.length;
      final formatLength = format.length;
      if (bytesLength >= formatLength) {
        var isJpg = true;
        for (var i = 0; i < formatLength; i++) {
          if (format[i] != null && bytes[i] != format[i]) {
            isJpg = false;
            break;
          }
        }
        if (isJpg) {
          return true;
        }
      }
    }

    return false;
  }
}

enum ImageFormat {
  jpg,
  png,
  apng,
  gif,
  bmp,
  webp,
  tiff,
  ico,
  unknown,
}
