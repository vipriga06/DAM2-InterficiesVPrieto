import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/server_config.dart';

class ConfigService {
  static const _fileName = 'servers.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<ServerConfig>> loadServers() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      return list
          .map((e) => ServerConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveServers(List<ServerConfig> servers) async {
    final file = await _getFile();
    await file.writeAsString(
        jsonEncode(servers.map((s) => s.toJson()).toList()));
  }
}
