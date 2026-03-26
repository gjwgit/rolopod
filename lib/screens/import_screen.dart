/// ImportScreen — import contacts from BBDB or vCard files.
///
// Time-stamp: <2026-03-22 Graham Williams>
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import Contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(8),
          Text(
            'Import from Emacs BBDB or vCard (.vcf) files. '
            'Contacts will be added to the selected address book.',
            style: TextStyle(color: cs.onSurfaceVariant),
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
          const Gap(24),
          ImportCard(
            icon: Icons.description_outlined,
            title: 'Emacs BBDB',
            subtitle: 'Import from a .bbdb file exported from Emacs.',
            loading: _loading,
            onImport: () => _pickAndImport(context, _ImportFormat.bbdb),
          ),
          const Gap(16),
          ImportCard(
            icon: Icons.contact_page_outlined,
            title: 'vCard (.vcf)',
            subtitle: 'Import from a vCard file (v3.0 or v4.0).',
            loading: _loading,
            onImport: () => _pickAndImport(context, _ImportFormat.vcard),
          ),
          const Gap(16),
          ImportCard(
            icon: Icons.backup_outlined,
            title: 'RoloPod JSON backup',
            subtitle:
                'Restore contacts from a previously exported .json backup.',
            loading: _loading,
            onImport: () => _pickAndImportJson(context),
          ),

          // ── Export ──────────────────────────────────────────────────────
          const Gap(32),
          Text(
            'Export / Backup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(8),
          Text(
            'Save a copy of an address book as a JSON file for backup '
            'or to move to another device.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const Gap(16),
          ...context.read<AppProvider>().books.map(
                (book) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ImportCard(
                    icon: Icons.download_outlined,
                    title: 'Export "${book.name}"',
                    subtitle:
                        'Save ${book.name}_YYYYMMDD_HHMM.json to your Downloads folder.',
                    loading: _loading,
                    onImport: () => _exportBook(context, book.name),
                  ),
                ),
              ),
        ],
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
      final result = await FilePicker.platform.pickFiles(
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

      // Detect book name from filename: Personal_20260326_2005.json → Personal
      final bookName = file.name
          .replaceAll(RegExp(r'_\d{8}_\d{4}'), '')
          .replaceAll(RegExp(r'\.json$'), '');
      final targetBook = provider.books.any((b) => b.name == bookName)
          ? bookName
          : provider.primaryBook?.name ?? defaultBookName;

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
      final fileName = '${bookName}_$timestamp.json';

      if (kIsWeb) {
        // Web: use FilePicker save dialog if available, else show error.
        setState(() {
          _error = 'Export to file not supported on web.';
          _loading = false;
        });
        return;
      }

      // Desktop/mobile: save to Downloads folder.
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      final downloads = Directory('$home/Downloads');
      final dir = downloads.existsSync() ? downloads : Directory(home);
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      setState(() => _loading = false);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Exported to ${file.path}'),
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
      final result = await FilePicker.platform.pickFiles(
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

      final bookName = provider.primaryBook?.name ?? defaultBookName;

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
