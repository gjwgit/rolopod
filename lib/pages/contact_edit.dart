/// ContactEdit — form to create or edit a contact.
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
import 'package:rolopod/services/app_provider.dart';

class ContactEdit extends StatefulWidget {
  final Contact contact;
  final bool isNew;

  const ContactEdit({
    super.key,
    required this.contact,
    this.isNew = false,
  });

  @override
  State<ContactEdit> createState() => _ContactEditState();
}

class _ContactEditState extends State<ContactEdit> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _organisation;
  late final TextEditingController _jobTitle;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _firstName = TextEditingController(text: c.firstName ?? '');
    _lastName = TextEditingController(text: c.lastName ?? '');
    _organisation = TextEditingController(text: c.organisation ?? '');
    _jobTitle = TextEditingController(text: c.jobTitle ?? '');
    _email = TextEditingController(text: c.primaryEmail ?? '');
    _phone = TextEditingController(text: c.primaryPhone ?? '');
    _notes = TextEditingController(text: c.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _organisation, _jobTitle,
      _email, _phone, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(BuildContext context) {
    final updated = widget.contact.copyWith(
      firstName: _firstName.text.trim().isEmpty ? null : _firstName.text.trim(),
      lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
      organisation: _organisation.text.trim().isEmpty
          ? null
          : _organisation.text.trim(),
      jobTitle: _jobTitle.text.trim().isEmpty ? null : _jobTitle.text.trim(),
      emails: _email.text.trim().isEmpty
          ? widget.contact.emails
          : [ContactField(label: 'email', value: _email.text.trim())],
      phones: _phone.text.trim().isEmpty
          ? widget.contact.phones
          : [ContactField(label: 'phone', value: _phone.text.trim())],
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      updatedAt: DateTime.now(),
    );
    context.read<AppProvider>().upsertContact(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Text(
                    widget.isNew ? 'New Contact' : 'Edit Contact',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Form ───────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _firstName,
                            label: 'First name',
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _Field(
                            controller: _lastName,
                            label: 'Last name',
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    _Field(controller: _organisation, label: 'Organisation'),
                    const Gap(12),
                    _Field(controller: _jobTitle, label: 'Job title'),
                    const Gap(12),
                    _Field(
                      controller: _email,
                      label: 'Email',
                      keyboard: TextInputType.emailAddress,
                    ),
                    const Gap(12),
                    _Field(
                      controller: _phone,
                      label: 'Phone',
                      keyboard: TextInputType.phone,
                    ),
                    const Gap(12),
                    _Field(
                      controller: _notes,
                      label: 'Notes',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // ── Actions ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Gap(8),
                  FilledButton(
                    onPressed: () => _save(context),
                    child: const Text('Save'),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}
