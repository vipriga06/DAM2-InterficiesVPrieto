import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/server_config.dart';
import '../services/config_service.dart';
import '../services/ssh_service.dart';
import '../widgets/titled_text_field.dart';
import 'files_screen.dart';

class ConfigScreen extends StatefulWidget {
  final SshService sshService;

  const ConfigScreen({super.key, required this.sshService});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  List<ServerConfig> _servers = [];
  ServerConfig? _selected;
  bool _connecting = false;

  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    final servers = await ConfigService.loadServers();
    if (mounted) {
      setState(() {
        _servers = servers;
        if (servers.isNotEmpty) _selectServer(servers.first);
      });
    }
  }

  void _selectServer(ServerConfig s) {
    setState(() {
      _selected = s;
      _nameCtrl.text = s.name;
      _hostCtrl.text = s.host;
      _portCtrl.text = s.port.toString();
      _userCtrl.text = s.username;
      _passCtrl.text = s.password;
      _keyCtrl.text = s.keyPath;
    });
  }

  void _addServer() {
    final s = ServerConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Nou servidor',
      host: '',
    );
    setState(() => _servers.add(s));
    _selectServer(s);
    ConfigService.saveServers(_servers);
  }

  ServerConfig _currentFromForm() {
    if (_selected == null) throw StateError('No selected');
    return _selected!.copyWith(
      name: _nameCtrl.text,
      host: _hostCtrl.text,
      port: int.tryParse(_portCtrl.text) ?? 22,
      username: _userCtrl.text,
      password: _passCtrl.text,
      keyPath: _keyCtrl.text,
    );
  }

  void _saveSelected() {
    if (_selected == null) return;
    final updated = _currentFromForm();
    final idx = _servers.indexWhere((s) => s.id == _selected!.id);
    if (idx < 0) return;
    setState(() {
      _servers[idx] = updated;
      _selected = updated;
    });
    ConfigService.saveServers(_servers);
  }

  void _deleteSelected() {
    if (_selected == null) return;
    final id = _selected!.id;
    setState(() {
      _servers.removeWhere((s) => s.id == id);
      _selected = _servers.isNotEmpty ? _servers.first : null;
      if (_selected != null) _selectServer(_selected!);
    });
    ConfigService.saveServers(_servers);
  }

  void _toggleFavorite() {
    if (_selected == null) return;
    final updated =
        _currentFromForm().copyWith(isFavorite: !_selected!.isFavorite);
    final idx = _servers.indexWhere((s) => s.id == _selected!.id);
    if (idx < 0) return;
    setState(() {
      _servers[idx] = updated;
      _selected = updated;
    });
    ConfigService.saveServers(_servers);
  }

  Future<void> _connect() async {
    if (_selected == null) return;
    _saveSelected();
    setState(() => _connecting = true);
    try {
      final idx = _servers.indexWhere((s) => s.id == _selected!.id);
      await widget.sshService.connect(_servers[idx]);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FilesScreen(sshService: widget.sshService),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de connexió: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel – server list
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Text('Servidors',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addServer,
                        tooltip: 'Afegir servidor',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _servers.length,
                    itemBuilder: (ctx, i) {
                      final s = _servers[i];
                      final selected = _selected?.id == s.id;
                      return InkWell(
                        onTap: () => _selectServer(s),
                        child: Container(
                          color: selected ? Colors.grey.shade300 : null,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              if (s.isFavorite)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child:
                                      Icon(Icons.star, size: 14, color: Colors.amber),
                                ),
                              Expanded(child: Text(s.name)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right panel – config form
          Expanded(
            child: _selected == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.dns_outlined,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Selecciona o afegeix un servidor'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addServer,
                          icon: const Icon(Icons.add),
                          label: const Text('Afegir servidor'),
                        ),
                      ],
                    ),
                  )
                : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuració SSH',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          TitledTextField(title: 'Nom:', controller: _nameCtrl),
          const SizedBox(height: 12),
          TitledTextField(title: 'Servidor:', controller: _hostCtrl),
          const SizedBox(height: 12),
          TitledTextField(
            title: 'Port:',
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TitledTextField(title: 'Usuari:', controller: _userCtrl),
          const SizedBox(height: 12),
          TitledTextField(
            title: 'Contrasenya:',
            controller: _passCtrl,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TitledTextField(title: 'Clau:', controller: _keyCtrl),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar servidor',
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _toggleFavorite,
                child: Text(_selected?.isFavorite == true
                    ? 'Treure de favorits'
                    : 'Afegir a favorits'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _connecting ? null : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                child: _connecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Connectar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
