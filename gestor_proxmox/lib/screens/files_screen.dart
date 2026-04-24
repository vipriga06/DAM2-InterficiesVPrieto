import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ssh_service.dart';
import '../widgets/server_status_widget.dart';
import '../widgets/port_forward_widget.dart';
import 'disk_screen.dart';

class FilesScreen extends StatefulWidget {
  final SshService sshService;

  const FilesScreen({super.key, required this.sshService});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _currentPath = '/home';
  List<RemoteFile> _files = [];
  final List<String> _pathHistory = [];
  RemoteFile? _selected;
  bool _loading = false;
  String _sidebarItem = 'Carpetes';

  ServerType _serverType = ServerType.none;
  ServerStatus _serverStatus = ServerStatus.unknown;
  int? _serverPort;

  @override
  void initState() {
    super.initState();
    _loadFiles('/home');
  }

  Future<void> _loadFiles(String path) async {
    setState(() {
      _loading = true;
      _selected = null;
    });
    try {
      final files = await widget.sshService.listDirectory(path);
      if (!mounted) return;
      setState(() {
        _currentPath = path;
        _files = files;
        _loading = false;
      });
      _detectServer(path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Error carregant directori: $e');
    }
  }

  Future<void> _loadSidebarSection(String section) async {
    setState(() { _loading = true; _selected = null; });
    try {
      List<RemoteFile> files;
      switch (section) {
        case 'Recents':
          files = await widget.sshService.listRecent(_currentPath);
        case 'Compartit':
          files = await widget.sshService.listShared(_currentPath);
        case 'Eliminats':
          files = await widget.sshService.listTrash();
        default:
          await _loadFiles(_currentPath);
          return;
      }
      if (!mounted) return;
      setState(() { _files = files; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Error carregant $section: $e');
    }
  }

  Future<void> _detectServer(String path) async {
    final type = await widget.sshService.detectServerType(path);
    if (!mounted) return;
    if (type == ServerType.none) {
      setState(() => _serverType = ServerType.none);
      return;
    }
    final status = await widget.sshService.getServerStatus(path, type);
    int? port;
    if (status == ServerStatus.running) {
      port = await widget.sshService.getServerPort(path, type);
      port ??= type == ServerType.nodejs ? 3000 : 8080;
    }
    if (!mounted) return;
    setState(() {
      _serverType = type;
      _serverStatus = status;
      _serverPort = port;
    });
  }

  void _navigateTo(String path) {
    _pathHistory.add(_currentPath);
    _loadFiles(path);
  }

  void _navigateBack() {
    if (_pathHistory.isEmpty) return;
    _loadFiles(_pathHistory.removeLast());
  }

  String get _folderName {
    if (_currentPath == '/') return '/';
    return _currentPath.split('/').where((p) => p.isNotEmpty).last;
  }

  Future<void> _uploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (file.bytes == null) continue;
      final remotePath = '$_currentPath/${file.name}';
      try {
        await widget.sshService.uploadFile(remotePath, file.bytes!);

        if (file.name.endsWith('.zip') && mounted) {
          final extract = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Arxiu ZIP detectat'),
              content:
                  Text('Vols descomprimir "${file.name}" al servidor remot?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sí')),
              ],
            ),
          );
          if (extract == true) {
            await widget.sshService.extractZip(remotePath);
          }
        }
      } catch (e) {
        _showError('Error pujant ${file.name}: $e');
      }
    }
    await _loadFiles(_currentPath);
  }

  Future<void> _uploadDirectory() async {
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return;
    try {
      await widget.sshService.uploadDirectory(dirPath, _currentPath);
      await _loadFiles(_currentPath);
    } catch (e) {
      _showError('Error pujant directori: $e');
    }
  }

  Future<void> _download(RemoteFile file) async {
    try {
      final data = await widget.sshService.downloadFile(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Descarregat: ${file.name} (${_formatSize(data.length)})'),
      ));
    } catch (e) {
      _showError('Error descarregant: $e');
    }
  }

  Future<void> _showInfo(RemoteFile file) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Ruta:', file.path),
            _infoRow('Tipus:',
                file.isDirectory ? 'Carpeta' : 'Arxiu'),
            _infoRow('Mida:', _formatSize(file.size)),
            _infoRow('Permisos:', file.permissions),
            if (file.modified != null)
              _infoRow(
                  'Modificat:', _formatDate(file.modified!)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tancar')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _rename(RemoteFile file) async {
    final ctrl = TextEditingController(text: file.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Canviar nom'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nou nom'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel·lar')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Acceptar')),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty || result == file.name) return;
    final dir = file.path.substring(0, file.path.lastIndexOf('/'));
    try {
      await widget.sshService.renameFile(file.path, '$dir/$result');
      await _loadFiles(_currentPath);
    } catch (e) {
      _showError('Error canviant nom: $e');
    }
  }

  Future<void> _delete(RemoteFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Esborrar'),
        content: Text('Segur que vols esborrar "${file.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel·lar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esborrar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.sshService.deleteFile(file.path);
      await _loadFiles(_currentPath);
    } catch (e) {
      _showError('Error esborrant: $e');
    }
  }

  Future<void> _extractZip(RemoteFile file) async {
    try {
      await widget.sshService.extractZip(file.path);
      await _loadFiles(_currentPath);
    } catch (e) {
      _showError('Error descomprimint: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showPortForwardDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Redirecció de ports'),
        content: SizedBox(
          width: 380,
          child: PortForwardWidget(sshService: widget.sshService),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tancar')),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                const VerticalDivider(width: 1),
                Expanded(child: _buildMainArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            'Proxmox Drive',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red.shade700,
              decoration: TextDecoration.underline,
              decorationColor: Colors.red.shade300,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () async {
              await widget.sshService.disconnect();
              if (mounted) Navigator.pop(context);
            },
            tooltip: 'Desconnectar',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    const items = ['Recents', 'Carpetes', 'Compartit', 'Eliminats'];
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          for (final item in items)
            InkWell(
              onTap: () {
                setState(() => _sidebarItem = item);
                _loadSidebarSection(item);
              },
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _sidebarItem == item
                      ? Colors.grey.shade300
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item),
              ),
            ),
          const Divider(height: 24),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiskScreen(
                  sshService: widget.sshService,
                  path: _currentPath,
                ),
              ),
            ),
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.pie_chart_outline, size: 16),
                  SizedBox(width: 8),
                  Text('Ús del disc'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea() {
    return Column(
      children: [
        _buildTopBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Row(
            children: [
              Text('Ordenar segons: ',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13)),
              const Text('Nom',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('Carpeta buida'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (ctx, i) => _buildFileRow(_files[i]),
                    ),
        ),
        ServerStatusWidget(
          serverType: _serverType,
          status: _serverStatus,
          path: _currentPath,
          port: _serverPort,
          onStart: () async {
            await widget.sshService.startServer(_currentPath, _serverType);
            await _detectServer(_currentPath);
          },
          onStop: () async {
            await widget.sshService.stopServer(_currentPath, _serverType);
            await _detectServer(_currentPath);
          },
          onRestart: () async {
            setState(() => _serverStatus = ServerStatus.restarting);
            await widget.sshService
                .restartServer(_currentPath, _serverType);
            await _detectServer(_currentPath);
          },
          onConfigure: _showPortForwardDialog,
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          if (_pathHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: _navigateBack,
                child: const Icon(Icons.arrow_back),
              ),
            ),
          Text(
            '"$_folderName"',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'files') _uploadFiles();
              if (v == 'dir') _uploadDirectory();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'files', child: Text('Pujar arxius')),
              const PopupMenuItem(
                  value: 'dir', child: Text('Pujar carpeta')),
            ],
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Afegir arxius'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(RemoteFile file) {
    final isSelected = _selected?.path == file.path;
    final isZip = file.name.endsWith('.zip');

    return InkWell(
      onTap: () {
        if (file.isDirectory) {
          _navigateTo(file.path);
        } else {
          setState(() => _selected = isSelected ? null : file);
        }
      },
      onLongPress: () => _rename(file),
      child: Container(
        color: isSelected ? Colors.grey.shade100 : null,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(
              file.isDirectory
                  ? Icons.folder_outlined
                  : isZip
                      ? Icons.folder_zip_outlined
                      : Icons.insert_drive_file_outlined,
              size: 26,
              color: file.isDirectory
                  ? Colors.grey.shade600
                  : Colors.grey.shade500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.name,
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: Colors.red.shade300,
                ),
              ),
            ),
            if (isSelected) ..._buildActions(file, isZip),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(RemoteFile file, bool isZip) {
    return [
      IconButton(
        icon: const Icon(Icons.download_outlined, size: 18),
        onPressed: () => _download(file),
        tooltip: 'Descarregar',
        visualDensity: VisualDensity.compact,
      ),
      IconButton(
        icon: const Icon(Icons.info_outline, size: 18),
        onPressed: () => _showInfo(file),
        tooltip: 'Informació',
        visualDensity: VisualDensity.compact,
      ),
      if (isZip)
        IconButton(
          icon: const Icon(Icons.open_in_full, size: 18),
          onPressed: () => _extractZip(file),
          tooltip: 'Descomprimir',
          visualDensity: VisualDensity.compact,
        ),
      if (!file.isDirectory)
        IconButton(
          icon: const Icon(Icons.drive_file_rename_outline, size: 18),
          onPressed: () => _rename(file),
          tooltip: 'Canviar nom',
          visualDensity: VisualDensity.compact,
        ),
      IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: () => _delete(file),
        tooltip: 'Esborrar',
        visualDensity: VisualDensity.compact,
      ),
    ];
  }
}
