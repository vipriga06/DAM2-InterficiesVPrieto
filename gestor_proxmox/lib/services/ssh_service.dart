import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';
import '../models/server_config.dart';

enum ServerType { none, nodejs, java }

enum ServerStatus { unknown, stopped, running, restarting, error }

class RemoteFile {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final String permissions;
  final DateTime? modified;

  const RemoteFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.permissions,
    this.modified,
  });
}

class PortForwardRule {
  final String id;
  final int sourcePort;
  final int destPort;

  const PortForwardRule({
    required this.id,
    required this.sourcePort,
    required this.destPort,
  });
}

class SshService {
  SSHClient? _client;
  ServerConfig? _config;
  SftpClient? _sftp;

  bool get isConnected => _client != null;
  ServerConfig? get currentConfig => _config;

  Future<SftpClient> _getSftp() async {
    final client = _client;
    if (client == null) throw Exception('No connectat');
    _sftp ??= await client.sftp();
    return _sftp!;
  }

  Future<void> connect(ServerConfig config) async {
    await disconnect();
    // Resolve hostname manually so Flutter on Windows doesn't fail DNS lookup
    final addresses = await InternetAddress.lookup(config.host)
        .timeout(const Duration(seconds: 10));
    if (addresses.isEmpty) throw Exception('No s\'ha pogut resoldre el host: ${config.host}');
    final resolvedHost = addresses.first.address;
    final socket = await SSHSocket.connect(resolvedHost, config.port,
        timeout: const Duration(seconds: 10));

    List<SSHKeyPair>? identities;
    if (config.keyPath.isNotEmpty) {
      String pem;
      final normalizedPath = config.keyPath.replaceAll('\\', '/');
      final keyFile = File(normalizedPath);
      if (await keyFile.exists()) {
        pem = await keyFile.readAsString();
      } else {
        // Fallback: load from bundled asset
        pem = await rootBundle.loadString('assets/id_rsa');
      }
      identities = SSHKeyPair.fromPem(pem);
      if (identities.isEmpty) {
        throw Exception('No s\'ha pogut llegir la clau SSH: format no suportat');
      }
    }

    _client = SSHClient(
      socket,
      username: config.username,
      onPasswordRequest: () => config.password,
      identities: identities,
    );
    _config = config;
  }

  Future<void> disconnect() async {
    _sftp?.close();
    _sftp = null;
    _client?.close();
    _client = null;
    _config = null;
  }

  Future<String> runCommand(String command) async {
    final client = _client;
    if (client == null) throw Exception('No connectat');
    final session = await client.execute(command);
    final bytes = await session.stdout
        .fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
    await session.done;
    return String.fromCharCodes(bytes).trim();
  }

  Future<List<RemoteFile>> listDirectory(String path) async {
    final sftp = await _getSftp();
    final items = await sftp.listdir(path);
    final files = items
        .where((item) => item.filename != '.' && item.filename != '..')
        .map((item) {
          final modeValue = item.attr.mode?.value ?? 0;
          final mtime = item.attr.modifyTime;
          return RemoteFile(
            name: item.filename,
            path: '$path/${item.filename}',
            isDirectory: item.attr.isDirectory,
            size: item.attr.size ?? 0,
            permissions: _permissionsString(modeValue),
            modified: mtime != null
                ? DateTime.fromMillisecondsSinceEpoch(mtime * 1000)
                : null,
          );
        })
        .toList()
      ..sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return files;
  }

  Future<List<RemoteFile>> listRecent(String basePath, {int limit = 30}) async {
    final out = await runCommand(
        'find "$basePath" -maxdepth 4 -not -path "*/.*" -printf "%T@ %s %p\\n" 2>/dev/null'
        ' | sort -rn | head -$limit');
    final files = <RemoteFile>[];
    for (final line in out.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.trim().split(' ');
      if (parts.length < 3) continue;
      final ts = double.tryParse(parts[0]) ?? 0;
      final size = int.tryParse(parts[1]) ?? 0;
      final path = parts.sublist(2).join(' ');
      final name = path.split('/').last;
      files.add(RemoteFile(
        name: name,
        path: path,
        isDirectory: false,
        size: size,
        permissions: '-rwxr--r--',
        modified: DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt()),
      ));
    }
    return files;
  }

  Future<List<RemoteFile>> listShared(String basePath) async {
    final out = await runCommand(
        'find "$basePath" -maxdepth 4 -not -path "*/.*" \\( -perm -o+r -o -perm -g+r \\) -type f'
        ' -printf "%s %p\\n" 2>/dev/null | head -50');
    final files = <RemoteFile>[];
    for (final line in out.split('\n')) {
      if (line.trim().isEmpty) continue;
      final idx = line.indexOf(' ');
      if (idx < 0) continue;
      final size = int.tryParse(line.substring(0, idx)) ?? 0;
      final path = line.substring(idx + 1).trim();
      final name = path.split('/').last;
      files.add(RemoteFile(
        name: name,
        path: path,
        isDirectory: false,
        size: size,
        permissions: '-rw-r--r--',
        modified: null,
      ));
    }
    return files;
  }

  Future<List<RemoteFile>> listTrash() async {
    final trashPath = await runCommand(
        'test -d ~/.local/share/Trash/files && echo ~/.local/share/Trash/files || echo /tmp');
    try {
      return await listDirectory(trashPath.trim());
    } catch (_) {
      return [];
    }
  }

  Future<Uint8List> downloadFile(String remotePath) async {
    final sftp = await _getSftp();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    final data = await file.readBytes();
    await file.close();
    return data;
  }

  Future<void> uploadFile(String remotePath, Uint8List data) async {
    final sftp = await _getSftp();
    final file = await sftp.open(
      remotePath,
      mode: SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );
    await file.writeBytes(data);
    await file.close();
  }

  Future<void> uploadDirectory(String localDirPath, String remotePath) async {
    final dir = Directory(localDirPath);
    final dirName = dir.path.split(Platform.pathSeparator).last;
    final archive = Archive();

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relative = entity.path
            .replaceFirst(dir.path, dirName)
            .replaceAll('\\', '/');
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relative, bytes.length, bytes));
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Error creant ZIP');

    final remoteZip = '$remotePath/$dirName.zip';
    await uploadFile(remoteZip, Uint8List.fromList(zipData));
    // Extract on server and remove zip
    await runCommand(
        'cd "$remotePath" && unzip -o "$dirName.zip" && rm -f "$dirName.zip"');
  }

  Future<void> deleteFile(String remotePath) async {
    await runCommand('rm -rf "$remotePath"');
  }

  Future<void> renameFile(String oldPath, String newPath) async {
    final sftp = await _getSftp();
    await sftp.rename(oldPath, newPath);
  }

  Future<void> extractZip(String remotePath) async {
    final dir = remotePath.substring(0, remotePath.lastIndexOf('/'));
    await runCommand('cd "$dir" && unzip -o "${remotePath.split('/').last}"');
  }

  Future<ServerType> detectServerType(String path) async {
    final result = await runCommand(
        '(test -f "$path/package.json" && echo nodejs) || (test -f "$path/pom.xml" && echo java) || echo none');
    if (result.contains('nodejs')) return ServerType.nodejs;
    if (result.contains('java')) return ServerType.java;
    return ServerType.none;
  }

  Future<ServerStatus> getServerStatus(String path, ServerType type) async {
    if (type == ServerType.none) return ServerStatus.unknown;
    try {
      final grep = type == ServerType.nodejs ? 'node' : 'java';
      final result = await runCommand(
          'pgrep -f "$grep" > /dev/null 2>&1 && echo running || echo stopped');
      return result.contains('running')
          ? ServerStatus.running
          : ServerStatus.stopped;
    } catch (_) {
      return ServerStatus.error;
    }
  }

  Future<int?> getServerPort(String path, ServerType type) async {
    try {
      if (type == ServerType.nodejs) {
        final result = await runCommand(
            'grep -o \'"port"[^,}]*\' "$path/package.json" 2>/dev/null | grep -o \'[0-9]\\+\' | head -1');
        return int.tryParse(result);
      }
    } catch (_) {}
    return null;
  }

  Future<void> startServer(String path, ServerType type) async {
    if (type == ServerType.nodejs) {
      await runCommand(
          'cd "$path" && nohup npm start > /tmp/srv_\$(basename $path).log 2>&1 &');
    } else if (type == ServerType.java) {
      await runCommand(
          'cd "$path" && nohup mvn spring-boot:run > /tmp/srv_\$(basename $path).log 2>&1 &');
    }
  }

  Future<void> stopServer(String path, ServerType type) async {
    final grep = type == ServerType.nodejs ? 'node' : 'java';
    await runCommand('pkill -f "$grep" 2>/dev/null || true');
  }

  Future<void> restartServer(String path, ServerType type) async {
    await stopServer(path, type);
    await Future.delayed(const Duration(seconds: 2));
    await startServer(path, type);
  }

  Future<List<PortForwardRule>> getPortForwards() async {
    try {
      final result = await runCommand(
          'sudo iptables -t nat -L PREROUTING -n --line-numbers 2>/dev/null | grep "dpt:80" || true');
      final rules = <PortForwardRule>[];
      for (final line in result.split('\n')) {
        if (line.isEmpty) continue;
        final match =
            RegExp(r'(\d+).*dpt:80.*to:.*?:(\d+)').firstMatch(line);
        if (match != null) {
          rules.add(PortForwardRule(
            id: match.group(1)!,
            sourcePort: 80,
            destPort: int.parse(match.group(2)!),
          ));
        }
      }
      return rules;
    } catch (_) {
      return [];
    }
  }

  Future<void> addPortForward(int destPort) async {
    await runCommand(
        'sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $destPort');
  }

  Future<void> removePortForward(int destPort) async {
    await runCommand(
        'sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $destPort 2>/dev/null || true');
  }

  Future<Map<String, int>> getDiskUsage(String path, {int depth = 3}) async {
    final result =
        await runCommand('du -d $depth "$path" 2>/dev/null | sort -rn');
    final map = <String, int>{};
    for (final line in result.split('\n')) {
      if (line.isEmpty) continue;
      final parts = line.split('\t');
      if (parts.length < 2) continue;
      final size = int.tryParse(parts[0]) ?? 0;
      map[parts[1]] = size;
    }
    return map;
  }

  String _permissionsString(int mode) {
    const types = ['---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx'];
    final owner = types[(mode >> 6) & 7];
    final group = types[(mode >> 3) & 7];
    final other = types[mode & 7];
    final isDir = (mode & 0xF000) == 0x4000;
    return '${isDir ? 'd' : '-'}$owner$group$other';
  }
}
