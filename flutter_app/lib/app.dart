import 'package:flutter/material.dart';

import 'screens/scan_screen.dart';

/// The green in here matches the training slides on purpose.
class AppColours {
  static const forest = Color(0xFF2C5F2D);
  static const moss = Color(0xFF97BC62);
  static const dark = Color(0xFF12241A);
  static const clay = Color(0xFF9A3F2B);
  static const amber = Color(0xFFB56E12);
  static const pale = Color(0xFFEDF3EA);
}

class LeafScannerApp extends StatelessWidget {
  const LeafScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaf Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColours.forest,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColours.dark,
      ),
      home: const ScanScreen(),
    );
  }
}
