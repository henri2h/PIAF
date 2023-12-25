
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

extension SettingsTileRadio on SettingsTile {
  static SettingsTile radio<T>(
      {void Function(T value)? onPressed,
      required Widget title,
      required T value,
      required T groupValue}) {
    return SettingsTile(
      leading: Radio<T>(
        onChanged: (val) {
          if (val != null) {
            onPressed?.call(val);
          }
        },
        value: value,
        groupValue: groupValue,
      ),
      title: title,
      onPressed: (_) => onPressed?.call(value),
    );
  }
}
