/// Welcome — start, continue, open or import a return.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../core/io/tax_file.dart';
import '../../services/platform_io.dart';
import '../shell.dart';
import 'import.dart';
import 'eligibility.dart';

class WelcomeScreen extends StatefulWidget {
  final AppState state;
  const WelcomeScreen({super.key, required this.state});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  Future<void> _openFile() async {
    setState(() => _busy = true);
    try {
      final opened = await const PlatformIo().pickOpen();
      if (opened == null) return;
      final text = String.fromCharCodes(opened.bytes);
      final data = TaxFile.load(text);
      widget.state.loadReturn(data, path: opened.path);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Shell(state: widget.state)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.openFailed(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width >= 800;

    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: Text(loc.startNewReturn),
          onPressed: _busy
              ? null
              : () {
                  widget.state.newReturn(taxYear: widget.state.data.taxYear);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => EligibilityScreen(state: widget.state)));
                },
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: Text(loc.openReturnFile),
          onPressed: _busy ? null : _openFile,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.download_for_offline_outlined),
          label: Text(loc.importFromOther),
          onPressed: _busy
              ? null
              : () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ImportScreen(state: widget.state)));
                },
        ),
        if (widget.state.firstRunDone) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(Icons.history),
            label: Text(loc.continueLastReturn),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => Shell(state: widget.state)));
            },
          ),
        ],
      ],
    );

    final hero = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.description_outlined, size: 40, color: scheme.primary),
          const SizedBox(width: 12),
          Text('Nitro Nissi',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        Text(loc.welcomeTagline,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Text(loc.welcomePrivacyNote,
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: wide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: hero),
                        const SizedBox(width: 48),
                        SizedBox(width: 360, child: actions),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [hero, const SizedBox(height: 32), actions],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
