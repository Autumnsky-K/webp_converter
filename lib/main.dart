import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webp_converter/options.dart';
import 'package:webp_converter/webp_converter.dart';
import 'package:path/path.dart' as p;
import 'package:webp_converter/license_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'WebP Converter',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: HomePage(title: 'WebP Converter'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _selectedFilePaths = [];
  String _status = '이미지를 선택해주세요';
  bool _isConverting = false;
  Options _options = const Options(
    quality: 75,
    lossless: false,
    method: 4,
    metadata: ['all'],
  );

  @override
  void initState() {
    super.initState();
    _addCwebpLicense();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addCwebpLicense() {
    LicenseRegistry.addLicense(() async* {
      final licenseText = await rootBundle.loadString('assets/CWEBP_LICENSE');
      yield LicenseEntryWithLineBreaks([
        'cwebp (Bundled Executable)',
      ], licenseText);
    });
  }

  void _pickImages() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          _selectedFilePaths = result.paths.map((path) => path!).toList();
          _status = '${_selectedFilePaths.length}개의 이미지가 선택되었습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _status = '오류 발생: $e';
      });
    }
  }

  Future<void> _convertImages() async {
    if (_selectedFilePaths.isEmpty) {
      setState(() {
        _status = '이미지를 선택해주세요';
      });
      return;
    }

    final String? outputDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '변환된 파일을 저장할 폴더를 선택하세요',
    );

    if (outputDirectory == null) {
      setState(() {
        _status = '폴더 선택이 취소되었습니다.';
      });
      return;
    }

    setState(() {
      _isConverting = true;
    });

    int successCount = 0;
    int totalCount = _selectedFilePaths.length;

    for (int i = 0; i < totalCount; i++) {
      final String inputPath = _selectedFilePaths[i];
      setState(() {
        _status = '변환 중... (${i + 1}/$totalCount)';
      });

      String? tempWebPPath;
      try {
        tempWebPPath = await WebpConverter.convertToWebP(
          inputPath,
          quality: _options.quality,
          lossless: _options.lossless,
          method: _options.method,
          metadata: _options.metadata,
        );
        if (tempWebPPath != null) {
          final File tempFile = File(tempWebPPath);
          final String outputFileName =
              '${p.basenameWithoutExtension(inputPath)}.webp';
          final String outputPath = p.join(outputDirectory, outputFileName);

          await tempFile.copy(outputPath);
          successCount++;
        }
      } catch (e) {
        debugPrint('오류 발생: $e');
      } finally {
        if (tempWebPPath != null) {
          final File tempFile = File(tempWebPPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }
    }

    setState(() {
      _status = '$totalCount개의 이미지 중 $successCount개 변환 완료';
      _isConverting = false;
      _selectedFilePaths = [];
    });
  }

  void _showLicensePage() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const CustomLicensePage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showOptionsPage() async {
    final Options? newOptions = await Navigator.of(context).push<Options>(
      CupertinoPageRoute(
        builder: (context) => OptionsPage(initialOptions: _options),
        fullscreenDialog: true,
      ),
    );
    if (newOptions != null) {
      setState(() {
        _options = newOptions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showOptionsPage,
              child: const Icon(CupertinoIcons.settings),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showLicensePage,
              child: const Icon(CupertinoIcons.info),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            if (_selectedFilePaths.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.separator),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListView.builder(
                      itemCount: _selectedFilePaths.length,
                      itemBuilder: (context, index) {
                        final filePath = _selectedFilePaths[index];
                        return CupertinoListTile(
                          title: Text(
                            p.basename(filePath),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              const Expanded(child: Center(child: Text('변환할 이미지 파일을 선택하세요.'))),
            if (_isConverting)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CupertinoActivityIndicator(radius: 20),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: _isConverting ? null : _pickImages,
                      child: const Text('이미지 선택'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _selectedFilePaths.isNotEmpty && !_isConverting
                          ? _convertImages
                          : null,
                      child: const Text('WebP로 변환'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// Helper for older Flutter versions
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  const CupertinoListTile({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: title,
    );
  }
}
