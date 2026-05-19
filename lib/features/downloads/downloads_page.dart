import 'package:flutter/material.dart';
import 'package:quickdrop/services/download_service.dart';
import 'package:quickdrop/widgets/download_tile.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key, required this.downloads});

  final DownloadService downloads;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: downloads,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Downloads')),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (downloads.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('No downloads yet')),
                )
              else
                ...downloads.items.map((item) => DownloadTile(
                      item: item,
                      onRetry: () => downloads.retry(item, 'best'),
                      onDelete: () => downloads.remove(item),
                    )),
            ],
          ),
        );
      },
    );
  }
}
