import 'package:flutter/services.dart';

class NativeBridge {
  static const _methods = MethodChannel('quickdrop/native');

  Future<String?> clipboardUrl() => _methods.invokeMethod<String>('clipboardUrl');

  Future<bool> isOverlayGranted() async {
    return await _methods.invokeMethod<bool>('isOverlayGranted') ?? false;
  }

  Future<void> requestOverlayPermission() => _methods.invokeMethod('requestOverlayPermission');

  Future<void> requestNotifications() => _methods.invokeMethod('requestNotifications');

  Future<void> showOverlay(String url) => _methods.invokeMethod('showOverlay', {'url': url});

  Future<void> hideOverlay() => _methods.invokeMethod('hideOverlay');

  Future<void> startClipboardMonitor() => _methods.invokeMethod('startClipboardMonitor');

  Future<void> stopClipboardMonitor() => _methods.invokeMethod('stopClipboardMonitor');

  Future<void> download(String url, String quality) => _methods.invokeMethod('download', {
        'url': url,
        'quality': quality,
      });

  Future<Map<String, dynamic>> diagnostics() async {
    final result = await _methods.invokeMapMethod<String, dynamic>('diagnostics');
    return result ?? <String, dynamic>{};
  }
}
