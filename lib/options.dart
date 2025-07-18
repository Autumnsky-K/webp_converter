import 'package:flutter/cupertino.dart';

class Options {
  final double quality;
  final bool lossless;
  final int method;
  final List<String> metadata;

  const Options({
    required this.quality,
    required this.lossless,
    required this.method,
    required this.metadata,
  });
}

class OptionsPage extends StatefulWidget {
  final Options initialOptions;

  const OptionsPage({super.key, required this.initialOptions});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  late double _lossyQuality;
  late bool _lossless;
  late int _method;
  late List<String> _metadata;
  late final TextEditingController _qualityController;

  double get _effectiveQuality => _lossless ? 100 : _lossyQuality;

  @override
  void initState() {
    super.initState();
    final Options options = widget.initialOptions;
    _lossless = options.lossless;
    _method = options.method;
    _metadata = List<String>.from(options.metadata);
    _lossyQuality = options.lossless ? 75 : options.quality;

    _qualityController = TextEditingController(
      text: _effectiveQuality.round().toString(),
    );

    _qualityController.addListener(() {
      final String text = _qualityController.text;
      if (text.isEmpty) {
        setState(() {
          _lossyQuality = 0;
        });
        return;
      }
      final double? value = double.tryParse(text);
      if (value != null) {
        if (value < 0) {
          _qualityController.text = '0';
        } else if (value > 100) {
          _qualityController.text = '100';
        }
      }
    });
  }

  @override
  void dispose() {
    _qualityController.dispose();
    super.dispose();
  }

  void _checkLossless(bool value) {
    setState(() {
      _lossless = value;
      _qualityController.text = _effectiveQuality.round().toString();
    });
  }

  void _showMetadataPicker(BuildContext context) {
    final List<String> availableMetadata = [
      'all',
      'none',
      'exif',
      'icc',
      'xmp',
    ];

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        final List<String> tempSelected = List<String>.from(_metadata);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return CupertinoActionSheet(
              title: const Text('Select Metadata'),
              actions: availableMetadata.map((item) {
                return CupertinoActionSheetAction(
                  child: Row(
                    children: [
                      Text(item),
                      const Spacer(),
                      if (tempSelected.contains(item))
                        const Icon(CupertinoIcons.check_mark),
                    ],
                  ),
                  onPressed: () {
                    modalSetState(() {
                      if (item == 'all') {
                        tempSelected.clear();
                        tempSelected.add('all');
                      } else if (item == 'none') {
                        tempSelected.clear();
                        tempSelected.add('none');
                      } else {
                        tempSelected.remove('all');
                        tempSelected.remove('none');
                        if (tempSelected.contains(item)) {
                          tempSelected.remove(item);
                        } else {
                          tempSelected.add(item);
                        }
                      }
                    });
                  },
                );
              }).toList(),
              cancelButton: CupertinoActionSheetAction(
                child: const Text('Done'),
                onPressed: () {
                  setState(() {
                    _metadata.clear();
                    if (tempSelected.isEmpty) {
                      _metadata.add('none');
                    } else {
                      _metadata.addAll(tempSelected);
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Options'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            final Options newOptions = Options(
              quality: _effectiveQuality,
              lossless: _lossless,
              method: _method,
              metadata: _metadata,
            );
            Navigator.of(context).pop(newOptions);
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lossless'),
                      CupertinoSwitch(
                        value: _lossless,
                        onChanged: _checkLossless,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quality'),
                      SizedBox(
                        width: 50,
                        child: CupertinoTextField(
                          controller: _qualityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          enabled: !_lossless,
                          onChanged: (value) {
                            final double? quality = double.tryParse(value);
                            if (quality != null &&
                                quality >= 0 &&
                                quality <= 100) {
                              setState(() {
                                _lossyQuality = quality;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  CupertinoSlider(
                    value: _effectiveQuality,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: _lossless
                        ? null
                        : (value) {
                            setState(() {
                              _lossyQuality = value;
                              _qualityController.text = value
                                  .round()
                                  .toString();
                            });
                          },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Method'), Text(_method.toString())],
                  ),
                  CupertinoSlidingSegmentedControl<int>(
                    groupValue: _method,
                    children: const {
                      0: Text('0'),
                      1: Text('1'),
                      2: Text('2'),
                      3: Text('3'),
                      4: Text('4'),
                      5: Text('5'),
                      6: Text('6'),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _method = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '압축 방법(compression method)을 지정하며, 인코딩 속도와 압축된 파일의 품질 간의 균형을 조절합니다. 값의 범위는 0 ~ 6이며, 값이 높을수록 압축 효율이 높아지는 대신, 인코딩 속도가 느려집니다.',
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metadata'),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _showMetadataPicker(context),
                        child: Text(_metadata.join(', ')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
