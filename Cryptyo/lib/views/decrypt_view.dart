import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cryptyo/services/crypto_service.dart';
import 'package:cryptyo/widgets/adaptive_button.dart';
import 'package:cryptyo/widgets/adaptive_message.dart';
import 'package:flutter/cupertino.dart';

class DecryptView extends StatelessWidget {
  const DecryptView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DecryptBody();
  }
}

class _DecryptBody extends StatefulWidget {
  const _DecryptBody({Key? key}) : super(key: key);

  @override
  State<_DecryptBody> createState() => _DecryptBodyState();
}

class _DecryptBodyState extends State<_DecryptBody> {
  String? _privKeyPath;
  String? _inputFilePath;
  String? _outputDir;

  @override
  void initState() {
    super.initState();
    _checkDefaultPrivateKey();
  }

  Future<void> _checkDefaultPrivateKey() async {
    if (kIsWeb) return;
    try {
      final home = Platform.isWindows ? Platform.environment['USERPROFILE'] : Platform.environment['HOME'];
      if (home == null) return;
      final candidate = File('$home/.ssh/id_rsa');
      if (await candidate.exists()) {
        setState(() => _privKeyPath = candidate.path);
      }
    } catch (_) {}
  }

  Future<void> _pickPrivateKey() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pem', 'key', 'txt'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _privKeyPath = res.files.single.path);
    }
  }

  Future<void> _pickInputFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.isNotEmpty) {
      setState(() => _inputFilePath = res.files.single.path);
    }
  }

  Future<void> _pickOutputDir() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) setState(() => _outputDir = dir);
  }

  void _decrypt() {
    if (_privKeyPath == null || _inputFilePath == null || _outputDir == null) {
      showAdaptiveMessage(context, 'Selecciona clave privada, archivo y destino');
      return;
    }

    _doDecrypt();
  }

  Future<void> _doDecrypt() async {
    try {
      final pem = await File(_privKeyPath!).readAsString();
      final packaged = await File(_inputFilePath!).readAsBytes();
      final crypto = const CryptoService();
      final outName = _inputFilePath!.split(Platform.pathSeparator).last.replaceAll('.enc', '');
      final outFile = File('$_outputDir/decrypted_$outName');
      await crypto.decryptPackageWithPrivateKeyPem(pem, packaged, outFile);
      if (!mounted) return;
      await showAdaptiveMessage(context, 'Archivo desencriptado: ${outFile.path}');
    } catch (e) {
      if (!mounted) return;
      await showAdaptiveMessage(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveButton(
            onPressed: _pickPrivateKey,
            icon: const Icon(Icons.key),
            label: 'Seleccionar clave privada',
          ),
          const SizedBox(height: 8),
          Text(_privKeyPath ?? 'Usando por defecto: ~/.ssh/id_rsa si existe'),
          const SizedBox(height: 16),
          AdaptiveButton(
            onPressed: _pickInputFile,
            icon: const Icon(Icons.insert_drive_file),
            label: 'Seleccionar archivo a desencriptar',
          ),
          const SizedBox(height: 8),
          Text(_inputFilePath ?? 'Ningún archivo seleccionado'),
          const SizedBox(height: 16),
          AdaptiveButton(
            onPressed: _pickOutputDir,
            icon: const Icon(Icons.folder_open),
            label: 'Seleccionar carpeta destino',
          ),
          const SizedBox(height: 8),
          Text(_outputDir ?? 'Ninguna carpeta seleccionada'),
          const Spacer(),
          AdaptiveButton(
            onPressed: _decrypt,
            icon: const Icon(Icons.lock_open),
            label: 'Desencriptar',
          ),
        ],
        ),
      ),
    );
  }
}