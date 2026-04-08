import 'dart:convert';
import 'dart:io';

/// Pure dart:io key-value store. No Flutter plugins required.
/// On Windows, saves to %APPDATA%\teacher_scheduler\
/// On other platforms, falls back to the executable's directory.
class AppStorage {
  static AppStorage? _instance;
  late Directory _dir;

  AppStorage._();

  static Future<AppStorage> getInstance() async {
    if (_instance == null) {
      final s = AppStorage._();
      await s._init();
      _instance = s;
    }
    return _instance!;
  }

  Future<void> _init() async {
    String base;

    if (Platform.isWindows) {
      // %APPDATA% is always set on Windows (e.g. C:\Users\<user>\AppData\Roaming)
      base =
          Platform.environment['APPDATA'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
    } else if (Platform.isMacOS) {
      base =
          '${Platform.environment['HOME'] ?? '.'}/Library/Application Support';
    } else {
      base = Platform.environment['HOME'] ?? '.';
    }

    _dir = Directory('$base${Platform.pathSeparator}teacher_scheduler');
    if (!_dir.existsSync()) {
      _dir.createSync(recursive: true);
    }
  }

  File _file(String key) =>
      File('${_dir.path}${Platform.pathSeparator}$key.json');

  Future<String?> getString(String key) async {
    final f = _file(key);
    if (!f.existsSync()) return null;
    try {
      return await f.readAsString(encoding: utf8);
    } catch (_) {
      return null;
    }
  }

  Future<void> setString(String key, String value) async {
    await _file(key).writeAsString(value, encoding: utf8, flush: true);
  }
}
