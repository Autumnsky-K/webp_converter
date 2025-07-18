import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:path_provider/path_provider.dart';

class WebpConverter {
  static File _getCWebpExecutable() {
    final File mainExecutable = File(Platform.resolvedExecutable);
    final Directory executableDir = mainExecutable.parent;
    return File(p.join(executableDir.path, 'cwebp'));
  }

  static Future<String?> convertToWebP(
    String inputPath, {
    double quality = 75,
    bool lossless = false,
    int method = 4,
    List<String> metadata = const ['all'],
  }) async {
    try {
      final File cwebp = _getCWebpExecutable();

      if (!cwebp.existsSync()) {
        return null;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String inputFileName = p.basenameWithoutExtension(inputPath);
      final String tempOutputPath = p.join(
        tempDir.path,
        '${inputFileName}_${DateTime.now().millisecondsSinceEpoch}.webp',
      );

      final List<String> args = [];

      if (lossless) {
        args.add('-lossless');
      } else {
        args.add('-q');
        args.add(quality.round().toString());
      }

      args.add('-m');
      args.add(method.toString());

      if (metadata.isNotEmpty) {
        args.add('-metadata');
        args.add(metadata.join(','));
      }

      args.addAll([
        inputPath,
        '-o',
        tempOutputPath,
      ]);

      final ProcessResult result = await Process.run(cwebp.path, args);

      if (result.exitCode == 0) {
        return tempOutputPath;
      } else {
        debugPrint('''cwebp 실행 실패:
                  result.stderr: ${result.stderr}
                  result.stdout: ${result.stdout}
               ''');
        return null;
      }
    } catch (e) {
      debugPrint('변환 중 오류 발생: $e');
      return null;
    }
  }
}
