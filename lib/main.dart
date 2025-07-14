import 'dart:io';
import 'dart:typed_data';

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
  String? _selectedFilePath;
  String _status = '이미지를 선택해주세요';
  bool _isConverting = false;

  void _pickImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path!;
          _status = '선택된 이미지: ${p.basename(_selectedFilePath!)}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '오류 발생: $e';
      });
    }
  }

  Future<void> _convertImage() async {
    if (_selectedFilePath == null) {
      setState(() {
        _status = '이미지를 선택해주세요';
      });
      return;
    }

    setState(() {
      _isConverting = true;
      _status = '변환 중...';
    });

    String? tempWebPPath;
    try {
      tempWebPPath = await WebpConverter.convertToWebP(_selectedFilePath!);
      if (tempWebPPath == null) {
        setState(() {
          _status = '변환 실패';
        });
        return;
      }

      final File tempFile = File(tempWebPPath);
      final Uint8List fileBytes = await tempFile.readAsBytes();
      final String suggestedFileName =
          '${p.basenameWithoutExtension(_selectedFilePath!)}.webp';

      final String? resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'WebP 파일을 저장해주세요',
        fileName: suggestedFileName,
        bytes: fileBytes,
      );

      if (resultPath != null) {
        setState(() {
          _status = '${p.basename(resultPath)}에 저장 되었습니다.';
        });
      } else {
        setState(() {
          _status = '저장을 취소했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _status = '오류 발생: $e';
      });
    } finally {
      if (tempWebPPath != null) {
        final File tempFile = File(tempWebPPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
      setState(() {
        _isConverting = false;
        _selectedFilePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_selectedFilePath != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '선택된 이미지',
                          style: CupertinoTheme.of(
                            context,
                          ).textTheme.navTitleTextStyle,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.file(
                              File(_selectedFilePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.basename(_selectedFilePath!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
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
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(color: CupertinoColors.secondaryLabel),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        onPressed: _isConverting ? null : _pickImage,
                        child: const Text('이미지 선택'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: _selectedFilePath != null && !_isConverting
                            ? _convertImage
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
      ),
    );
  }
}
