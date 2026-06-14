/// RoloPod — home page with a welcome/overview card.
///
// Time-stamp: <2026-06-12>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
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

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:rolopod/constants/app.dart';

/// The landing page, showing a welcome card describing the app.
///
/// Security-key bootstrap and the initial Pod load are handled by
/// [AppScaffold], so this page is purely informational.
class Home extends StatelessWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.contacts,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                MarkdownBody(
                  data: '## Welcome to RoloPod!\n'
                      '\n'
                      'RoloPod is a contact manager that stores your address '
                      'books encrypted in your personal Solid Pod, so your '
                      'data stays under your control.\n'
                      '\n'
                      'Your Solid Pod can be hosted on any Solid server and '
                      'being encrypted it is protected against casual access '
                      'to your data by anyone, including the server '
                      'administrators or anyone who might breach the server.\n'
                      '\n'
                      '### Key features\n'
                      '\n'
                      '- Browse and search across multiple address books\n'
                      '- Import from BBDB or vCard files\n'
                      '- Find and merge duplicate contacts\n'
                      '- Backup and restore your contacts as JSON\n'
                      '- Share address books with other Pod owners\n'
                      '- Security key management for encrypted data\n'
                      '- Theme switching (light / dark / system)\n'
                      '\n'
                      'Use the navigation menu to get started.',
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
                const SizedBox(height: 16),
                Text(
                  appName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
