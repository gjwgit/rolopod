/// ImportExportIo — pure serialisation and file-save helpers for the
/// RoloPod import/export screen, extracted to keep that screen within the
/// project line-count limit.
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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:file_picker/file_picker.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/models/contact_parser.dart';

/// The format an address book can be exported to.
enum ExportFormat { json, bbdb, vcard }

/// A `rolopod_<book>_YYYYMMDD_HHMM.<ext>` filename for the current time.
String timestampedName(String bookName, String ext) {
  final now = DateTime.now();
  final ts =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
      '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  return 'rolopod_${bookName}_$ts.$ext';
}

/// Serialise [bookName] to the requested [format], returning the file bytes
/// and the default filename extension.
({List<int> bytes, String ext}) exportBytes(
  String serialisedBookJson,
  ExportFormat format,
) {
  switch (format) {
    case ExportFormat.json:
      final json = const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(serialisedBookJson));
      return (bytes: utf8.encode(json), ext: 'json');
    case ExportFormat.bbdb:
    case ExportFormat.vcard:
      final decoded = jsonDecode(serialisedBookJson) as List;
      final contacts = decoded
          .map((j) => Contact.fromJson(j as Map<String, dynamic>))
          .toList();
      final content =
          format == ExportFormat.bbdb ? toBbdb(contacts) : toVcard(contacts);
      return (
        bytes: utf8.encode(content),
        ext: format == ExportFormat.bbdb ? 'bbdb' : 'vcf',
      );
  }
}

/// Prompt for a location and write [bytes] there.
///
/// Returns the saved path on success, null if cancelled, or an 'error:'
/// prefixed message on failure. On web the browser handles the write.
Future<String?> savePickedBytes({
  required List<int> bytes,
  required String fileName,
  required String ext,
  required String dialogTitle,
}) async {
  try {
    final savedUri = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [ext],
      bytes: Uint8List.fromList(bytes),
    );
    if (savedUri == null) return null;

    return savedUri.scheme == 'file'
        ? savedUri.toFilePath()
        : savedUri.toString();
  } catch (e, st) {
    debugPrint('[Export] save error: $e\n$st');
    return 'error:Export failed: $e';
  }
}
