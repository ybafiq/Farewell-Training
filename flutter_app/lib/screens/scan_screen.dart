import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../app.dart';
import '../model_source.dart';
import '../verdict.dart';
import '../widgets/notice.dart';
import '../widgets/stats_bar.dart';
import '../widgets/verdict_banner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final YOLOViewController _controller = YOLOViewController();

  ModelSource? _source;
  String? _loadError;

  Verdict _verdict = Verdict.nothing;
  String _label = '';
  double _confidence = 0;

  double _fps = 0;
  double _ms = 0;

  double _threshold = 0.45;
  bool _frozen = false;
  bool _torch = false;

  @override
  void initState() {
    super.initState();
    _resolveModel();
  }

  Future<void> _resolveModel() async {
    setState(() {
      _source = null;
      _loadError = null;
    });
    final source = await ModelSource.resolve();
    if (!mounted) return;
    setState(() => _source = source);
  }

  void _onResult(List<YOLOResult> results) {
    if (_frozen || !mounted) return;

    final top = VerdictReader.best(results);
    if (top == null) {
      if (_verdict != Verdict.nothing) {
        setState(() {
          _verdict = Verdict.nothing;
          _label = '';
          _confidence = 0;
        });
      }
      return;
    }

    setState(() {
      _verdict = VerdictReader.classify(top.className);
      _label = top.className;
      _confidence = top.confidence;
    });
  }

  void _onMetrics(YOLOPerformanceMetrics m) {
    if (!mounted) return;
    setState(() {
      _fps = m.fps;
      _ms = m.processingTimeMs;
    });
  }

  Future<void> _toggleFreeze() async {
    // Holding the picture still is the single most useful thing on stage -
    // it lets you talk about a detection instead of chasing it around.
    if (_frozen) {
      await _controller.resume();
    } else {
      await _controller.pause();
    }
    if (!mounted) return;
    setState(() => _frozen = !_frozen);
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) return;
    setState(() => _torch = _controller.isTorchEnabled);
  }

  Future<void> _capture() async {
    final Uint8List? shot = await _controller.capturePhoto();
    if (!mounted || shot == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColours.dark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              child: Image.memory(shot),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColours.dark,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is not the leaf model',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'No trained model was found, so the app is running a general '
              'purpose model that detects everyday objects. It proves the '
              'camera and the detection pipeline work - nothing more.\n\n'
              'To use your own model:',
              style: TextStyle(fontSize: 14, height: 1.45, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            _step('1', 'Train it (Colab notebook or scripts/2_train.py)'),
            _step('2', 'Export it (scripts/3_export_tflite.py)'),
            _step('3', 'Rename model_int8.tflite to leaf.tflite'),
            _step('4', 'Drop it into flutter_app/assets/models/'),
            _step('5', 'flutter clean && flutter pub get && flutter run --release'),
          ],
        ),
      ),
    );
  }

  Widget _step(String n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: AppColours.moss,
              child: Text(
                n,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColours.dark,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.35)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final source = _source;

    if (_loadError != null && source != null) {
      return ModelErrorScreen(
        message: _loadError!,
        modelPath: source.path,
        onRetry: _resolveModel,
      );
    }

    if (source == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColours.moss),
              SizedBox(height: 18),
              Text('Looking for a model...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The camera and the boxes. The plugin draws the overlays natively,
          // which is why they never lag behind the picture.
          YOLOView(
            modelPath: source.path,
            task: source.task,
            controller: _controller,
            confidenceThreshold: _threshold,
            iouThreshold: 0.5,
            useGpu: true,
            streamingConfig: YOLOStreamingConfig.minimal(),
            onResult: _onResult,
            onPerformanceMetrics: _onMetrics,
            onModelLoad: (path, task) => debugPrint('model loaded: $path'),
            onModelError: (error, path, task) {
              if (!mounted) return;
              setState(() => _loadError = error.toString());
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  VerdictBanner(
                    verdict: _verdict,
                    label: _label,
                    confidence: _confidence,
                    frozen: _frozen,
                  ),
                  if (source.isFallback) ...[
                    const SizedBox(height: 8),
                    FallbackNotice(onHelp: _showSetupHelp),
                  ],
                  const Spacer(),
                  StatsBar(fps: _fps, milliseconds: _ms, modelLabel: source.label),
                  const SizedBox(height: 10),
                  _controls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Sensitivity',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _threshold,
                  min: 0.1,
                  max: 0.9,
                  divisions: 16,
                  activeColor: AppColours.moss,
                  label: _threshold.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _threshold = v),
                  onChangeEnd: (v) => _controller.setConfidenceThreshold(v),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  _threshold.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _button(
                icon: _frozen ? Icons.play_arrow : Icons.pause,
                label: _frozen ? 'Resume' : 'Hold',
                onTap: _toggleFreeze,
                highlight: _frozen,
              ),
              _button(
                icon: _torch ? Icons.flashlight_on : Icons.flashlight_off,
                label: 'Light',
                onTap: _toggleTorch,
                highlight: _torch,
              ),
              _button(
                icon: Icons.camera_alt_outlined,
                label: 'Snap',
                onTap: _capture,
              ),
              _button(
                icon: Icons.cameraswitch_outlined,
                label: 'Flip',
                onTap: () => _controller.switchCamera(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _button({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: highlight ? AppColours.moss : Colors.white, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: highlight ? AppColours.moss : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
