/// DuplicateCompare — comparison dialog and contact card widgets.
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
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/models/duplicate_detector.dart';

// ── Tooltip constants ─────────────────────────────────────────────────────────

const kScoreTooltip = '**Similarity Score**\n\n'
    'The percentage shown is a *name similarity score* calculated using '
    '**Jaccard similarity on character bigrams**.\n\n'
    '**How it works:**\n'
    '1. Both names are normalised (lowercased, punctuation removed).\n'
    '2. Each name is split into overlapping pairs of characters '
    '(*bigrams*) — e.g. "graham" becomes {gr, ra, ah, ha, am}.\n'
    '3. The score = shared bigrams divided by total unique bigrams across both names.\n\n'
    'A score of **100%** means the names are identical after normalisation.\n'
    'A score of **80-99%** typically indicates a spelling variation, '
    'nickname, or middle name difference.\n\n'
    '**Note:** Only the *display name* is used for matching. Two contacts '
    'with the same name but different emails or phones will still score '
    '100%. Tap a pair to compare all fields side by side.';

const kMergeTooltip = '**Merge Contacts**\n\n'
    'Merging combines the two contacts into one, keeping the **left contact '
    'as the primary** source of truth.\n\n'
    '**Field-by-field rules:**\n'
    '- **Scalar fields** (name, organisation, job title, etc.): '
    'the left value is kept; the right value fills in only if the left is empty.\n'
    '- **List fields** (emails, phones, addresses, URLs): '
    'both lists are combined and de-duplicated, left entries first.\n'
    '- **Tags:** merged into a single de-duplicated set.\n'
    '- **Notes:** both notes kept, separated by a blank line.\n'
    '- **Birthday / gender / spouse / children:** left contact wins.\n\n'
    'The merged contact is saved to the left contact address book '
    'and both originals are deleted. The change is saved to your Solid Pod.';

// ── Compare action ────────────────────────────────────────────────────────────

// ── Comparison dialog ─────────────────────────────────────────────────────────

enum CompareAction { merge, dismiss }

class ComparisonDialog extends StatelessWidget {
  final DuplicatePair pair;

  const ComparisonDialog({super.key, required this.pair});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;
    final pct = (pair.score * 100).round();

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 8,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Text(
                    'Compare contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(12),
                  MarkdownTooltip(
                    message: kScoreTooltip,
                    child: Chip(
                      label: Text(
                        '$pct% match',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: cs.primaryContainer,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // ── Side-by-side cards ──────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ContactCard(
                              contact: pair.a,
                              label: 'Left (primary if merged)',
                              cs: cs,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: _ContactCard(
                              contact: pair.b,
                              label: 'Right',
                              cs: cs,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _ContactCard(
                            contact: pair.a,
                            label: 'Left (primary if merged)',
                            cs: cs,
                          ),
                          const Gap(12),
                          _ContactCard(
                            contact: pair.b,
                            label: 'Right',
                            cs: cs,
                          ),
                        ],
                      ),
              ),
            ),

            // ── Actions ────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(CompareAction.dismiss),
                    child: const Text('Not a duplicate'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const Gap(8),
                  MarkdownTooltip(
                    message: kMergeTooltip,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.merge),
                      label: const Text('Merge'),
                      onPressed: () =>
                          Navigator.of(context).pop(CompareAction.merge),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact card (used inside comparison dialog) ──────────────────────────────

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final String label;
  final ColorScheme cs;

  const _ContactCard({
    required this.contact,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              color: cs.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          // Avatar + name
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  contact.initials,
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (contact.organisation != null)
                      Text(
                        contact.organisation!,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          // Fields
          ..._fieldRows(contact, cs),
        ],
      ),
    );
  }

  List<Widget> _fieldRows(Contact c, ColorScheme cs) {
    final rows = <Widget>[];

    void addRow(String label, String? value) {
      if (value == null || value.isEmpty) return;
      rows.add(_FieldRow(label: label, value: value, cs: cs));
      rows.add(const Gap(4));
    }

    void addList(
      String label,
      List<dynamic> items,
      String Function(dynamic) fn,
    ) {
      for (final item in items) {
        addRow(label, fn(item));
      }
    }

    addRow('Book', c.bookName);
    addList(
      'Email',
      c.emails,
      (e) => '${(e as ContactField).value} (${e.label})',
    );
    addList(
      'Phone',
      c.phones,
      (e) => '${(e as ContactField).value} (${e.label})',
    );
    addList(
      'Address',
      c.addresses,
      (a) => (a as ContactAddress).summary,
    );
    addList('URL', c.urls, (e) => (e as ContactField).value);
    if (c.birthday != null) {
      addRow(
        'Birthday',
        '${c.birthday!.day}/${c.birthday!.month}/${c.birthday!.year}',
      );
    }
    addRow('Gender', c.gender);
    addRow('Spouse', c.spouseName);
    if (c.children.isNotEmpty) addRow('Children', c.children.join(', '));
    if (c.tags.isNotEmpty) addRow('Tags', c.tags.join(', '));
    addRow('Notes', c.notes);

    return rows;
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      );
}
