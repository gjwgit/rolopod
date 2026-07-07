/// ImportWidgets — confirmation dialog and import card for ImportScreen.
///
// Time-stamp: <Monday 2026-06-15 19:29:44 +1000 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:rolopod/models/contact.dart';

// ── Import result ─────────────────────────────────────────────────────────────

class ImportResult {
  final String bookName;

  const ImportResult({required this.bookName});
}

// ── Confirmation dialog ───────────────────────────────────────────────────────

class ImportConfirmDialog extends StatefulWidget {
  final String fileName;
  final List<Contact> contacts;
  final String initialBook;
  final List<String> availableBooks;

  const ImportConfirmDialog({
    super.key,
    required this.fileName,
    required this.contacts,
    required this.initialBook,
    required this.availableBooks,
  });

  @override
  State<ImportConfirmDialog> createState() => ImportConfirmDialogState();
}

class ImportConfirmDialogState extends State<ImportConfirmDialog> {
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
                initialValue: _selectedBook,
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
            ImportResult(bookName: _selectedBook),
          ),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
