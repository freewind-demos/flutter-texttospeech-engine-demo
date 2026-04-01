import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TtsDemoApp());
}

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

class TtsDemoApp extends StatelessWidget {
  const TtsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TTS Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _textController = TextEditingController(
    text: '第一段。\n第二段会接在后面朗读。\n第三段。',
  );
  final _flutterTts = FlutterTts();

  static const int _rateMax = 45;
  static const int _defaultProgress = 5;

  int _rateProgress = _defaultProgress;
  bool _followSystem = true;
  String _status = '初始化中…';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _status = '正在朗读…');
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _status = '本段播放结束');
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _status = '错误: $msg');
    });

    if (mounted) setState(() => _status = '引擎已就绪（本机 TTS）');
  }

  /// flutter_tts 在 Android 上将 Dart 的 rate 乘 2 再交给 [TextToSpeech.setSpeechRate]，
  /// 且约定 Dart 侧 0.5 对应原生 1.0（正常语速）。与 Legado 的 (progress+5)/10 对齐：
  /// `(progress + 5) / 20` → 乘 2 后为原生 `(progress+5)/10`。
  Future<void> _applySpeechRate() async {
    if (_followSystem) {
      await _flutterTts.setSpeechRate(0.5);
    } else {
      await _flutterTts.setSpeechRate((_rateProgress + 5) / 20.0);
    }
  }

  Future<void> _speak() async {
    final segments = _textController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      setState(() => _status = '请输入至少一行文字');
      return;
    }

    await _flutterTts.stop();
    await _applySpeechRate();

    if (_isAndroid) {
      await _flutterTts.setQueueMode(0);
      await _flutterTts.speak(segments[0]);
      for (var i = 1; i < segments.length; i++) {
        await _flutterTts.setQueueMode(1);
        await _flutterTts.speak(segments[i]);
      }
    } else {
      await _flutterTts.awaitSpeakCompletion(true);
      for (final s in segments) {
        await _flutterTts.speak(s);
      }
    }

    if (mounted) {
      setState(() => _status = '已排队 ${segments.length} 段');
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _status = '已停止');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rateLabel = ((_rateProgress + 5) / 10).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('本机 TTS（flutter_tts）'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('每行一段；Android 上使用 QUEUE_FLUSH + QUEUE_ADD，与 Legado 一致。'),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _speak,
                    child: const Text('朗读'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _stop,
                    child: const Text('停止'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('语速约 $rateLabel×（相对原生 1.0）'),
                const Spacer(),
                const Text('跟随系统默认'),
                Switch(
                  value: _followSystem,
                  onChanged: (v) {
                    setState(() => _followSystem = v);
                    _applySpeechRate();
                  },
                ),
              ],
            ),
            Slider(
              value: _rateProgress.toDouble(),
              max: _rateMax.toDouble(),
              divisions: _rateMax,
              label: rateLabel,
              onChanged: _followSystem
                  ? null
                  : (v) {
                      setState(() => _rateProgress = v.round());
                    },
              onChangeEnd: (_) => _applySpeechRate(),
            ),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
