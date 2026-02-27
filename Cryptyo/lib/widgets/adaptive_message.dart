import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showAdaptiveMessage(BuildContext context, String message) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return;
  }

  // Fallback for CupertinoApp: show a simple alert dialog
  await showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}
