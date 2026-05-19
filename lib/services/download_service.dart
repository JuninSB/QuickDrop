import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quickdrop/models/download_item.dart';
import 'package:quickdrop/services/native_bridge.dart';

class DownloadService extends ChangeNotifier {
  DownloadService(this._native) {
    _sub = _events.receiveBroadcastStream().listen(_onEvent);
  }

  static const _events = EventChannel('quickdrop/download_events');
  final NativeBridge _native;
  final List<DownloadItem> _items = [];
  final List<String> _logs = [];
  StreamSubscription<dynamic>? _sub;

  List<DownloadItem> get items => List.unmodifiable(_items);
  List<String> get logs => List.unmodifiable(_logs);

  Future<void> start(String url, String quality) async {
    final item = DownloadItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url,
      status: 'queued',
      progress: 0,
    );
    _items.insert(0, item);
    _addLog('queued ${DateTime.now().toIso8601String()} quality=$quality url=$url');
    notifyListeners();
    await _native.download(url, quality);
  }

  Future<void> retry(DownloadItem item, String quality) => start(item.url, quality);

  void remove(DownloadItem item) {
    _items.removeWhere((e) => e.id == item.id);
    notifyListeners();
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final incoming = DownloadItem.fromEvent(event);
    _addLog(
      'event ${DateTime.now().toIso8601String()} status=${incoming.status} progress=${incoming.progress} url=${incoming.url} file=${incoming.file ?? '-'} error=${incoming.error ?? '-'}',
    );
    final existing = _items.indexWhere((e) => e.url == incoming.url && e.status != 'completed');
    if (existing >= 0) {
      _items[existing] = incoming;
    } else {
      _items.insert(0, incoming);
    }
    notifyListeners();
  }

  void _addLog(String line) {
    _logs.insert(0, line);
    if (_logs.length > 120) {
      _logs.removeRange(120, _logs.length);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
