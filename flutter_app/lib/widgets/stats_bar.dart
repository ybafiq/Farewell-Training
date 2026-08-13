import 'package:flutter/material.dart';

/// Live speed readout.
///
/// This is on screen for one reason: during the training session you can point
/// at it and say "that number is why we put the model on the phone instead of
/// sending photos to a server".
class StatsBar extends StatelessWidget {
  const StatsBar({
    super.key,
    required this.fps,
    required this.milliseconds,
    required this.modelLabel,
  });

  final double fps;
  final double milliseconds;
  final String modelLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _stat('${milliseconds.toStringAsFixed(0)} ms', 'per frame'),
          const SizedBox(width: 22),
          _stat(fps.toStringAsFixed(1), 'frames / sec'),
          const Spacer(),
          Flexible(
            child: Text(
              modelLabel,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          caption,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
