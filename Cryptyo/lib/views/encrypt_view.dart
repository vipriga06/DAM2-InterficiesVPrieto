import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cryptyo/services/crypto_service.dart';
import 'package:cryptyo/widgets/adaptive_button.dart';
import 'package:cryptyo/widgets/adaptive_message.dart';

// UI to pick a public RSA key and a file to encrypt. Encryption not implemented yet.
class EncryptView extends StatelessWidget {
  const EncryptView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EncryptBody();
  }
}

class _EncryptBody extends StatefulWidget {
  const _EncryptBody({Key? key}) : super(key: key);

  @override
  State<_EncryptBody> createState() => _EncryptBodyState();
}

class _EncryptBodyState extends State<_EncryptBody> {
  String? _pubKeyPath;
  String? _inputFilePath;

  Future<void> _pickPublicKey() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pem', 'pub', 'txt'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pubKeyPath = res.files.single.path);
    }
  }

  Future<void> _pickInputFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.isNotEmpty) {
      setState(() => _inputFilePath = res.files.single.path);
    }
  }

  void _encrypt() {
    if (_pubKeyPath == null || _inputFilePath == null) {
      showAdaptiveMessage(context, 'Selecciona clave pública y archivo');
      return;
    }

    _doEncrypt();
  }

  Future<void> _doEncrypt() async {
    try {
      final pem = await File(_pubKeyPath!).readAsString();
      final input = File(_inputFilePath!);
      final crypto = const CryptoService();
      final packaged = await crypto.encryptFileWithPublicKeyPem(pem, input);
      final outPath = '${_inputFilePath!}.enc';
      await File(outPath).writeAsBytes(packaged);
      if (!mounted) return;
      await showAdaptiveMessage(context, 'Archivo encriptado: $outPath');
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
            onPressed: _pickPublicKey,
            icon: const Icon(Icons.account_circle),
            label: 'Seleccionar clave pública',
          ),
          const SizedBox(height: 8),
          Text(_pubKeyPath ?? 'Ninguna clave seleccionada'),
          const SizedBox(height: 16),
          AdaptiveButton(
            onPressed: _pickInputFile,
            icon: const Icon(Icons.insert_drive_file),
            label: 'Seleccionar archivo a encriptar',
          ),
          const SizedBox(height: 8),
          Text(_inputFilePath ?? 'Ningún archivo seleccionado'),
          const Spacer(),
          AdaptiveButton(
            onPressed: _encrypt,
            icon: const Icon(Icons.lock),
            label: 'Encriptar',
          ),
        ],
        ),
      ),
    );
  }
}

