/// ImportScreen — import contacts from BBDB or vCard files.
///
// Time-stamp: <Tuesday 2026-04-21 14:20:32 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program. If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:rolopod/constants/app.dart';
import 'package:rolopod/models/contact.dart';
import 'package:rolopod/models/contact_parser.dart';
import 'package:rolopod/screens/import_widgets.dart';
import 'package:rolopod/services/app_provider.dart';

enum _ImportFormat { bbdb, vcard }

class _ParseArgs {
  final String content;
  final String bookName;
  final _ImportFormat format;

  const _ParseArgs({
    required this.content,
    required this.bookName,
    required this.format,
  });
}

List<Contact> _parseContacts(_ParseArgs args) => switch (args.format) {
      _ImportFormat.bbdb => parseBbdb(args.content, bookName: args.bookName),
      _ImportFormat.vcard => parseVcard(args.content, bookName: args.bookName),
    };

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _loading = false;
  String? _error;

  /// The address book that import/export actions operate on. Defaults to the
  /// first available book; resolved in [build] against the current book list.
  String? _selectedBook;

  /// Resolve the selected book name against the current book list, falling
  /// back to the first available book (or null when there are none).
  String? _resolvedBook(AppProvider provider) {
    final names = provider.books.map((b) => b.name).toList();
    if (_selectedBook != null && names.contains(_selectedBook)) {
      return _selectedBook;
    }
    return names.isNotEmpty ? names.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();
    final books = provider.books;
    final bookNames = books.map((b) => b.name).toList();

    // Resolve the selected book against the current list.
    final selected =
        (_selectedBook != null && bookNames.contains(_selectedBook))
            ? _selectedBook!
            : (bookNames.isNotEmpty ? bookNames.first : null);
    final count = selected == null ? 0 : provider.contactCountForBook(selected);
    final entryWord = count == 1 ? 'entry' : 'entries';

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Address book selector ────────────────────────────────────
            Text(
              'Address Book',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Gap(8),
            Text(
              'Choose the address book that the import and export actions '
              'below apply to.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const Gap(12),
            DropdownMenu<String>(
              initialSelection: selected,
              label: const Text('Address book'),
              enabled: bookNames.isNotEmpty,
              onSelected: (value) => setState(() => _selectedBook = value),
              dropdownMenuEntries: [
                for (final name in bookNames)
                  DropdownMenuEntry<String>(
                    value: name,
                    label: '$name (${provider.contactCountForBook(name)})',
                  ),
              ],
            ),
            if (_error != null) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.onErrorContainer),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Backup & Restore ──────────────────────────────────────────
            const Gap(32),
            Text(
              'Backup & Restore',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Gap(8),
            Text(
              'Save a copy of the selected address book as a JSON file for '
              'backup or to move to another device, or restore contacts from '
              'a previously saved JSON backup.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MarkdownTooltip(
                  message: selected == null
                      ? 'No address book available to export.'
                      : '**Export Backup**\n\n'
                          'Save a JSON backup of "$selected" '
                          '($count $entryWord) as '
                          'rolopod_${selected}_YYYYMMDD_HHMM.json. You will '
                          'be prompted for where to save it. Keep it '
                          'somewhere safe so you can restore it later.',
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export Backup'),
                    onPressed: (_loading || selected == null)
                        ? null
                        : () => _exportBook(context, selected),
                  ),
                ),
                MarkdownTooltip(
                  message: '**Import Backup**\n\n'
                      'Restore contacts from a previously exported RoloPod '
                      'JSON backup file. Restored contacts are merged into '
                      'the matching address book.',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Import Backup'),
                    onPressed:
                        _loading ? null : () => _pickAndImportJson(context),
                  ),
                ),
              ],
            ),

            // ── Export ────────────────────────────────────────────────────
            const Gap(32),
            Text('Export', style: Theme.of(context).textTheme.titleLarge),
            const Gap(8),
            Text(
              'Export the selected address book to an Emacs BBDB or vCard '
              '(.vcf) file for use in other applications.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MarkdownTooltip(
                  message: selected == null
                      ? 'No address book available to export.'
                      : '**Export to BBDB**\n\n'
                          'Save "$selected" ($count $entryWord) as an Emacs '
                          'BBDB (.bbdb) file. You will be prompted for where '
                          'to save it.',
                  child: FilledButton.icon(
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Export to BBDB'),
                    onPressed: (_loading || selected == null)
                        ? null
                        : () => _exportFormat(
                              context,
                              selected,
                              _ImportFormat.bbdb,
                            ),
                  ),
                ),
                MarkdownTooltip(
                  message: selected == null
                      ? 'No address book available to export.'
                      : '**Export to vCard**\n\n'
                          'Save "$selected" ($count $entryWord) as a vCard '
                          '(.vcf) file. You will be prompted for where to '
                          'save it.',
                  child: FilledButton.icon(
                    icon: const Icon(Icons.contact_page_outlined),
                    label: const Text('Export to vCard'),
                    onPressed: (_loading || selected == null)
                        ? null
                        : () => _exportFormat(
                              context,
                              selected,
                              _ImportFormat.vcard,
                            ),
                  ),
                ),
              ],
            ),

            // ── Import ────────────────────────────────────────────────────
            const Gap(32),
            Text('Import', style: Theme.of(context).textTheme.titleLarge),
            const Gap(8),
            Text(
              'Import from Emacs BBDB or vCard (.vcf) files. Contacts will be '
              'added to the selected address book.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MarkdownTooltip(
                  message: '**Emacs BBDB**\n\n'
                      'Import contacts from a .bbdb file exported from Emacs '
                      'into the selected address book.',
                  child: FilledButton.icon(
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Emacs BBDB'),
                    onPressed: _loading
                        ? null
                        : () => _pickAndImport(context, _ImportFormat.bbdb),
                  ),
                ),
                MarkdownTooltip(
                  message: '**vCard (.vcf)**\n\n'
                      'Import contacts from a vCard file (v3.0 or v4.0) into '
                      'the selected address book.',
                  child: FilledButton.icon(
                    icon: const Icon(Icons.contact_page_outlined),
                    label: const Text('vCard (.vcf)'),
                    onPressed: _loading
                        ? null
                        : () => _pickAndImport(context, _ImportFormat.vcard),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── JSON backup import ─────────────────────────────────────────────────────

  Future<void> _pickAndImportJson(BuildContext context) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Capture context-dependent objects before the first await.
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select RoloPod JSON backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        setState(() {
          _error = 'Could not read file contents.';
          _loading = false;
        });
        return;
      }

      final content = utf8.decode(file.bytes!);

      // Detect book name from filename, e.g.
      // rolopod_Personal_20260326_2005.json → Personal. Tolerates older
      // backups without the rolopod_ prefix.
      final bookName = file.name
          .replaceAll(RegExp(r'^rolopod_'), '')
          .replaceAll(RegExp(r'_\d{8}_\d{4}'), '')
          .replaceAll(RegExp(r'\.json$'), '');
      final targetBook = provider.books.any((b) => b.name == bookName)
          ? bookName
          : _resolvedBook(provider) ??
              provider.primaryBook?.name ??
              defaultBookName;

      // Parse the JSON contact list
      final decoded = jsonDecode(content) as List?;
      if (decoded == null || decoded.isEmpty) {
        setState(() {
          _error = 'No contacts found in "${file.name}".';
          _loading = false;
        });
        return;
      }

      final contacts = decoded
          .map(
            (j) => Contact.fromJson(j as Map<String, dynamic>)
                .copyWith(bookName: targetBook),
          )
          .toList();

      setState(() => _loading = false);
      if (!context.mounted) return;

      final confirmed = await showDialog<ImportResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ImportConfirmDialog(
          fileName: file.name,
          contacts: contacts,
          initialBook: targetBook,
          availableBooks: provider.books.isEmpty
              ? [targetBook]
              : provider.books.map((b) => b.name).toList(),
        ),
      );

      if (confirmed != null && context.mounted) {
        final toImport = contacts
            .map((c) => c.copyWith(bookName: confirmed.bookName))
            .toList();
        provider.importContacts(toImport, bookName: confirmed.bookName);
        final error = await provider.saveBookToPod(confirmed.bookName);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error != null
                  ? 'Imported but failed to save to pod: $error'
                  : 'Restored ${toImport.length} contact'
                      '${toImport.length == 1 ? '' : 's'} '
                      'into "${confirmed.bookName}".',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[Import] JSON error: $e\n$st');
      setState(() {
        _error = 'Import failed: $e';
        _loading = false;
      });
    }
  }

  // ── JSON export ────────────────────────────────────────────────────────────

  Future<void> _exportBook(BuildContext context, String bookName) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Capture context-dependent objects before the first await.
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final json = const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(provider.serialiseBook(bookName)));
      final bytes = utf8.encode(json);
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'rolopod_${bookName}_$timestamp.json';

      // Prompt for where to save the backup.
      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save JSON Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: kIsWeb ? bytes : null,
      );

      // User cancelled the save dialog.
      if (savePath == null) {
        setState(() => _loading = false);
        return;
      }

      // On web the bytes are written by the browser via the save dialog; on
      // desktop/mobile write them to the chosen path.
      if (!kIsWeb) {
        await File(savePath).writeAsBytes(bytes);
      }

      setState(() => _loading = false);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Exported to $savePath'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, st) {
      debugPrint('[Export] error: $e\n$st');
      setState(() {
        _error = 'Export failed: $e';
        _loading = false;
      });
    }
  }

  // ── BBDB / vCard export ──────────────────────────────────────────────────

  /// Export [bookName] to a BBDB or vCard file, prompting for the location.
  Future<void> _exportFormat(
    BuildContext context,
    String bookName,
    _ImportFormat format,
  ) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Capture context-dependent objects before the first await.
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // serialiseBook returns the book's contacts as a JSON list; decode them
      // back into Contact objects to feed the format serialisers.
      final decoded = jsonDecode(provider.serialiseBook(bookName)) as List;
      final contacts = decoded
          .map((j) => Contact.fromJson(j as Map<String, dynamic>))
          .toList();

      final ext = format == _ImportFormat.bbdb ? 'bbdb' : 'vcf';
      final content =
          format == _ImportFormat.bbdb ? toBbdb(contacts) : toVcard(contacts);
      final bytes = utf8.encode(content);

      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'rolopod_${bookName}_$timestamp.$ext';

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save ${ext.toUpperCase()} Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [ext],
        bytes: kIsWeb ? bytes : null,
      );

      if (savePath == null) {
        setState(() => _loading = false);
        return;
      }

      if (!kIsWeb) {
        await File(savePath).writeAsBytes(bytes);
      }

      setState(() => _loading = false);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Exported to $savePath'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, st) {
      debugPrint('[Export] format error: $e\n$st');
      setState(() {
        _error = 'Export failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pickAndImport(
    BuildContext context,
    _ImportFormat format,
  ) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Capture context-dependent objects before the first await.
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: switch (format) {
          _ImportFormat.bbdb => 'Select BBDB file',
          _ImportFormat.vcard => 'Select vCard file',
        },
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;
      final String content;

      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else {
        setState(() {
          _error = 'Could not read file contents.';
          _loading = false;
        });
        return;
      }

      if (!context.mounted) return;

      final bookName = _resolvedBook(provider) ??
          provider.primaryBook?.name ??
          defaultBookName;

      final contacts = await compute(
        _parseContacts,
        _ParseArgs(content: content, bookName: bookName, format: format),
      );

      setState(() => _loading = false);

      if (!context.mounted) return;

      if (contacts.isEmpty) {
        setState(() => _error = 'No contacts found in "${file.name}".');
        return;
      }

      final confirmed = await showDialog<ImportResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ImportConfirmDialog(
          fileName: file.name,
          contacts: contacts,
          initialBook: bookName,
          availableBooks: provider.books.isEmpty
              ? [bookName]
              : provider.books.map((b) => b.name).toList(),
        ),
      );

      if (confirmed != null && context.mounted) {
        final importContacts = contacts
            .map((c) => c.copyWith(bookName: confirmed.bookName))
            .toList();
        provider.importContacts(importContacts, bookName: confirmed.bookName);
        // Persist to pod.
        final error = await provider.saveBookToPod(confirmed.bookName);
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error != null
                  ? 'Imported but failed to save to pod: $error'
                  : 'Imported ${importContacts.length} contact'
                      '${importContacts.length == 1 ? '' : 's'} '
                      'into "${confirmed.bookName}".',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[Import] error: $e\n$st');
      setState(() {
        _error = 'Import failed: $e';
        _loading = false;
      });
    }
  }
}
