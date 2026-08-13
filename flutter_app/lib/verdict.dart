import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// What we show in the big banner at the top of the screen.
enum Verdict { healthy, unhealthy, nothing }

/// Turns a list of detections into one answer.
///
/// A field officer does not want a list of eleven boxes. They want one word.
/// So we take the most confident detection and report that.
///
/// The rule for deciding which side a class name falls on is deliberately
/// simple and lives here, in one place, so you can change it without hunting
/// through the UI code:
///
///   * a class name containing "unhealthy", "sick", "disease", "blight",
///     "spot", "rust", "pest" or "damage"   -> NOT HEALTHY
///   * a class name containing "healthy"    -> HEALTHY
///   * anything else                        -> NOT HEALTHY
///
/// That last line is on purpose. If you retrain with four disease classes and
/// forget to update this file, the app errs towards flagging a problem rather
/// than quietly telling a field officer that a diseased plant is fine.
class VerdictReader {
  static const _unhealthyWords = <String>[
    'unhealthy', 'sick', 'disease', 'diseased', 'blight', 'spot',
    'rust', 'mildew', 'mould', 'mold', 'pest', 'damage', 'scab', 'rot',
  ];

  static Verdict classify(String className) {
    final name = className.toLowerCase();
    if (_unhealthyWords.any(name.contains)) return Verdict.unhealthy;
    if (name.contains('healthy')) return Verdict.healthy;
    return Verdict.unhealthy;
  }

  /// The single detection we report, or null if the model found nothing.
  static YOLOResult? best(List<YOLOResult> results) {
    if (results.isEmpty) return null;
    var top = results.first;
    for (final r in results) {
      if (r.confidence > top.confidence) top = r;
    }
    return top;
  }
}
