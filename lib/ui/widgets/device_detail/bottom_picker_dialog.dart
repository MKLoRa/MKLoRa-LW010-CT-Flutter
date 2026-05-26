import 'package:flutter/material.dart';

import '../../theme/device_detail_theme.dart';

Future<int?> showBottomPicker({
  required BuildContext context,
  required List<String> options,
  required int selectedIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: options.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final selected = index == selectedIndex;
            return ListTile(
              title: Text(
                options[index],
                style: TextStyle(
                  color: selected ? DeviceDetailTheme.primary : DeviceDetailTheme.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: DeviceDetailTheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(index),
            );
          },
        ),
      );
    },
  );
}
