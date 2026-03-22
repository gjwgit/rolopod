/// AddressBook — metadata for a named address book stored on a Solid Pod.
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

/// Metadata describing a single address book.
class AddressBook {
  /// Display name (e.g. "Personal", "Work").
  final String name;

  /// Path on the Solid Pod (relative to pod root).
  final String podPath;

  /// WebID of the pod owner.
  final String ownerWebId;

  /// WebIDs this book is shared with (outgoing shares).
  final List<String> sharedWith;

  /// Whether this book was shared with the current user by someone else.
  final bool isSharedWithMe;

  /// Whether to include this book in the combined view.
  bool isVisible;

  AddressBook({
    required this.name,
    required this.podPath,
    required this.ownerWebId,
    this.sharedWith = const [],
    this.isSharedWithMe = false,
    this.isVisible = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'podPath': podPath,
        'ownerWebId': ownerWebId,
        'sharedWith': sharedWith,
        'isSharedWithMe': isSharedWithMe,
        'isVisible': isVisible,
      };

  factory AddressBook.fromJson(Map<String, dynamic> j) => AddressBook(
        name: j['name'] as String,
        podPath: j['podPath'] as String,
        ownerWebId: j['ownerWebId'] as String? ?? '',
        sharedWith: List<String>.from(j['sharedWith'] as List? ?? []),
        isSharedWithMe: j['isSharedWithMe'] as bool? ?? false,
        isVisible: j['isVisible'] as bool? ?? true,
      );
}
