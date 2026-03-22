/// DuplicateDetector — finds fuzzy-name duplicates across address books.
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

import 'package:rolopod/models/contact.dart';

/// A pair of contacts that are likely duplicates.
class DuplicatePair {
  final Contact a;
  final Contact b;

  /// Similarity score 0.0–1.0.
  final double score;

  const DuplicatePair({
    required this.a,
    required this.b,
    required this.score,
  });
}

/// Find duplicate contacts by fuzzy name matching.
///
/// Returns pairs with similarity score above [threshold] (default 0.8).
List<DuplicatePair> findDuplicates(
  List<Contact> contacts, {
  double threshold = 0.8,
}) {
  final pairs = <DuplicatePair>[];

  for (var i = 0; i < contacts.length; i++) {
    for (var j = i + 1; j < contacts.length; j++) {
      final score = _nameSimilarity(contacts[i].name, contacts[j].name);
      if (score >= threshold) {
        pairs.add(DuplicatePair(a: contacts[i], b: contacts[j], score: score));
      }
    }
  }

  pairs.sort((a, b) => b.score.compareTo(a.score));
  return pairs;
}

/// Merge two contacts into one, preferring non-null values from [primary].
///
/// Lists (emails, phones, etc.) are merged and de-duplicated.
Contact mergeContacts(
  Contact primary,
  Contact secondary, {
  required String bookName,
}) =>
    Contact(
      bookName: bookName,
      firstName: primary.firstName ?? secondary.firstName,
      lastName: primary.lastName ?? secondary.lastName,
      displayName: primary.displayName ?? secondary.displayName,
      nickname: primary.nickname ?? secondary.nickname,
      organisation: primary.organisation ?? secondary.organisation,
      jobTitle: primary.jobTitle ?? secondary.jobTitle,
      emails: _mergeFields(primary.emails, secondary.emails),
      phones: _mergeFields(primary.phones, secondary.phones),
      addresses: _mergeAddresses(primary.addresses, secondary.addresses),
      urls: _mergeFields(primary.urls, secondary.urls),
      notes: _mergeNotes(primary.notes, secondary.notes),
      tags: {...primary.tags, ...secondary.tags}.toList(),
      createdAt: primary.createdAt ?? secondary.createdAt,
      updatedAt: DateTime.now(),
    );

// ── Fuzzy name similarity ─────────────────────────────────────────────────────

double _nameSimilarity(String a, String b) {
  final na = _normaliseName(a);
  final nb = _normaliseName(b);
  if (na == nb) return 1.0;
  if (na.isEmpty || nb.isEmpty) return 0.0;
  return _jaccardSimilarity(na, nb);
}

String _normaliseName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

/// Jaccard similarity on character bigrams.
double _jaccardSimilarity(String a, String b) {
  final bigramsA = _bigrams(a);
  final bigramsB = _bigrams(b);
  if (bigramsA.isEmpty || bigramsB.isEmpty) return 0.0;
  final intersection = bigramsA.intersection(bigramsB).length;
  final union = bigramsA.union(bigramsB).length;
  return union == 0 ? 0.0 : intersection / union;
}

Set<String> _bigrams(String s) {
  final result = <String>{};
  for (var i = 0; i < s.length - 1; i++) {
    result.add(s.substring(i, i + 2));
  }
  return result;
}

// ── Merge helpers ─────────────────────────────────────────────────────────────

List<ContactField> _mergeFields(
  List<ContactField> primary,
  List<ContactField> secondary,
) {
  final seen = <String>{};
  final result = <ContactField>[];
  for (final f in [...primary, ...secondary]) {
    if (seen.add(f.value.toLowerCase())) result.add(f);
  }
  return result;
}

List<ContactAddress> _mergeAddresses(
  List<ContactAddress> primary,
  List<ContactAddress> secondary,
) {
  final seen = <String>{};
  final result = <ContactAddress>[];
  for (final a in [...primary, ...secondary]) {
    if (seen.add(a.summary.toLowerCase())) result.add(a);
  }
  return result;
}

String? _mergeNotes(String? a, String? b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a == b) return a;
  return '$a\n\n$b';
}
