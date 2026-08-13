// Leaf Scanner - live healthy / unhealthy leaf detection.
//
// Entry point only. The interesting parts are:
//   lib/model_source.dart      which model file we load, and what to do if there isn't one
//   lib/screens/scan_screen.dart   the camera screen
//   lib/verdict.dart           turning detections into HEALTHY / NOT HEALTHY

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only. A demo that rotates unexpectedly on stage is a demo that fails.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const LeafScannerApp());
}
