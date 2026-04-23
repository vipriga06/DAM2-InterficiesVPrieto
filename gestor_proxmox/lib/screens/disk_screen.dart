import 'package:flutter/material.dart';
import '../services/ssh_service.dart';
import '../widgets/disk_usage_painter.dart';

class DiskScreen extends StatefulWidget {
  final SshService sshService;
  final String path;

  const DiskScreen({super.key, required this.sshService, required this.path});

  @override
  State<DiskScreen> createState() => _DiskScreenState();
}

class _DiskScreenState extends State<DiskScreen> {
  DiskNode? _root;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usage = await widget.sshService.getDiskUsage(widget.path);
      final root = _buildTree(usage, widget.path);
      if (mounted) setState(() { _root = root; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  DiskNode _buildTree(Map<String, int> usage, String basePath) {
    final children = <DiskNode>[];
    for (final entry in usage.entries) {
      if (entry.key == basePath) continue;
      final parent = entry.key.contains('/')
          ? entry.key.substring(0, entry.key.lastIndexOf('/'))
          : '';
      if (parent == basePath) {
        final name = entry.key.split('/').last;
        // collect grandchildren
        final grandchildren = <DiskNode>[];
        for (final sub in usage.entries) {
          if (sub.key == entry.key) continue;
          final subParent = sub.key.contains('/')
              ? sub.key.substring(0, sub.key.lastIndexOf('/'))
              : '';
          if (subParent == entry.key) {
            grandchildren.add(DiskNode(
              name: sub.key.split('/').last,
              sizeKb: sub.value,
            ));
          }
        }
        grandchildren.sort((a, b) => b.sizeKb.compareTo(a.sizeKb));
        children.add(DiskNode(
          name: name,
          sizeKb: entry.value,
          children: grandchildren,
        ));
      }
    }
    children.sort((a, b) => b.sizeKb.compareTo(a.sizeKb));
    return DiskNode(
      name: basePath.split('/').where((p) => p.isNotEmpty).lastOrNull ??
          basePath,
      sizeKb: usage[basePath] ?? 0,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ús del disc — ${widget.path}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Actualitzar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error: $_error',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final root = _root;
    if (root == null) return const SizedBox.shrink();

    return LayoutBuilder(builder: (ctx, constraints) {
      final canvasSize =
          (constraints.maxHeight * 0.65).clamp(200.0, 500.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: DiskUsageWidget(root: root, size: canvasSize),
            ),
            const SizedBox(height: 24),
            _buildLegend(root),
          ],
        ),
      );
    });
  }

  Widget _buildLegend(DiskNode root) {
    if (root.children.isEmpty) {
      return const Text('Sense subdirectoris',
          style: TextStyle(color: Colors.grey));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contingut de ${root.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...root.children.take(12).map((child) {
              final total = root.totalKb;
              final pct = total > 0
                  ? (child.totalKb / total * 100).toStringAsFixed(1)
                  : '0.0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: Text(child.name,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total > 0 ? child.totalKb / total : 0,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${_fmt(child.totalKb)} ($pct%)',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(int kb) {
    if (kb < 1024) return '$kb KB';
    if (kb < 1024 * 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '${(kb / (1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
