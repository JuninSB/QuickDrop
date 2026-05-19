import 'package:flutter/material.dart';
import 'package:quickdrop/services/native_bridge.dart';
import 'package:quickdrop/services/settings_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final native = NativeBridge();
  bool overlayGranted = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    overlayGranted = await native.isOverlayGranted();
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
                value: widget.settings.quality,
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
            ],
          ),
        );
      },
    );
  }
}
