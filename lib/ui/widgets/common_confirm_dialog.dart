import 'package:flutter/material.dart';

Future<bool> showCommonConfirmDialog({
  required BuildContext context,
  required String message,
  String? title,
  String cancelText = 'Cancel',
  String confirmText = 'Confirm',
  Color actionColor = const Color(0xFF2F84D0),
  bool barrierDismissible = true,
  bool showCancel = true,
  bool useRootNavigator = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (context) {
      const dividerColor = Color(0xFFE0E0E0);
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: dividerColor),
              SizedBox(
                height: 44,
                child: showCancel
                    ? Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(6),
                              ),
                              onTap: () => Navigator.of(context).pop(false),
                              child: Center(
                                child: Text(
                                  cancelText,
                                  style: TextStyle(
                                    color: actionColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: dividerColor,
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(6),
                              ),
                              onTap: () => Navigator.of(context).pop(true),
                              child: Center(
                                child: Text(
                                  confirmText,
                                  style: TextStyle(
                                    color: actionColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        onTap: () => Navigator.of(context).pop(true),
                        child: Center(
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              color: actionColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
