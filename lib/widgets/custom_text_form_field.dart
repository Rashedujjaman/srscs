import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final bool filled;
  final Color? fillColor;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool? readOnly;
  final bool? enabled;

  const CustomTextFormField({
    Key? key,
    this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.filled = true,
    this.fillColor,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.keyboardType,
    this.validator,
    this.readOnly,
    this.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: enabled ?? true,
      readOnly: readOnly ?? false,
      controller: controller,
      obscureText: obscureText,
      obscuringCharacter: '*',
      keyboardType: keyboardType,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: filled,
        fillColor: Theme.of(context).colorScheme.brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).colorScheme.secondary.withAlpha(200),
        iconColor: Theme.of(context).colorScheme.primary,
        border: const OutlineInputBorder(),
        floatingLabelBehavior: floatingLabelBehavior,
        floatingLabelAlignment: FloatingLabelAlignment.start,
      ),
      validator: validator,
    );
  }
}
