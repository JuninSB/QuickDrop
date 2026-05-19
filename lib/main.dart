import 'package:flutter/material.dart';
import 'package:quickdrop/core/app_theme.dart';
import 'package:quickdrop/features/downloads/downloads_page.dart';
import 'package:quickdrop/features/home/home_page.dart';
import 'package:quickdrop/features/settings/settings_page.dart';
import 'package:quickdrop/services/download_service.dart';
import 'package:quickdrop/services/native_bridge.dart';
import 'package:quickdrop/services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsStore();
  await settings.load();
  final native = NativeBridge();
  final downloads = DownloadService(native);
  final clipboardUrl = await native.clipboardUrl();
  if (settings.autoClipboard) {
    await native.startClipboardMonitor();
    if (settings.autoOverlay && clipboardUrl != null) {
      await native.showOverlay(clipboardUrl);
    }
  }
  runApp(QuickDropApp(settings: settings, downloads: downloads, initialUrl: clipboardUrl));
}

class QuickDropApp extends StatefulWidget {
  const QuickDropApp({
    super.key,
    required this.settings,
    required this.downloads,
    this.initialUrl,
  });

  final SettingsStore settings;
  final DownloadService downloads;
  final String? initialUrl;

  @override
  State<QuickDropApp> createState() => _QuickDropAppState();
}

class _QuickDropAppState extends State<QuickDropApp> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'QuickDrop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            body: IndexedStack(
              index: index,
              children: [
                HomePage(
                  initialUrl: widget.initialUrl,
                  downloads: widget.downloads,
                  settings: widget.settings,
                ),
                DownloadsPage(downloads: widget.downloads),
                SettingsPage(settings: widget.settings),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download), label: 'Downloads'),
                NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
              ],
            ),
          ),
        );
      },
    );
  }
}
