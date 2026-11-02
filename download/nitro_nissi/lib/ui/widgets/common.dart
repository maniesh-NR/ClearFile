/// Shared MD3 widgets: money/text fields, choice cards, toggles, refund
/// meter, info panel, banners.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

String money(double v, {bool withSign = false}) {
  final neg = v < 0;
  final a = v.abs().round();
  final s = a.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  final sign = neg ? '-' : (withSign ? '+' : '');
  return '$sign\$$s';
}

/// Money input: keeps text entry natural, commits a double on change.
class MoneyField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? hint;

  const MoneyField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final controller =
        TextEditingController(text: value == 0 ? '' : value.round().toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: '\$ ',
        ),
        onChanged: (t) {
          final v = double.tryParse(t.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          onChanged(v);
        },
      ),
    );
  }
}

class TextFieldSpec extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool obscure;

  const TextFieldSpec({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: TextEditingController(text: value),
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, hintText: hint),
        onChanged: onChanged,
      ),
    );
  }
}

/// MD3 single-choice card row (TurboTax-style question with card options).
class ChoiceCards<T> extends StatelessWidget {
  final String label;
  final T? value;
  final Map<T, String> options; // value -> label
  final ValueChanged<T> onChanged;

  const ChoiceCards({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((e) {
              final selected = e.key == value;
              return FilterChip(
                selected: selected,
                label: Text(e.value),
                onSelected: (_) => onChanged(e.key),
                selectedColor: scheme.secondaryContainer,
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Top-right refund/owe indicator used across screens (TurboTax-like).
class RefundMeter extends StatelessWidget {
  final TaxResultLite lite;
  const RefundMeter({super.key, required this.lite});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final color = lite.isRefund ? scheme.primary : scheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: lite.isRefund
            ? scheme.primaryContainer.withAlpha(140)
            : scheme.errorContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(lite.isRefund ? Icons.savings : Icons.account_balance_wallet,
              size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            lite.isRefund
                ? '${loc.refundEstimate} ${money(lite.amount)}'
                : '${loc.oweEstimate} ${money(lite.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Minimal result snapshot for widgets that must not depend on the engine.
class TaxResultLite {
  final double amount;
  final bool isRefund;
  const TaxResultLite(this.amount, this.isRefund);
}

/// Right-hand info panel content (TurboTax-like "Explain" pane).
class InfoPanel extends StatelessWidget {
  final String title;
  final String body;
  const InfoPanel({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_outline, color: scheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class SeverityBanner extends StatelessWidget {
  final bool isError;
  final bool isWarning;
  final String message;
  const SeverityBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError
        ? scheme.errorContainer
        : isWarning
            ? scheme.tertiaryContainer
            : scheme.secondaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? scheme.onErrorContainer : scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
