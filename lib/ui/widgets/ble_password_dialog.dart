import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../viewmodels/ble_scan_view_model.dart';

/// Shows a password entry dialog. Returns the entered password on success,
/// or null if the user cancels.
Future<String?> showBlePasswordDialog({
  required BuildContext context,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final controller = TextEditingController();
      const dividerColor = Color(0xFFE0E0E0);

      void showMessage(String message) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message),
          ),
        );
      }

      void onConfirm() {
        final password = controller.text;
        if (password.isEmpty) {
          showMessage('Password cannot be empty!');
          return;
        }
        if (password.length != 8) {
          showMessage('The password should be 8 characters');
          return;
        }
        Navigator.of(dialogContext).pop(password);
      }

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
                    const Text(
                      'Please enter password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 8,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[ -~]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'The password is 8 character',
                        hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: BleScanViewModel.titleBarColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => onConfirm(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: dividerColor),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                        ),
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: BleScanViewModel.titleBarColor,
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
                        onTap: onConfirm,
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: BleScanViewModel.titleBarColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
