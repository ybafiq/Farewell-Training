import 'package:flutter/material.dart';

import '../app.dart';

/// The amber strip that appears when we are running the fallback model.
///
/// Never hide this. An audience being shown "AI detecting crop disease" when
/// the model is actually detecting coffee cups is how trust gets lost.
class FallbackNotice extends StatelessWidget {
  const FallbackNotice({super.key, required this.onHelp});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColours.amber,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onHelp,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'DEMO MODEL - detects everyday objects, not leaves. Tap to fix.',
                  style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen error state. Shown when the model genuinely will not load, so
/// the app explains itself instead of showing a black rectangle.
class ModelErrorScreen extends StatelessWidget {
  const ModelErrorScreen({
    super.key,
    required this.message,
    required this.modelPath,
    required this.onRetry,
  });

  final String message;
  final String modelPath;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColours.clay, size: 48),
              const SizedBox(height: 18),
              const Text(
                'The model would not load',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text('Tried to load:', style: _dim),
              Text(modelPath, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              const SizedBox(height: 14),
              Text(message, style: _dim),
              const SizedBox(height: 24),
              Text('Things to check, in order:', style: _dim),
              const SizedBox(height: 8),
              ..._checks.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('-  '),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, height: 1.35))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _dim = TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.4);

  static const _checks = <String>[
    'Is the file named exactly leaf.tflite, in assets/models/ ?',
    'Is assets/models/ listed under flutter: assets: in pubspec.yaml ?',
    'Did you run flutter clean, then flutter pub get, after adding it?',
    'Was the model exported with format=tflite from Ultralytics?',
    'On the demo model: is the phone on wifi? It downloads once on first launch.',
  ];
}
