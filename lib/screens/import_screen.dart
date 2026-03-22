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

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

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
          const Gap(24),
          _ImportCard(
            icon: Icons.description_outlined,
            title: 'Emacs BBDB',
            subtitle: 'Import from a .bbdb file exported from Emacs.',
            onImport: () => _importBbdb(context),
          ),
          const Gap(16),
          _ImportCard(
            icon: Icons.contact_page_outlined,
            title: 'vCard (.vcf)',
            subtitle: 'Import from a vCard file (v3.0 or v4.0).',
            onImport: () => _importVcard(context),
          ),
        ],
      ),
    );
  }

  void _importBbdb(BuildContext context) {
    // TODO: file picker → parseBbdb → provider.importContacts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('BBDB import coming soon')),
    );
  }

  void _importVcard(BuildContext context) {
    // TODO: file picker → parseVcard → provider.importContacts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('vCard import coming soon')),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onImport;

  const _ImportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            FilledButton.tonal(
              onPressed: onImport,
              child: const Text('Choose file'),
            ),
          ],
        ),
      ),
    );
  }
}
