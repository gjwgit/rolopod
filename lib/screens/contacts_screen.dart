/// ContactsScreen — main contact list with regex search and book filter.
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
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:rolopod/constants/app.dart';
import 'package:rolopod/models/contact.dart';
import 'package:rolopod/pages/contact_detail.dart';
import 'package:rolopod/pages/contact_edit.dart';
import 'package:rolopod/services/app_provider.dart';
import 'package:rolopod/widgets/contact_tile.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  bool _regexError = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String pattern, AppProvider provider) {
    setState(() {
      try {
        if (pattern.isNotEmpty) RegExp(pattern);
        _regexError = false;
      } catch (_) {
        _regexError = true;
      }
    });
    provider.setSearchPattern(pattern);
  }

  void _openContact(BuildContext context, Contact contact) {
    showDialog<void>(
      context: context,
      builder: (_) => ContactDetail(contact: contact),
    );
  }

  void _newContact(BuildContext context) {
    final provider = context.read<AppProvider>();
    final bookName = provider.primaryBook?.name ?? defaultBookName;
    showDialog<void>(
      context: context,
      builder: (_) => ContactEdit(
        contact: Contact(bookName: bookName),
        isNew: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final contacts = provider.visibleContacts;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => _onSearchChanged(v, provider),
            decoration: InputDecoration(
              hintText: 'Search (regex)…',
              prefixIcon: MarkdownTooltip(
                message: '**Regex Search**\n\n'
                    'Filter contacts using a regular expression.\n\n'
                    'Matches against name, organisation, email, phone, tags and notes. '
                    'Examples:\n'
                    '+ `smith` — all Smiths\n'
                    '+ `@gmail` — Gmail addresses\n'
                    '+ `^A` — names starting with A\n'
                    '+ `tag:anu` — contacts tagged *anu*',
                child: Icon(
                  Icons.search,
                  color: _regexError ? cs.error : null,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('', provider);
                      },
                    )
                  : null,
              errorText: _regexError ? 'Invalid regular expression' : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        // ── Book filter chips ────────────────────────────────────────────────
        if (provider.books.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: provider.books.map((book) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(book.name),
                    selected: book.isVisible,
                    onSelected: (_) => provider.toggleBookVisibility(book.name),
                  ),
                );
              }).toList(),
            ),
          ),

        // ── Contact count ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${contacts.length} contact${contacts.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // ── Contact list ─────────────────────────────────────────────────────
        Expanded(
          child: contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.contacts_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const Gap(16),
                      Text(
                        provider.searchPattern.isEmpty
                            ? 'No contacts yet'
                            : 'No matches',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ContactTile(
                    contact: contacts[i],
                    showBook: provider.books.length > 1,
                    onTap: () => _openContact(context, contacts[i]),
                  ),
                ),
        ),
      ],
    );
  }
}
