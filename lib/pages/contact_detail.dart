/// ContactDetail — full detail popup for a single contact.
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

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/pages/contact_edit.dart';
import 'package:rolopod/services/app_provider.dart';

class ContactDetail extends StatelessWidget {
  final Contact contact;

  const ContactDetail({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.primary,
                    child: Text(
                      contact.initials,
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        if (contact.jobTitle != null ||
                            contact.organisation != null)
                          Text(
                            [contact.jobTitle, contact.organisation]
                                .whereType<String>()
                                .join(' · '),
                            style: TextStyle(
                              color: cs.onPrimaryContainer.withValues(
                                alpha: 0.75,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        const Gap(4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            contact.bookName,
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contact.emails.isNotEmpty) ...[
                      _Section(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        fields: contact.emails,
                      ),
                      const Gap(12),
                    ],
                    if (contact.phones.isNotEmpty) ...[
                      _Section(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        fields: contact.phones,
                      ),
                      const Gap(12),
                    ],
                    if (contact.addresses.isNotEmpty) ...[
                      _AddressSection(addresses: contact.addresses),
                      const Gap(12),
                    ],
                    if (contact.urls.isNotEmpty) ...[
                      _Section(
                        icon: Icons.link,
                        label: 'Web',
                        fields: contact.urls,
                      ),
                      const Gap(12),
                    ],
                    if (contact.birthday != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const Gap(12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Birthday',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${contact.birthday!.day}/'
                                '${contact.birthday!.month}/'
                                '${contact.birthday!.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Gap(12),
                    ],
                    if (contact.tags.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.label_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const Gap(12),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: contact.tags.map((tag) {
                                final cs = Theme.of(context).colorScheme;
                                return Chip(
                                  label: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                  backgroundColor: cs.secondaryContainer,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                    ],
                    if (contact.notes != null &&
                        contact.notes!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  contact.notes!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Actions ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.error,
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const Gap(8),
                  FilledButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog<void>(
                        context: context,
                        builder: (_) => ContactEdit(contact: contact),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final provider = context.read<AppProvider>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove ${contact.name} from ${contact.bookName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              provider.deleteContact(contact.id);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<ContactField> fields;

  const _Section({
    required this.icon,
    required this.label,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(2),
              ...fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(f.value, style: const TextStyle(fontSize: 13)),
                      ),
                      if (f.label.isNotEmpty)
                        Text(
                          f.label,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressSection extends StatelessWidget {
  final List<ContactAddress> addresses;

  const _AddressSection({required this.addresses});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: cs.onSurfaceVariant),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(2),
              ...addresses.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(a.summary, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
