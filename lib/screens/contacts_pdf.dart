/// ContactsPdf — build, preview and save a PDF of contacts.
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:rolopod/models/contact.dart';

/// Build a PDF document listing [contacts], sorted alphabetically by name.
///
/// Uses Noto Sans (loaded from Google Fonts) so that Unicode names and
/// characters render correctly, rather than the bare Helvetica default.
Future<Uint8List> buildContactsPdf(List<Contact> contacts) async {
  final dateStr = DateFormat('d MMMM yyyy').format(DateTime.now());

  final sorted = [...contacts]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final base = await PdfGoogleFonts.notoSansRegular();
  final bold = await PdfGoogleFonts.notoSansBold();
  final italic = await PdfGoogleFonts.notoSansItalic();
  final boldItalic = await PdfGoogleFonts.notoSansBoldItalic();

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: base,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    ),
  );

  doc.addPage(
    pw.MultiPage(
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Contacts',
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '$dateStr  •  ${sorted.length} '
            '${sorted.length == 1 ? 'contact' : 'contacts'}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
        ],
      ),
      build: (_) => [
        for (final c in sorted) ..._contactBlock(c),
      ],
    ),
  );

  return doc.save();
}

/// The PDF widgets for a single contact entry.
List<pw.Widget> _contactBlock(Contact c) {
  final lines = <pw.Widget>[];

  if (c.organisation != null && c.organisation!.isNotEmpty) {
    final role = c.jobTitle != null && c.jobTitle!.isNotEmpty
        ? '${c.jobTitle}, ${c.organisation}'
        : c.organisation!;
    lines.add(_detail(role));
  }
  for (final e in c.emails) {
    lines.add(_detail('${e.label}: ${e.value}'));
  }
  for (final p in c.phones) {
    lines.add(_detail('${p.label}: ${p.value}'));
  }
  for (final a in c.addresses) {
    if (a.summary.isNotEmpty) lines.add(_detail('${a.label}: ${a.summary}'));
  }
  for (final u in c.urls) {
    lines.add(_detail(u.value));
  }
  if (c.notes != null && c.notes!.isNotEmpty) {
    lines.addAll(_markdownToPdf(c.notes!));
  }
  if (c.tags.isNotEmpty) {
    lines.add(_detail('tags: ${c.tags.join(', ')}'));
  }

  return [
    pw.Text(
      c.name,
      style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 2),
    ...lines,
    pw.SizedBox(height: 8),
    pw.Divider(thickness: 1, color: PdfColors.grey400),
    pw.SizedBox(height: 8),
  ];
}

pw.Widget _detail(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );

// ── Markdown → PDF ──────────────────────────────────────────────────────────

/// Render a (best-effort) subset of Markdown to PDF widgets: headings,
/// unordered bullet lists, blank-line paragraph breaks, and inline emphasis
/// (`**bold**`, `*italic*` / `_italic_`).
List<pw.Widget> _markdownToPdf(String md) {
  final widgets = <pw.Widget>[];
  for (final raw in md.split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      continue;
    }

    // Headings: #, ##, ### …
    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line.trimLeft());
    if (heading != null) {
      final level = heading.group(1)!.length;
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
          child: pw.RichText(
            text: pw.TextSpan(
              children: _inlineSpans(
                heading.group(2)!,
                base: pw.TextStyle(
                  fontSize: (15 - level).clamp(10, 14).toDouble(),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
      continue;
    }

    // Unordered list items: -, * or +.
    final bullet = RegExp(r'^\s*[-*+]\s+(.*)$').firstMatch(line);
    if (bullet != null) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                const pw.TextSpan(text: '• '),
                ..._inlineSpans(bullet.group(1)!),
              ],
            ),
          ),
        ),
      );
      continue;
    }

    // Plain paragraph line.
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(children: _inlineSpans(line)),
        ),
      ),
    );
  }
  return widgets;
}

/// Convert inline Markdown emphasis in [text] into styled [pw.TextSpan]s.
List<pw.TextSpan> _inlineSpans(String text, {pw.TextStyle? base}) {
  final baseStyle = base ?? const pw.TextStyle(fontSize: 10);
  final spans = <pw.TextSpan>[];
  // Matches **bold**, *italic* or _italic_.
  final re = RegExp(r'(\*\*(.+?)\*\*)|(\*(.+?)\*)|(_(.+?)_)');
  var index = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > index) {
      spans.add(
        pw.TextSpan(text: text.substring(index, m.start), style: baseStyle),
      );
    }
    if (m.group(2) != null) {
      spans.add(
        pw.TextSpan(
          text: m.group(2),
          style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
        ),
      );
    } else if (m.group(4) != null) {
      spans.add(
        pw.TextSpan(
          text: m.group(4),
          style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic),
        ),
      );
    } else if (m.group(6) != null) {
      spans.add(
        pw.TextSpan(
          text: m.group(6),
          style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic),
        ),
      );
    }
    index = m.end;
  }
  if (index < text.length) {
    spans.add(pw.TextSpan(text: text.substring(index), style: baseStyle));
  }
  return spans;
}

/// Prompt for a filename/location and write the PDF [bytes] there.
///
/// Returns the saved path on success, null if cancelled, or an 'error:'
/// prefixed message on failure. On web, falls back to the share sheet.
Future<String?> saveContactsPdf(List<int> bytes, String defaultName) async {
  try {
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: defaultName,
      );
      return null;
    }
    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Save PDF',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: Uint8List.fromList(bytes),
    );
    if (savedUri == null) return null;

    return savedUri.scheme == 'file'
        ? savedUri.toFilePath()
        : savedUri.toString();
  } catch (e, st) {
    debugPrint('[Contacts PDF] save error: $e\n$st');
    return 'error:Save failed: $e';
  }
}

/// Open a full-screen in-app preview of the contacts PDF, with a Save action
/// in place of the default share button.
void showContactsPdfPreview(
  BuildContext context,
  List<Contact> contacts,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Contacts PDF')),
        body: PdfPreview(
          build: (_) => buildContactsPdf(contacts),
          pdfFileName: 'rolopod_contacts.pdf',
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowSharing: false,
          actions: [
            PdfPreviewAction(
              icon: const Icon(Icons.save_alt),
              onPressed: (ctx, build, pageFormat) async {
                final bytes = await build(pageFormat);
                final msg = await saveContactsPdf(
                  bytes,
                  'rolopod_contacts.pdf',
                );
                if (!ctx.mounted || msg == null) return;
                final text = msg.startsWith('error:')
                    ? msg.substring(6)
                    : 'Saved to $msg';
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(text)),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
