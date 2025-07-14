import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webp_converter/webp_converter.dart';
import 'package:path/path.dart' as p;

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
        primaryColor: CupertinoColors.systemPurple,
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

  void _pickImages() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          _selectedFilePaths = result.paths.map((path) => path!).toList();
          _status = '${_selectedFilePaths.length} 개의 이미지가 선택되었습니다.';
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
      dialogTitle: '변환된 파일을 저장할 폴더를 선택하세요.',
    );

    if (outputDirectory == null) {
      setState(() {
        _status = '폴더 선택이 취소되었습니다.';
      });
      return;
    }

    int successCount = 0;
    int totalCount = _selectedFilePaths.length;

    for (int i = 0; i < totalCount; i++) {
      final String inputPath = _selectedFilePaths[i];
      setState(() {
        _status = '변환 중... (${i + 1}/$totalCount)';
      });

      String? tempWebPPath;
      try {
        tempWebPPath = await WebpConverter.convertToWebP(inputPath);

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
      _selectedFilePaths.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
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
