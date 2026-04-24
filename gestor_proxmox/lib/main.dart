import 'package:flutter/material.dart';
import 'screens/config_screen.dart';
import 'services/ssh_service.dart';

void main() {
  runApp(const GestorProxmoxApp());
}

class GestorProxmoxApp extends StatelessWidget {
  const GestorProxmoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Proxmox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ConfigScreen(sshService: SshService()),
      );
  }
}
