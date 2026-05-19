import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  bool autoClipboard = true;
  bool autoOverlay = true;
  bool darkMode = true;
  String quality = 'best';
  String saveLocation = 'Downloads/QuickDrop';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    autoClipboard = prefs.getBool('autoClipboard') ?? true;
    autoOverlay = prefs.getBool('autoOverlay') ?? true;
    darkMode = prefs.getBool('darkMode') ?? true;
    quality = prefs.getString('quality') ?? 'best';
    saveLocation = prefs.getString('saveLocation') ?? 'Downloads/QuickDrop';
  }

  Future<void> setAutoClipboard(bool value) async {
    autoClipboard = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoClipboard', value);
    notifyListeners();
  }

  Future<void> setAutoOverlay(bool value) async {
    autoOverlay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoOverlay', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setQuality(String value) async {
    quality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quality', value);
    notifyListeners();
  }
}
