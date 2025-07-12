import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:path_provider/path_provider.dart';

class WebpConverter {
  static File _getCWebpExecutable() {
    final File mainExecutable = File(Platform.resolvedExecutable);
    final Directory executableDir = mainExecutable.parent;
    return File(p.join(executableDir.path, 'cwebp'));
  }

  static Future<String?> convertToWebP(String inputPath) async {
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

      final ProcessResult result = await Process.run(cwebp.path, [
        inputPath,
        '-o',
        tempOutputPath,
      ]);

      if (result.exitCode == 0) {
        return tempOutputPath;
      } else {
        return '''cwebp 실행 실패:
                  result.stderr: ${result.stderr}
                  result.stdout: ${result.stdout}
               ''';
      }
    } catch (e) {
      return '변환 중 오류 발생: $e';
    }
  }
}
