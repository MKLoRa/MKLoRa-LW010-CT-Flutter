import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../viewmodels/ble_scan_view_model.dart';

/// Change-password dialog (native [ChangePasswordDialog]).
/// Returns the new password when both fields match, or null if cancelled.
Future<String?> showBleChangePasswordDialog({
  required BuildContext context,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final passwordController = TextEditingController();
      final confirmController = TextEditingController();
      const dividerColor = Color(0xFFE0E0E0);
      var ensureEnabled = false;

      void showMessage(String message) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message),
          ),
        );
      }

      void updateEnsureEnabled() {
        ensureEnabled = passwordController.text.isNotEmpty ||
            confirmController.text.isNotEmpty;
      }

      void submitPassword() {
        final password = passwordController.text;
        final confirm = confirmController.text;
        if (password.length != 8 || confirm.length != 8) {
          showMessage('The password should be 8 characters.Please try again');
          return;
        }
        if (password != confirm) {
          showMessage('Password do not match!Please try again.');
          return;
        }
        Navigator.of(dialogContext).pop(password);
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Change password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Note:The password should be 8 characters',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: passwordController,
                      autofocus: true,
                      maxLength: 8,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[ -~]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Enter new password',
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
                      onChanged: (_) {
                        updateEnsureEnabled();
                        setState(() {});
                      },
                      onSubmitted: (_) => submitPassword(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: TextField(
                      controller: confirmController,
                      maxLength: 8,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[ -~]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Enter new password again',
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
                      onChanged: (_) {
                        updateEnsureEnabled();
                        setState(() {});
                      },
                      onSubmitted: (_) => submitPassword(),
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
                            onTap: ensureEnabled ? submitPassword : null,
                            child: Center(
                              child: Text(
                                'OK',
                                style: TextStyle(
                                  color: ensureEnabled
                                      ? BleScanViewModel.titleBarColor
                                      : const Color(0xFFBDBDBD),
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
    },
  );
}
