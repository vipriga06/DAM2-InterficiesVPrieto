import 'package:flutter/material.dart';
import '../services/ssh_service.dart';
import 'status_indicator.dart';

class ServerStatusWidget extends StatelessWidget {
  final ServerType serverType;
  final ServerStatus status;
  final String path;
  final int? port;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;
  final VoidCallback? onConfigure;

  const ServerStatusWidget({
    super.key,
    required this.serverType,
    required this.status,
    required this.path,
    this.port,
    this.onStart,
    this.onStop,
    this.onRestart,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    if (serverType == ServerType.none) return const SizedBox.shrink();

    final typeName = serverType == ServerType.nodejs ? 'NodeJS' : 'Java';
    final isRunning = status == ServerStatus.running;
    final isRestarting = status == ServerStatus.restarting;

    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          StatusIndicator(active: isRunning, size: 12),
          const SizedBox(width: 8),
          Text(
            'Servidor $typeName ${_statusLabel()}${port != null ? ' al port $port' : ''}',
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          if (!isRunning && !isRestarting && onStart != null)
            _ActionButton(label: 'Iniciar', onTap: onStart!),
          if (isRunning && onRestart != null) ...[
            _ActionButton(label: 'Reiniciar', onTap: onRestart!),
            const SizedBox(width: 4),
          ],
          if (isRunning && onStop != null)
            _ActionButton(label: 'Aturar', onTap: onStop!),
          if (onConfigure != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onConfigure,
              child: const Icon(Icons.settings, size: 18, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel() => switch (status) {
        ServerStatus.running => 'funcionant',
        ServerStatus.stopped => 'aturat',
        ServerStatus.restarting => 'reiniciant...',
        ServerStatus.error => 'error',
        ServerStatus.unknown => '',
      };
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
}
