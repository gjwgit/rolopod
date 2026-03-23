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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:rolopod/constants/app.dart';
import 'package:rolopod/models/contact.dart';
import 'package:rolopod/models/contact_parser.dart';
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
          _ImportCard(
            icon: Icons.description_outlined,
            title: 'Emacs BBDB',
            subtitle: 'Import from a .bbdb file exported from Emacs.',
            loading: _loading,
            onImport: () => _pickAndImport(context, _ImportFormat.bbdb),
          ),
          const Gap(16),
          _ImportCard(
            icon: Icons.contact_page_outlined,
            title: 'vCard (.vcf)',
            subtitle: 'Import from a vCard file (v3.0 or v4.0).',
            loading: _loading,
            onImport: () => _pickAndImport(context, _ImportFormat.vcard),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImport(
    BuildContext context,
    _ImportFormat format,
  ) async {
    setState(() {
      _loading = true;
      _error = null;
    });

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

      final provider = context.read<AppProvider>();
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

      final confirmed = await showDialog<_ImportResult>(
        context: context,
        builder: (_) => _ImportConfirmDialog(
          fileName: file.name,
          contacts: contacts,
          initialBook: bookName,
          availableBooks:
              provider.books.isEmpty ? [bookName] : provider.books.map((b) => b.name).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
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

// ── Import result ─────────────────────────────────────────────────────────────

class _ImportResult {
  final String bookName;

  const _ImportResult({required this.bookName});
}

// ── Confirmation dialog ───────────────────────────────────────────────────────

class _ImportConfirmDialog extends StatefulWidget {
  final String fileName;
  final List<Contact> contacts;
  final String initialBook;
  final List<String> availableBooks;

  const _ImportConfirmDialog({
    required this.fileName,
    required this.contacts,
    required this.initialBook,
    required this.availableBooks,
  });

  @override
  State<_ImportConfirmDialog> createState() => _ImportConfirmDialogState();
}

class _ImportConfirmDialogState extends State<_ImportConfirmDialog> {
  late String _selectedBook;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.initialBook;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = widget.contacts.take(5).toList();
    final remaining = widget.contacts.length - preview.length;

    return AlertDialog(
      title: const Text('Confirm import'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${widget.contacts.length} contact'
              '${widget.contacts.length == 1 ? '' : 's'} '
              'in "${widget.fileName}".',
            ),
            const Gap(16),

            // Book selector
            if (widget.availableBooks.length > 1) ...[
              Text(
                'Import into:',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const Gap(8),
              DropdownButtonFormField<String>(
                value: _selectedBook,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.availableBooks
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedBook = v);
                },
              ),
              const Gap(16),
            ],

            // Preview list
            Text(
              'Preview:',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
            ...preview.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.primaryEmail != null)
                      Text(
                        c.primaryEmail!,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '… and $remaining more.',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _ImportResult(bookName: _selectedBook),
          ),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

// ── Import card ───────────────────────────────────────────────────────────────

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onImport;

  const _ImportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: cs.primary),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton.tonal(
                    onPressed: onImport,
                    child: const Text('Choose file'),
                  ),
          ],
        ),
      ),
    );
  }
}
