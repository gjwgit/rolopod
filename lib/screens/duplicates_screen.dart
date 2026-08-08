/// DuplicatesScreen — find and merge duplicate contacts.
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
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:rolopod/models/duplicate_detector.dart';
import 'package:rolopod/screens/duplicate_compare.dart';
import 'package:rolopod/services/app_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  List<DuplicatePair>? _pairs;
  bool _scanning = false;

  Future<void> _scan(AppProvider provider) async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final pairs = provider.scanForDuplicates();
    setState(() {
      _pairs = pairs;
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final pairs = _pairs;

    if (_scanning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pairs == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.content_copy_outlined,
                size: 64,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const Gap(16),
              const Text(
                'Find duplicate contacts',
                style: TextStyle(fontSize: 16),
              ),
              const Gap(8),
              Text(
                'Scan all visible address books for contacts with '
                'similar names.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const Gap(24),
              FilledButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Scan for duplicates'),
                onPressed: () => _scan(provider),
              ),
            ],
          ),
        ),
      );
    }

    if (pairs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: cs.primary),
            const Gap(16),
            const Text('No duplicates found', style: TextStyle(fontSize: 16)),
            const Gap(24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Scan again'),
              onPressed: () => _scan(provider),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${pairs.length} potential '
                'duplicate${pairs.length == 1 ? '' : 's'} — '
                'tap a pair to compare',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Rescan'),
                onPressed: () => _scan(provider),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: pairs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _DuplicateTile(
              pair: pairs[i],
              onTap: () => _showComparison(context, pairs[i], i, provider),
              onMerge: (pair) => _doMerge(pair, i, provider),
              onDismiss: () => setState(() {
                _pairs = List.from(pairs)..removeAt(i);
              }),
            ),
          ),
        ),
      ],
    );
  }

  void _doMerge(DuplicatePair pair, int i, AppProvider provider) {
    provider.mergeDuplicates(pair, targetBook: pair.a.bookName);
    SolidWriteFailures.watch(
      provider.saveBookToPod(pair.a.bookName),
      during: 'merging the duplicates',
    );
    setState(() {
      _pairs = List.from(_pairs!)..removeAt(i);
    });
  }

  void _showComparison(
    BuildContext context,
    DuplicatePair pair,
    int i,
    AppProvider provider,
  ) {
    showDialog<CompareAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ComparisonDialog(pair: pair),
    ).then((action) {
      if (!mounted) return;
      if (action == CompareAction.merge) _doMerge(pair, i, provider);
      if (action == CompareAction.dismiss) {
        setState(() {
          _pairs = List.from(_pairs!)..removeAt(i);
        });
      }
    });
  }
}

// ── Duplicate tile ────────────────────────────────────────────────────────────

class _DuplicateTile extends StatelessWidget {
  final DuplicatePair pair;
  final VoidCallback onTap;
  final ValueChanged<DuplicatePair> onMerge;
  final VoidCallback onDismiss;

  const _DuplicateTile({
    required this.pair,
    required this.onTap,
    required this.onMerge,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = (pair.score * 100).round();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _NameChip(
                    name: pair.a.name,
                    book: pair.a.bookName,
                    cs: cs,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: MarkdownTooltip(
                    message: kScoreTooltip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _NameChip(
                    name: pair.b.name,
                    book: pair.b.bookName,
                    cs: cs,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to compare',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Not a duplicate'),
                ),
                const Gap(8),
                MarkdownTooltip(
                  message: kMergeTooltip,
                  child: FilledButton.tonal(
                    onPressed: () => onMerge(pair),
                    child: const Text('Merge'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Name chip ─────────────────────────────────────────────────────────────────

class _NameChip extends StatelessWidget {
  final String name;
  final String book;
  final ColorScheme cs;

  const _NameChip({
    required this.name,
    required this.book,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            Text(
              book,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      );
}
