import 'package:flutter/material.dart';

import '../app.dart';
import '../verdict.dart';

/// The big coloured answer at the top of the screen.
///
/// Deliberately huge. A field officer holds the phone at arm's length in
/// sunlight; they should be able to read this without squinting.
class VerdictBanner extends StatelessWidget {
  const VerdictBanner({
    super.key,
    required this.verdict,
    required this.label,
    required this.confidence,
    required this.frozen,
  });

  final Verdict verdict;
  final String label;
  final double confidence;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final (colour, headline, icon) = switch (verdict) {
      Verdict.healthy => (
          AppColours.forest,
          'HEALTHY',
          Icons.check_circle_outline,
        ),
      Verdict.unhealthy => (
          AppColours.clay,
          'NOT HEALTHY',
          Icons.report_problem_outlined,
        ),
      Verdict.nothing => (
          Colors.black.withValues(alpha: 0.55),
          'POINT AT A LEAF',
          Icons.center_focus_weak,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (verdict != Verdict.nothing)
                  Text(
                    '$label  -  ${(confidence * 100).round()}% sure',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          if (frozen)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.pause_circle_filled, color: Colors.white, size: 26),
            ),
        ],
      ),
    );
  }
}
