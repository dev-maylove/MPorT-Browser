import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'controllers/browser_controller.dart';
import 'features/home/new_tab_screen.dart';
import 'features/browser/browser_screen.dart';
import 'core/platform/native_bridge.dart';
import 'package:flutter/foundation.dart';

class MporTBrowserApp extends StatefulWidget {
  const MporTBrowserApp({super.key});

  @override
  State<MporTBrowserApp> createState() => _MporTBrowserAppState();
}

class _MporTBrowserAppState extends State<MporTBrowserApp> {
  late final BrowserController controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    controller = BrowserController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.initialize();
      String? deepLink;
      if (!kIsWeb) {
        NativeBridge.setOpenUrlListener((url) async {
          await controller.open(url);
          if (!mounted) return;
          // Ignore if navigator not ready yet
          final nav = Navigator.maybeOf(context);
          if (nav != null) {
            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => BrowserScreen(controller: controller),
              ),
              (route) => false,
            );
          }
        });
        deepLink = await NativeBridge.getInitialUrl();
        if (deepLink != null && deepLink.isNotEmpty) {
          await controller.open(deepLink);
        }
      }
      if (mounted) {
        setState(() => _ready = true);
        if (deepLink != null && deepLink.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BrowserScreen(controller: controller),
              ),
            );
          });
        }
      }
    });
  }

  ThemeData _buildTheme() {
    final base = AppTheme.darkTheme();
    GoogleFonts.config.allowRuntimeFetching = true;

    final inter = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppTheme.textPrimary,
      displayColor: AppTheme.textPrimary,
    );

    // FadeUpwards on all platforms — CupertinoPageTransitionsBuilder was
    // removed / unavailable in Flutter 3.47 analyzer surface.
    return base.copyWith(
      textTheme: inter,
      primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MPorT Browser',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      scrollBehavior: const _MportScrollBehavior(),
      home: _ready
          ? NewTabScreen(controller: controller)
          : const _BootSplash(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyanNeon.withValues(alpha: 0.35),
                    blurRadius: 56,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/mport_logo.png',
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.public_rounded,
                  size: 96,
                  color: AppTheme.cyanNeon,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'MPorT Browser',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.cyanNeon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MportScrollBehavior extends MaterialScrollBehavior {
  const _MportScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
