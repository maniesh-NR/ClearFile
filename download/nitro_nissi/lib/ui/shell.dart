/// Responsive app shell.
///
/// Wide (≥1100px): left topic rail (TurboTax-like) + center content.
/// Narrow: bottom navigation bar. The assistant and settings live on the
/// rail too, mirroring how TurboTax keeps help one click away.
library;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../l10n/app_localizations.dart';
import 'screens/home_flow.dart';
import 'screens/assistant.dart';
import 'screens/settings.dart';
import 'widgets/common.dart';

class Shell extends StatefulWidget {
  final AppState state;
  const Shell({super.key, required this.state});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _dest = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final wide = MediaQuery.of(context).size.width >= 1100;
    final scheme = Theme.of(context).colorScheme;

    final destinations = [
      _Dest(loc.navMyReturn, Icons.fact_check_outlined),
      _Dest(loc.navAssistant, Icons.auto_awesome_outlined),
      _Dest(loc.navSettings, Icons.settings_outlined),
    ];

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final result = widget.state.result;
        final lite = TaxResultLite(result.refundOrOwe.abs(), result.isRefund);
        return _buildScaffold(context, loc, wide, scheme, destinations, lite);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations loc,
    bool wide,
    ColorScheme scheme,
    List<_Dest> destinations,
    TaxResultLite lite,
  ) {
    final body = IndexedStack(
      index: _dest,
      children: [
        HomeFlow(state: widget.state),
        AssistantScreen(state: widget.state),
        SettingsScreen(state: widget.state),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.description_outlined, size: 22),
            const SizedBox(width: 8),
            Text('Nitro Nissi',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            _YearChip(state: widget.state),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: RefundMeter(lite: lite)),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _dest,
                  onDestinationSelected: (i) => setState(() => _dest = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: scheme.surface,
                  leading: const SizedBox(height: 8),
                  destinations: destinations
                      .map((d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.icon),
                            label: Text(d.label, textAlign: TextAlign.center),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : Column(
              children: [
                Expanded(child: body),
                NavigationBar(
                  selectedIndex: _dest,
                  onDestinationSelected: (i) => setState(() => _dest = i),
                  destinations: destinations
                      .map((d) => NavigationDestination(
                            icon: Icon(d.icon),
                            label: d.label,
                          ))
                      .toList(),
                ),
              ],
            ),
    );
  }
}

class _Dest {
  final String label;
  final IconData icon;
  const _Dest(this.label, this.icon);
}

class _YearChip extends StatelessWidget {
  final AppState state;
  const _YearChip({required this.state});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      initialValue: state.data.taxYear,
      onSelected: state.setTaxYear,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 2025, child: Text('Tax year 2025')),
        PopupMenuItem(value: 2024, child: Text('Tax year 2024')),
      ],
      child: Chip(
        avatar: const Icon(Icons.calendar_today, size: 14),
        label: Text('TY${state.data.taxYear}'),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
