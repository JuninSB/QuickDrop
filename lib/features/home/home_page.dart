import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickdrop/services/download_service.dart';
import 'package:quickdrop/services/settings_store.dart';
import 'package:quickdrop/widgets/download_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.downloads,
    required this.settings,
    required this.onDevUnlocked,
    this.initialUrl,
  });

  final DownloadService downloads;
  final SettingsStore settings;
  final VoidCallback onDevUnlocked;
  final String? initialUrl;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController controller = TextEditingController(text: widget.initialUrl ?? '');
  bool busy = false;
  int titleTaps = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.downloads,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              title: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  titleTaps += 1;
                  if (titleTaps >= 5) {
                    widget.onDevUnlocked();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Developer tools unlocked')),
                    );
                  }
                },
                child: const Text('QuickDrop'),
              ),
              actions: [
                IconButton(
                  tooltip: 'Paste',
                  onPressed: paste,
                  icon: const Icon(Icons.content_paste_rounded),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(18),
              sliver: SliverList.list(
                children: [
                  Text('Instant video download', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Paste Instagram, TikTok, YouTube, X, or Facebook URL',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : download,
                    icon: busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download_rounded),
                    label: const Text('Download'),
                  ),
                  const SizedBox(height: 28),
                  Text('Recent', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (widget.downloads.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Downloads appear here as soon as they start.'),
                    )
                  else
                    ...widget.downloads.items.take(4).map((item) => DownloadTile(
                          item: item,
                          onRetry: () => widget.downloads.retry(item, widget.settings.quality),
                          onDelete: () => widget.downloads.remove(item),
                        )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) controller.text = data!.text!;
  }

  Future<void> download() async {
    final url = controller.text.trim();
    if (url.isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.downloads.start(url, widget.settings.quality);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
