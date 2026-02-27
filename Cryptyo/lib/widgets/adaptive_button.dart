import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  const AdaptiveButton({Key? key, required this.onPressed, required this.icon, required this.label}) : super(key: key);

  bool get _useCupertino => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context) {
    if (_useCupertino) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 8), Text(label)]),
      );
    }

    return ElevatedButton.icon(onPressed: onPressed, icon: icon, label: Text(label));
  }
}
