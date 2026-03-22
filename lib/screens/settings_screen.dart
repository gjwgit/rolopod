/// SettingsScreen — manage address books, sharing and preferences.
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

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:rolopod/models/address_book.dart';
import 'package:rolopod/services/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address Books',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(16),
          ...provider.books.map((book) => _BookTile(book: book)),
          const Gap(8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New address book'),
            onPressed: () => _newBook(context, provider),
          ),
        ],
      ),
    );
  }

  void _newBook(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New address book'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.addBook(
                  AddressBook(
                    name: name,
                    podPath: 'rolopod/books/$name.json',
                    ownerWebId: '',
                  ),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final AddressBook book;

  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          book.isSharedWithMe ? Icons.folder_shared : Icons.folder_outlined,
          color: cs.primary,
        ),
        title: Text(book.name),
        subtitle: Text(
          book.isSharedWithMe
              ? 'Shared with you'
              : book.sharedWith.isEmpty
                  ? 'Private'
                  : 'Shared with ${book.sharedWith.length} '
                      'person${book.sharedWith.length == 1 ? '' : 's'}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant,
        ),
        onTap: () {
          // TODO: open book settings (sharing, rename, delete)
        },
      ),
    );
  }
}
