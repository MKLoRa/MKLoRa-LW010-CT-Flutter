import 'package:flutter/material.dart';

Future<void> pushDetailPage(BuildContext context, Widget page) {
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

Future<bool> saveWithToast(
  BuildContext context,
  Future<bool> Function() save,
) async {
  final ok = await save();
  if (!context.mounted) {
    return ok;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? 'Save Successfully！'
            : 'Opps！Save failed. Please check the input characters and try again.',
      ),
    ),
  );
  return ok;
}
