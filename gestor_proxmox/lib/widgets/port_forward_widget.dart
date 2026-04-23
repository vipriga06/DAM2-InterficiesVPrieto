import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ssh_service.dart';

class PortForwardWidget extends StatefulWidget {
  final SshService sshService;

  const PortForwardWidget({super.key, required this.sshService});

  @override
  State<PortForwardWidget> createState() => _PortForwardWidgetState();
}

class _PortForwardWidgetState extends State<PortForwardWidget> {
  List<PortForwardRule> _rules = [];
  final _portController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rules = await widget.sshService.getPortForwards();
      if (mounted) setState(() { _rules = rules; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _addRule() async {
    final port = int.tryParse(_portController.text);
    if (port == null || port < 1 || port > 65535) return;
    setState(() => _loading = true);
    try {
      await widget.sshService.addPortForward(port);
      _portController.clear();
      await _loadRules();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _removeRule(PortForwardRule rule) async {
    setState(() => _loading = true);
    try {
      await widget.sshService.removePortForward(rule.destPort);
      await _loadRules();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Redirecció de ports (port 80)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Port 80  →  ', style: TextStyle(fontSize: 14)),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'port',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _loading ? null : _addRule,
              child: const Text('Afegir'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loading ? null : _loadRules,
              tooltip: 'Actualitzar',
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        if (_loading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_rules.isEmpty)
          const Text('No hi ha redireccions actives.',
              style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ..._rules.map(
            (rule) => Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.swap_horiz, size: 18),
                title: Text('Port 80  →  ${rule.destPort}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: () => _removeRule(rule),
                  tooltip: 'Eliminar redirecció',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
