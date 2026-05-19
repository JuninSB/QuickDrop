import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:quickdrop/models/download_item.dart';
import 'package:share_plus/share_plus.dart';

class DownloadTile extends StatelessWidget {
  const DownloadTile({
    super.key,
    required this.item,
    required this.onRetry,
    required this.onDelete,
  });

  final DownloadItem item;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = item.status == 'completed';
    final failed = item.status == 'failed';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(done ? Icons.movie_creation_rounded : failed ? Icons.error_outline : Icons.downloading_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: failed ? 0 : item.progress / 100),
                  const SizedBox(height: 6),
                  Text(
                    failed ? item.error ?? 'Failed' : '${item.status} ${item.progress}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: done ? 'Open' : 'Retry',
              onPressed: done && item.file != null ? () => OpenFilex.open(item.file!) : onRetry,
              icon: Icon(done ? Icons.open_in_new : Icons.refresh),
            ),
            IconButton(
              tooltip: done ? 'Share' : 'Delete',
              onPressed: done && item.file != null ? () => Share.shareXFiles([XFile(item.file!)]) : onDelete,
              icon: Icon(done ? Icons.ios_share : Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
