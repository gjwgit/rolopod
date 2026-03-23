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

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/pages/contact_edit.dart';
import 'package:rolopod/pages/detail_widgets.dart';
import 'package:rolopod/services/app_provider.dart';

class ContactDetail extends StatefulWidget {
  final Contact contact;

  const ContactDetail({
    super.key,
    required this.contact,
  });

  @override
  State<ContactDetail> createState() => _ContactDetailState();
}

class _ContactDetailState extends State<ContactDetail> {
  late Contact _contact;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Future<void> _openEdit(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ContactEdit(contact: _contact),
    );
    // Refresh from provider in case the contact was updated.
    if (!context.mounted) return;
    final provider = context.read<AppProvider>();
    final updated = provider.findContactById(_contact.id);
    if (updated != null) setState(() => _contact = updated);
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contact;
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
                      DetailSection(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        fields: contact.emails,
                      ),
                      const Gap(12),
                    ],
                    if (contact.phones.isNotEmpty) ...[
                      DetailSection(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        fields: contact.phones,
                      ),
                      const Gap(12),
                    ],
                    if (contact.addresses.isNotEmpty) ...[
                      DetailAddressSection(addresses: contact.addresses),
                      const Gap(12),
                    ],
                    if (contact.urls.isNotEmpty) ...[
                      DetailSection(
                        icon: Icons.link,
                        label: 'Web',
                        fields: contact.urls,
                      ),
                      const Gap(12),
                    ],
                    if (contact.birthday != null) ...[
                      DetailInfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Birthday',
                        value: '${contact.birthday!.day}/'
                            '${contact.birthday!.month}/'
                            '${contact.birthday!.year}',
                        cs: cs,
                      ),
                      const Gap(12),
                    ],
                    if (contact.gender != null &&
                        contact.gender!.isNotEmpty) ...[
                      DetailInfoRow(
                        icon: Icons.person_outline,
                        label: 'Gender',
                        value: contact.gender!,
                        cs: cs,
                      ),
                      const Gap(12),
                    ],
                    if (contact.spouseName != null &&
                        contact.spouseName!.isNotEmpty) ...[
                      DetailSpouseRow(
                        spouseName: contact.spouseName!,
                        cs: cs,
                      ),
                      const Gap(12),
                    ],
                    if (contact.children.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.child_care,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Children',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Gap(2),
                                ...contact.children.map(
                                  (child) => Text(
                                    child,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                    if (contact.notes != null && contact.notes!.isNotEmpty) ...[
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
                                const Gap(4),
                                MarkdownBody(
                                  data: contact.notes!,
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
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
                    onPressed: () => _openEdit(context),
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
        content: Text('Remove ${_contact.name} from ${_contact.bookName}?'),
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
              final bookName = _contact.bookName;
              provider.deleteContact(_contact.id);
              provider.saveBookToPod(bookName);
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
