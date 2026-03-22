/// Contact — the core data model for a single address book entry.
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

import 'package:uuid/uuid.dart';

/// A single contact entry across all address book formats.
class Contact {
  /// Unique identifier (UUID).
  final String id;

  /// Which address book this contact belongs to.
  final String bookName;

  // ── Name ──────────────────────────────────────────────────────────────────
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? nickname;

  // ── Organisation ──────────────────────────────────────────────────────────
  final String? organisation;
  final String? jobTitle;

  // ── Contact details ───────────────────────────────────────────────────────
  final List<ContactField> emails;
  final List<ContactField> phones;
  final List<ContactAddress> addresses;
  final List<ContactField> urls;

  // ── Notes and tags ────────────────────────────────────────────────────────
  final String? notes;
  final List<String> tags;

  // ── Timestamps ────────────────────────────────────────────────────────────
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Contact({
    String? id,
    required this.bookName,
    this.firstName,
    this.lastName,
    this.displayName,
    this.nickname,
    this.organisation,
    this.jobTitle,
    this.emails = const [],
    this.phones = const [],
    this.addresses = const [],
    this.urls = const [],
    this.notes,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  /// The best available display name for this contact.
  String get name {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    final parts = [firstName, lastName].whereType<String>().join(' ').trim();
    if (parts.isNotEmpty) return parts;
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    if (organisation != null && organisation!.isNotEmpty) return organisation!;
    if (emails.isNotEmpty) return emails.first.value;
    return '(No name)';
  }

  /// Initials for avatar display (up to 2 characters).
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Primary email address, if any.
  String? get primaryEmail =>
      emails.isEmpty ? null : emails.first.value;

  /// Primary phone number, if any.
  String? get primaryPhone =>
      phones.isEmpty ? null : phones.first.value;

  Contact copyWith({
    String? bookName,
    String? firstName,
    String? lastName,
    String? displayName,
    String? nickname,
    String? organisation,
    String? jobTitle,
    List<ContactField>? emails,
    List<ContactField>? phones,
    List<ContactAddress>? addresses,
    List<ContactField>? urls,
    String? notes,
    List<String>? tags,
    DateTime? updatedAt,
  }) =>
      Contact(
        id: id,
        bookName: bookName ?? this.bookName,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        displayName: displayName ?? this.displayName,
        nickname: nickname ?? this.nickname,
        organisation: organisation ?? this.organisation,
        jobTitle: jobTitle ?? this.jobTitle,
        emails: emails ?? this.emails,
        phones: phones ?? this.phones,
        addresses: addresses ?? this.addresses,
        urls: urls ?? this.urls,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookName': bookName,
        'firstName': firstName,
        'lastName': lastName,
        'displayName': displayName,
        'nickname': nickname,
        'organisation': organisation,
        'jobTitle': jobTitle,
        'emails': emails.map((e) => e.toJson()).toList(),
        'phones': phones.map((p) => p.toJson()).toList(),
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'urls': urls.map((u) => u.toJson()).toList(),
        'notes': notes,
        'tags': tags,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        id: j['id'] as String?,
        bookName: j['bookName'] as String? ?? 'Personal',
        firstName: j['firstName'] as String?,
        lastName: j['lastName'] as String?,
        displayName: j['displayName'] as String?,
        nickname: j['nickname'] as String?,
        organisation: j['organisation'] as String?,
        jobTitle: j['jobTitle'] as String?,
        emails: (j['emails'] as List? ?? [])
            .map((e) => ContactField.fromJson(e as Map<String, dynamic>))
            .toList(),
        phones: (j['phones'] as List? ?? [])
            .map((e) => ContactField.fromJson(e as Map<String, dynamic>))
            .toList(),
        addresses: (j['addresses'] as List? ?? [])
            .map((e) => ContactAddress.fromJson(e as Map<String, dynamic>))
            .toList(),
        urls: (j['urls'] as List? ?? [])
            .map((e) => ContactField.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: j['notes'] as String?,
        tags: List<String>.from(j['tags'] as List? ?? []),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'] as String)
            : null,
      );
}

/// A labelled string field (e.g. "work" email, "mobile" phone).
class ContactField {
  final String label;
  final String value;

  const ContactField({
    required this.label,
    required this.value,
  });

  Map<String, dynamic> toJson() => {'label': label, 'value': value};

  factory ContactField.fromJson(Map<String, dynamic> j) => ContactField(
        label: j['label'] as String? ?? '',
        value: j['value'] as String? ?? '',
      );
}

/// A structured postal address.
class ContactAddress {
  final String label;
  final String? street;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  const ContactAddress({
    required this.label,
    this.street,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  /// Single-line summary for display.
  String get summary {
    return [street, city, state, postcode, country]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'street': street,
        'city': city,
        'state': state,
        'postcode': postcode,
        'country': country,
      };

  factory ContactAddress.fromJson(Map<String, dynamic> j) => ContactAddress(
        label: j['label'] as String? ?? '',
        street: j['street'] as String?,
        city: j['city'] as String?,
        state: j['state'] as String?,
        postcode: j['postcode'] as String?,
        country: j['country'] as String?,
      );
}
