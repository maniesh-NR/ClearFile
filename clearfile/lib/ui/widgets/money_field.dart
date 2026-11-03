import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field for money amounts: dollar prefix, tolerant parsing
/// ("1,234.5", "\$52,500.00", "6 200") and canonical formatting on blur.
///
/// While the field has focus the user's raw text is preserved; the value only
/// updates when the text parses (or is empty, which sets it to zero).
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.enabled = true,
  });

  final String label;
  final String? helper;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _display(widget.value));
    _focus = FocusNode();
    _focus.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (_focus.hasFocus) {
      _editing = true;
    } else if (_editing) {
      _editing = false;
      _controller.text = _display(widget.value);
    }
  }

  @override
  void didUpdateWidget(MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = _display(widget.value);
    }
  }

  static String _display(double v) => v == 0 ? '' : v.toStringAsFixed(2);

  void _onChanged(String raw) {
    final cleaned = raw
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s'), '');
    if (cleaned.isEmpty) {
      if (widget.value != 0) widget.onChanged(0);
      return;
    }
    final parsed = double.tryParse(cleaned);
    if (parsed != null && parsed != widget.value) widget.onChanged(parsed);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\$\s]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 3,
        prefixText: '\$ ',
      ),
      onChanged: _onChanged,
    );
  }
}
