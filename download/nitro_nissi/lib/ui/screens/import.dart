/// Import screen — open a TurboTax (best-effort) / CSV / JSON / .nnx file
/// or paste document text; AI extraction when configured; everything lands
/// in a review table before being applied. Nothing is written silently.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../core/io/tax_file.dart';
import '../../core/io/importer_tt.dart';
import '../../core/ai/ai_client.dart';
import '../../core/ai/prompts.dart';
import '../../services/platform_io.dart';
import '../shell.dart';

class ImportScreen extends StatefulWidget {
  final AppState state;
  const ImportScreen({super.key, required this.state});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _pasteController = TextEditingController();
  ImportPreview? _preview;
  String? _sourceName;
  Set<int> _accepted = {};
  bool _busy = false;
  String? _note;

  Future<void> _pickFile() async {
    setState(() => _busy = true);
    try {
      final opened = await const PlatformIo().pickOpen();
      if (opened == null) return;
      _sourceName = opened.name;
      // Native format first.
      if (opened.name.toLowerCase().endsWith('.nnx') ||
          opened.name.toLowerCase().endsWith('.json')) {
        final text = utf8.decode(opened.bytes, allowMalformed: true);
        try {
          final data = TaxFile.load(text);
          widget.state.loadReturn(data, path: opened.path);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => Shell(state: widget.state)));
          return;
        } catch (_) {
          // fall through to structural analysis
        }
      }
      final importer = TurboTaxImporter();
      setState(() {
        _preview = importer.analyze(
            Uint8List.fromList(opened.bytes), opened.name);
        _accepted = {
          for (var i = 0; i < _preview!.fields.length; i++) i,
        };
        _note = _preview!.note;
      });
    } catch (e) {
      setState(() => _note = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extractFromPaste() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      // Try AI extraction when keys exist and enabled; else structural scan.
      if (widget.state.ai.autoExtractPastedDocs &&
          (widget.state.ai.googleApiKey.isNotEmpty ||
              widget.state.ai.mistralApiKey.isNotEmpty)) {
        try {
          final reply = await AiClient().send(
            settings: widget.state.ai,
            system: AiPrompts.systemAssistant,
            user: AiPrompts.extractionPrompt('W-2 / 1099', text),
          );
          final cleaned =
              reply.text.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
          final j = jsonDecode(cleaned) as Map<String, dynamic>;
          final fields = <ImportField>[];
          void add(String key, String label, Object? v) {
            if (v == null) return;
            fields.add(ImportField(key, label, v, 0.85, 'AI:${reply.model}'));
          }

          add('w2.employer', 'Employer name', j['employerName']);
          add('w2.ein', 'Employer EIN', j['employerEin']);
          add('w2.wages', 'W-2 wages (Box 1)', j['wages']);
          add('w2.withholding', 'Federal withholding (Box 2)', j['federalWithholding']);
          add('w2.ssWages', 'Social Security wages (Box 3)', j['ssWages']);
          add('w2.ssWithholding', 'Social Security withheld (Box 4)', j['ssWithholding']);
          add('w2.medicareWithholding', 'Medicare withheld (Box 6)', j['medicareWithholding']);
          add('w2.qualifiedTips', 'Qualified tips (OBBBA)', j['qualifiedTips']);
          add('w2.qualifiedOvertime', 'Qualified overtime (OBBBA)', j['qualifiedOvertime']);
          setState(() {
            _preview = ImportPreview('ai-extract', 'importNotePreview', fields);
            _sourceName = 'pasted text';
            _accepted = {for (var i = 0; i < fields.length; i++) i};
          });
          return;
        } on AiException {
          // fall through to structural
        }
      }
      final importer = TurboTaxImporter();
      final bytes = Uint8List.fromList(utf8.encode(text));
      setState(() {
        _preview = importer.analyze(bytes, 'pasted.txt');
        _sourceName = 'pasted text';
        _accepted = {
          for (var i = 0; i < _preview!.fields.length; i++) i,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    if (_preview == null) return;
    final acceptedFields = [
      for (var i = 0; i < _preview!.fields.length; i++)
        if (_accepted.contains(i)) _preview!.fields[i],
    ];
    widget.state.mutate((d) => applyImport(d, acceptedFields));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Shell(state: widget.state)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(title: Text(loc.importTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.importIntro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.file_open),
                label: Text(loc.chooseFile),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _extractFromPaste,
                icon: const Icon(Icons.auto_fix_high),
                label: Text(loc.extractPasted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pasteController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: loc.pasteLabel,
              hintText: loc.pasteHint,
            ),
          ),
          if (_busy) const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator())),
          if (preview != null) ...[
            const SizedBox(height: 16),
            Text('${loc.detectedFormat}: ${preview.detectedFormat}'
                '${_sourceName != null ? ' · $_sourceName' : ''}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(loc.reviewImportNote,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (preview.isEmpty)
              Text(loc.nothingFound,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < preview.fields.length; i++)
                    CheckboxListTile(
                      value: _accepted.contains(i),
                      onChanged: (v) => setState(() {
                        v == true ? _accepted.add(i) : _accepted.remove(i);
                      }),
                      title: Text(
                          '${preview.fields[i].label}: ${preview.fields[i].value}'),
                      subtitle: Text(
                          '${preview.fields[i].source} · confidence ${(preview.fields[i].confidence * 100).toStringAsFixed(0)}%'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _accepted.isEmpty ? null : _apply,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(loc.applyFields(_accepted.length)),
            ),
          ],
          if (_note != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_note!, style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 24),
          Text(loc.importFaq, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Tiny adapter so importer code gets Uint8List without dart:typed_data here.
class Uint8ListBytesWrap {
  final List<int> bytes;
  const Uint8ListBytesWrap(this.bytes);
}
