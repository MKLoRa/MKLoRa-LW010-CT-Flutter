import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/device_detail_theme.dart';

class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.onSave,
    this.showSave = false,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeviceDetailTheme.background,
      appBar: AppBar(
        backgroundColor: DeviceDetailTheme.primary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: DeviceDetailTheme.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: onBack ?? () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          if (showSave)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: onSave,
            ),
        ],
      ),
      body: body,
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.child, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DeviceDetailTheme.card,
      child: Container(
        width: double.infinity,
        margin: margin ?? const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}

class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DeviceDetailTheme.textPrimary,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trailing!,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DeviceDetailTheme.textPrimary,
                  ),
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: DeviceDetailTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class SettingsLabelRow extends StatelessWidget {
  const SettingsLabelRow({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeviceDetailTheme.textPrimary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: DeviceDetailTheme.divider,
    );
  }
}

class BlueValueButton extends StatelessWidget {
  const BlueValueButton({
    super.key,
    required this.text,
    this.onTap,
    this.minWidth = 70,
  });

  final String text;
  final VoidCallback? onTap;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DeviceDetailTheme.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }
}

class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLength,
    this.width = 120,
    this.suffix,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final double width;
  final String? suffix;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: const UnderlineInputBorder(),
            ),
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 5),
          Text(
            suffix!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeviceDetailTheme.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsLabelRow(
      label: label,
      child: Switch(
        value: value,
        activeThumbColor: DeviceDetailTheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsLabelRow(
          label: label,
          child: Text(
            suffix ?? value.round().toString(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeviceDetailTheme.textPrimary,
            ),
          ),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: DeviceDetailTheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class SettingsHexField extends StatelessWidget {
  const SettingsHexField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLength,
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        isDense: true,
        border: const UnderlineInputBorder(),
      ),
    );
  }
}

class SettingsCheckboxRow extends StatelessWidget {
  const SettingsCheckboxRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: DeviceDetailTheme.textPrimary,
        ),
      ),
      value: value,
      activeColor: DeviceDetailTheme.primary,
      controlAffinity: ListTileControlAffinity.trailing,
      onChanged: onChanged,
    );
  }
}
