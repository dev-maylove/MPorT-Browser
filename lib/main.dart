import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: avoid expensive system UI calls; Mobile: edge-to-edge dark chrome.
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF06080F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // On web, ensure URL strategy without hash for cleaner links (optional).
  // usePathUrlStrategy requires flutter_web_plugins — enabled when dependency present.

  runApp(const MporTBrowserApp());
}
