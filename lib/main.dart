import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    return MaterialApp(
      title: 'WebP Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(title: 'Flutter WebP Converter'),
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

  void _pickImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles();
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
          _selectedFilePath = null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_selectedFilePath != null)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      p.basename(_selectedFilePath!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Image.file(
                        File(_selectedFilePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            Text(_status),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                textStyle: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              onPressed: _pickImage,
              child: const Text('이미지 선택'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                textStyle: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              onPressed: (_selectedFilePath != null) ? _convertImage : null,
              child: const Text('WebP로 변환'),
            ),
          ],
        ),
      ),
    );
  }
}
