import 'package:flutter/services.dart' show rootBundle;
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// Where the model comes from, and whether it is the real one.
///
/// The app must never fail to start just because nobody has dropped a model in
/// yet. So:
///
///   1. If assets/models/leaf.tflite exists  -> use it. This is the real thing.
///   2. If it does not                       -> fall back to an official
///      Ultralytics model, which the plugin downloads and caches on first use,
///      and shout loudly in the UI that this is NOT a leaf model.
///
/// Point 2 is what stops a live demo dying in front of an audience.
class ModelSource {
  const ModelSource({
    required this.path,
    required this.task,
    required this.isFallback,
    required this.label,
  });

  /// Asset path or official model ID handed to YOLOView.
  final String path;

  final YOLOTask task;

  /// True when we could not find a trained leaf model and are running a
  /// general-purpose model instead.
  final bool isFallback;

  /// Shown in the UI.
  final String label;

  static const customAsset = 'assets/models/leaf.tflite';

  static Future<ModelSource> resolve() async {
    // rootBundle.load throws if the asset is not bundled. That is our test.
    try {
      await rootBundle.load(customAsset);
      return const ModelSource(
        path: customAsset,
        task: YOLOTask.detect,
        isFallback: false,
        label: 'Your leaf model',
      );
    } catch (_) {
      return ModelSource(
        path: _officialFallback(),
        task: YOLOTask.detect,
        isFallback: true,
        label: 'Demo model - everyday objects, NOT leaves',
      );
    }
  }

  static String _officialFallback() {
    try {
      final available = YOLO.officialModels(task: YOLOTask.detect);
      if (available.isNotEmpty) return available.first;
    } catch (_) {
      // The plugin could not list official models. Fall through to the literal.
    }
    return 'yolo26n';
  }
}
