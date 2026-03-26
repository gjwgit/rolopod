/// SettingsScreen — manage address books, sharing and preferences.
///
// Time-stamp: <Tuesday 2026-03-24 08:17:30 +1100 Graham Williams>
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
import 'package:solidui/solidui.dart';

import 'package:rolopod/constants/app.dart';
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
          const Gap(32),
          Text(
            'Shared With Me',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(8),
          Text(
            'Address books that others have shared with you.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Gap(16),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_shared_outlined),
            label: const Text('View shared resources'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SharedResourcesUi(
                  child: _ReturnPage(),
                ),
              ),
            ),
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
                    podPath: '$podBooksPath/$name.ttl',
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

// ── Book tile with sharing actions ────────────────────────────────────────────

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
        // Only show sharing actions for books the user owns.
        trailing: book.isSharedWithMe
            ? null
            : IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Manage sharing',
                onPressed: () => _manageSharing(context, book),
              ),
      ),
    );
  }
}

void _manageSharing(BuildContext context, AddressBook book) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => GrantPermissionUi(
        resourceName: '${book.name}.ttl',
        child: const _ReturnPage(),
      ),
    ),
  );
}

// ── Simple back-navigation page used as child of solidpod UI widgets ──────────

class _ReturnPage extends StatelessWidget {
  const _ReturnPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(appName)),
        body: Center(
          child: FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Return to Settings'),
          ),
        ),
      );
}
