/// DetailWidgets — shared helper widgets for the ContactDetail card.
///
// Time-stamp: <Monday 2026-03-23 20:29:36 +1100 Graham Williams>
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
import 'package:rolopod/pages/contact_detail.dart';
import 'package:rolopod/services/app_provider.dart';

// ── Contact field section ─────────────────────────────────────────────────────

class DetailSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<ContactField> fields;

  /// Optional callback invoked when a field value is tapped.
  /// Receives the field value string (e.g. a phone number or URL).

  final void Function(String value)? onFieldTap;

  const DetailSection({
    super.key,
    required this.icon,
    required this.label,
    required this.fields,
    this.onFieldTap,
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
                  child: InkWell(
                    onTap:
                        onFieldTap != null ? () => onFieldTap!(f.value) : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: onFieldTap != null
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              decoration: onFieldTap != null
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Address section ───────────────────────────────────────────────────────────

class DetailAddressSection extends StatelessWidget {
  final List<ContactAddress> addresses;

  const DetailAddressSection({
    super.key,
    required this.addresses,
  });

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
                  child: Text(
                    a.summary,
                    style: const TextStyle(fontSize: 13),
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

// ── Simple info row ───────────────────────────────────────────────────────────

class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const Gap(12),
          Column(
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
              Text(value, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      );
}

// ── Spouse row — tappable if a matching contact exists ────────────────────────

class DetailSpouseRow extends StatelessWidget {
  final String spouseName;
  final ColorScheme cs;

  const DetailSpouseRow({
    super.key,
    required this.spouseName,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final spouse = provider.findContactByName(spouseName);

    return Row(
      children: [
        Icon(Icons.favorite_outline, size: 18, color: cs.onSurfaceVariant),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spouse',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            spouse != null
                ? InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => ContactDetail(contact: spouse),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            spouseName,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: cs.primary,
                            ),
                          ),
                          const Gap(4),
                          Icon(
                            Icons.open_in_new,
                            size: 12,
                            color: cs.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    spouseName,
                    style: const TextStyle(fontSize: 13),
                  ),
          ],
        ),
      ],
    );
  }
}
