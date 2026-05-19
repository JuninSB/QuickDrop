import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickdrop/services/download_service.dart';
import 'package:quickdrop/services/native_bridge.dart';
import 'package:quickdrop/services/settings_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings, required this.downloads});

  final SettingsStore settings;
  final DownloadService downloads;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final native = NativeBridge();
  bool overlayGranted = false;
  Map<String, dynamic> diagnostics = const {};

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    overlayGranted = await native.isOverlayGranted();
    diagnostics = await native.diagnostics();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              SwitchListTile(
                value: widget.settings.autoClipboard,
                onChanged: (value) async {
                  await widget.settings.setAutoClipboard(value);
                  if (value) {
                    await native.requestNotifications();
                    await native.startClipboardMonitor();
                  } else {
                    await native.stopClipboardMonitor();
                  }
                },
                title: const Text('Auto clipboard detection'),
                subtitle: const Text('Foreground monitor for supported copied links'),
              ),
              SwitchListTile(
                value: widget.settings.autoOverlay,
                onChanged: (value) => widget.settings.setAutoOverlay(value),
                title: const Text('Auto overlay'),
                subtitle: const Text('Show the floating bubble when a link is copied'),
              ),
              SwitchListTile(
                value: widget.settings.darkMode,
                onChanged: widget.settings.setDarkMode,
                title: const Text('Dark mode'),
              ),
              ListTile(
                leading: Icon(overlayGranted ? Icons.check_circle : Icons.open_in_new),
                title: Text(overlayGranted ? 'Overlay permission enabled' : 'Enable overlay'),
                subtitle: const Text('Required for the floating bubble over other apps'),
                onTap: () async {
                  await native.requestOverlayPermission();
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                  await refresh();
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: widget.settings.quality,
                decoration: const InputDecoration(labelText: 'Download quality'),
                items: const [
                  DropdownMenuItem(value: 'best', child: Text('Best available')),
                  DropdownMenuItem(value: '720p', child: Text('720p max')),
                  DropdownMenuItem(value: '480p', child: Text('480p max')),
                  DropdownMenuItem(value: 'audio', child: Text('Audio only')),
                ],
                onChanged: (value) {
                  if (value != null) widget.settings.setQuality(value);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Save location'),
                subtitle: Text(widget.settings.saveLocation),
              ),
              if (widget.settings.devMode) ...[
                const SizedBox(height: 20),
                Text('Developer', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('yt-dlp status'),
                  subtitle: Text(_diagnosticText()),
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                FilledButton.icon(
                  onPressed: copyDebugLogs,
                  icon: const Icon(Icons.copy_all),
                  label: const Text('Copy debug logs'),
                ),
                const SizedBox(height: 8),
                ...widget.downloads.logs.take(10).map(
                      (line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(line, style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _diagnosticText() {
    final existsInAssets = diagnostics['assetYtDlpExists'] == true;
    final pythonYtDlp = diagnostics['pythonYtDlpAvailable'] == true;
    final extracted = diagnostics['extractedYtDlpExists'] == true;
    final extractedPath = diagnostics['extractedYtDlpPath'] ?? '-';
    final packageName = diagnostics['packageName'] ?? '-';
    return 'pythonYtDlp=$pythonYtDlp asset=$existsInAssets extracted=$extracted package=$packageName path=$extractedPath';
  }

  Future<void> copyDebugLogs() async {
    await refresh();
    final text = [
      'QuickDrop debug ${DateTime.now().toIso8601String()}',
      'diagnostics=$diagnostics',
      ...widget.downloads.logs,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug logs copied')),
    );
  }
}
