/// ContactEdit — full edit form for all contact fields.
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
  // ── Scalar fields ──────────────────────────────────────────────────────────
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _displayName;
  late final TextEditingController _nickname;
  late final TextEditingController _organisation;
  late final TextEditingController _jobTitle;
  late final TextEditingController _notes;
  DateTime? _birthday;
  late TextEditingController _gender;
  late TextEditingController _spouse;
  late List<TextEditingController> _children;

  // ── Dynamic list fields ────────────────────────────────────────────────────
  late List<_LabeledField> _emails;
  late List<_LabeledField> _phones;
  late List<_LabeledField> _urls;
  late List<_AddressField> _addresses;
  late List<TextEditingController> _tags;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _firstName = TextEditingController(text: c.firstName ?? '');
    _lastName = TextEditingController(text: c.lastName ?? '');
    _displayName = TextEditingController(text: c.displayName ?? '');
    _nickname = TextEditingController(text: c.nickname ?? '');
    _organisation = TextEditingController(text: c.organisation ?? '');
    _jobTitle = TextEditingController(text: c.jobTitle ?? '');
    _notes = TextEditingController(text: c.notes ?? '');
    _birthday = c.birthday;
    _gender = TextEditingController(text: c.gender ?? '');
    _spouse = TextEditingController(text: c.spouseName ?? '');
    _children =
        c.children.map((ch) => TextEditingController(text: ch)).toList();

    _emails = c.emails.map(_LabeledField.from).toList();
    if (_emails.isEmpty) _emails.add(_LabeledField.empty('email'));

    _phones = c.phones.map(_LabeledField.from).toList();
    if (_phones.isEmpty) _phones.add(_LabeledField.empty('mobile'));

    _urls = c.urls.map(_LabeledField.from).toList();

    _addresses = c.addresses.map(_AddressField.from).toList();

    _tags = c.tags.map((t) => TextEditingController(text: t)).toList();
  }

  @override
  void dispose() {
    for (final ctrl in [
      _firstName,
      _lastName,
      _displayName,
      _nickname,
      _organisation,
      _jobTitle,
      _notes,
      _gender,
      _spouse,
    ]) {
      ctrl.dispose();
    }
    for (final ch in _children) {
      ch.dispose();
    }
    for (final f in _emails) {
      f.dispose();
    }
    for (final f in _phones) {
      f.dispose();
    }
    for (final f in _urls) {
      f.dispose();
    }
    for (final f in _addresses) {
      f.dispose();
    }
    for (final t in _tags) {
      t.dispose();
    }
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  void _save(BuildContext context) {
    String? clean(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    final updated = widget.contact.copyWith(
      firstName: clean(_firstName),
      lastName: clean(_lastName),
      displayName: clean(_displayName),
      nickname: clean(_nickname),
      organisation: clean(_organisation),
      jobTitle: clean(_jobTitle),
      notes: clean(_notes),
      birthday: _birthday,
      gender: clean(_gender),
      spouseName: clean(_spouse),
      children: _children
          .map((c) => c.text.trim())
          .where((c) => c.isNotEmpty)
          .toList(),
      emails: _emails.toFields(),
      phones: _phones.toFields(),
      urls: _urls.toFields(),
      addresses: _addresses.toAddresses(),
      tags: _tags.map((t) => t.text.trim()).where((t) => t.isNotEmpty).toList(),
      updatedAt: DateTime.now(),
    );
    final provider = context.read<AppProvider>();
    provider.upsertContact(updated);
    // Persist to pod in background — don't block the UI.
    provider.saveBookToPod(updated.bookName);
    Navigator.of(context).pop();
  }

  // ── Birthday picker ────────────────────────────────────────────────────────

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select birthday',
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 60 : 12,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
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

            // ── Scrollable form ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(context, 'Name'),
                    const Gap(8),
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
                    const Gap(8),
                    _Field(
                      controller: _displayName,
                      label: 'Display name',
                    ),
                    const Gap(8),
                    _Field(controller: _nickname, label: 'Nickname'),
                    const Gap(16),
                    _sectionLabel(context, 'Organisation'),
                    const Gap(8),
                    _Field(
                      controller: _organisation,
                      label: 'Organisation',
                    ),
                    const Gap(8),
                    _Field(controller: _jobTitle, label: 'Job title'),
                    const Gap(16),
                    _sectionLabel(context, 'Email'),
                    const Gap(8),
                    _buildLabeledList(
                      context,
                      fields: _emails,
                      valuePlaceholder: 'Email address',
                      keyboard: TextInputType.emailAddress,
                      defaultLabel: 'email',
                      labelOptions: ['email', 'work', 'home', 'other'],
                      onAdd: () => setState(
                        () => _emails.add(_LabeledField.empty('email')),
                      ),
                      onRemove: (i) => setState(() {
                        _emails[i].dispose();
                        _emails.removeAt(i);
                      }),
                    ),
                    const Gap(16),
                    _sectionLabel(context, 'Phone'),
                    const Gap(8),
                    _buildLabeledList(
                      context,
                      fields: _phones,
                      valuePlaceholder: 'Phone number',
                      keyboard: TextInputType.phone,
                      defaultLabel: 'mobile',
                      labelOptions: ['mobile', 'home', 'work', 'other'],
                      onAdd: () => setState(
                        () => _phones.add(_LabeledField.empty('mobile')),
                      ),
                      onRemove: (i) => setState(() {
                        _phones[i].dispose();
                        _phones.removeAt(i);
                      }),
                    ),
                    const Gap(16),
                    _sectionLabel(context, 'Address'),
                    const Gap(8),
                    ..._addresses.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AddressEditor(
                              field: e.value,
                              onRemove: () => setState(() {
                                _addresses[e.key].dispose();
                                _addresses.removeAt(e.key);
                              }),
                            ),
                          ),
                        ),
                    _AddButton(
                      label: 'Add address',
                      onPressed: () =>
                          setState(() => _addresses.add(_AddressField.empty())),
                    ),
                    const Gap(16),
                    _sectionLabel(context, 'Web'),
                    const Gap(8),
                    _buildLabeledList(
                      context,
                      fields: _urls,
                      valuePlaceholder: 'URL',
                      keyboard: TextInputType.url,
                      defaultLabel: 'url',
                      labelOptions: ['url', 'work', 'home', 'other'],
                      onAdd: () =>
                          setState(() => _urls.add(_LabeledField.empty('url'))),
                      onRemove: (i) => setState(() {
                        _urls[i].dispose();
                        _urls.removeAt(i);
                      }),
                    ),
                    const Gap(16),
                    _sectionLabel(context, 'Birthday'),
                    const Gap(8),
                    InkWell(
                      onTap: _pickBirthday,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          _birthday != null
                              ? '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: _birthday != null
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (_birthday != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => _birthday = null),
                          child: const Text('Clear'),
                        ),
                      ),
                    const Gap(16),
                    _sectionLabel(context, 'Personal'),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      initialValue: [
                        '',
                        'Male',
                        'Female',
                        'Non-binary',
                        'Other',
                      ].contains(_gender.text)
                          ? _gender.text
                          : '',
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('—')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'Non-binary',
                          child: Text('Non-binary'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _gender.text = v ?? ''),
                    ),
                    const Gap(12),
                    _Field(
                      controller: _spouse,
                      label: 'Spouse / partner name',
                    ),
                    const Gap(16),
                    _sectionLabel(context, 'Children'),
                    const Gap(8),
                    ..._children.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    controller: e.value,
                                    label: 'Child name',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: cs.error,
                                  onPressed: () => setState(() {
                                    _children[e.key].dispose();
                                    _children.removeAt(e.key);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                    _AddButton(
                      label: 'Add child',
                      onPressed: () => setState(
                        () => _children.add(TextEditingController()),
                      ),
                    ),
                    const Gap(16),
                    _sectionLabel(context, 'Tags'),
                    const Gap(8),
                    ..._tags.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    controller: e.value,
                                    label: 'Tag',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: cs.error,
                                  onPressed: () => setState(() {
                                    _tags[e.key].dispose();
                                    _tags.removeAt(e.key);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                    _AddButton(
                      label: 'Add tag',
                      onPressed: () => setState(
                        () => _tags.add(TextEditingController()),
                      ),
                    ),
                    const Gap(16),
                    _sectionLabel(context, 'Notes'),
                    const Gap(8),
                    TextField(
                      controller: _notes,
                      maxLines: null,
                      minLines: 4,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'Notes (markdown supported)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: '**bold**, *italic*, - bullet lists…',
                      ),
                    ),
                    const Gap(8),
                  ],
                ),
              ),
            ),

            // ── Actions ────────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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

  // ── Labeled list builder (emails / phones / urls) ──────────────────────────

  Widget _buildLabeledList(
    BuildContext context, {
    required List<_LabeledField> fields,
    required String valuePlaceholder,
    required TextInputType keyboard,
    required String defaultLabel,
    required List<String> labelOptions,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemove,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        ...fields.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label dropdown
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        initialValue: labelOptions.contains(e.value.label.text)
                            ? e.value.label.text
                            : labelOptions.first,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                        ),
                        items: labelOptions
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(
                                  l,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => e.value.label.text = v);
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    // Value field
                    Expanded(
                      child: TextField(
                        controller: e.value.value,
                        keyboardType: keyboard,
                        decoration: InputDecoration(
                          hintText: valuePlaceholder,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    // Remove button
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: cs.error,
                      onPressed: () => onRemove(e.key),
                    ),
                  ],
                ),
              ),
            ),
        _AddButton(label: 'Add', onPressed: onAdd),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

Widget _sectionLabel(BuildContext context, String text) => Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );

// ── Add button ────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 13)),
          onPressed: onPressed,
        ),
      );
}

// ── Simple text field ─────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _Field({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
}

// ── Labeled field pair (label + value controllers) ────────────────────────────

class _LabeledField {
  final TextEditingController label;
  final TextEditingController value;

  _LabeledField({required String label, required String value})
      : label = TextEditingController(text: label),
        value = TextEditingController(text: value);

  factory _LabeledField.from(ContactField f) =>
      _LabeledField(label: f.label, value: f.value);

  factory _LabeledField.empty(String defaultLabel) =>
      _LabeledField(label: defaultLabel, value: '');

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

extension on List<_LabeledField> {
  List<ContactField> toFields() => where((f) => f.value.text.trim().isNotEmpty)
      .map(
        (f) => ContactField(
          label: f.label.text.trim().isEmpty ? 'other' : f.label.text.trim(),
          value: f.value.text.trim(),
        ),
      )
      .toList();
}

// ── Address field group ───────────────────────────────────────────────────────

class _AddressField {
  final TextEditingController label;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController postcode;
  final TextEditingController country;

  _AddressField({
    required String label,
    required String street,
    required String city,
    required String state,
    required String postcode,
    required String country,
  })  : label = TextEditingController(text: label),
        street = TextEditingController(text: street),
        city = TextEditingController(text: city),
        state = TextEditingController(text: state),
        postcode = TextEditingController(text: postcode),
        country = TextEditingController(text: country);

  factory _AddressField.from(ContactAddress a) => _AddressField(
        label: a.label,
        street: a.street ?? '',
        city: a.city ?? '',
        state: a.state ?? '',
        postcode: a.postcode ?? '',
        country: a.country ?? '',
      );

  factory _AddressField.empty() => _AddressField(
        label: 'home',
        street: '',
        city: '',
        state: '',
        postcode: '',
        country: '',
      );

  void dispose() {
    for (final c in [label, street, city, state, postcode, country]) {
      c.dispose();
    }
  }
}

extension on List<_AddressField> {
  List<ContactAddress> toAddresses() {
    return where(
      (a) =>
          a.street.text.trim().isNotEmpty ||
          a.city.text.trim().isNotEmpty ||
          a.postcode.text.trim().isNotEmpty,
    )
        .map(
          (a) => ContactAddress(
            label: a.label.text.trim().isEmpty ? 'home' : a.label.text.trim(),
            street: a.street.text.trim().isEmpty ? null : a.street.text.trim(),
            city: a.city.text.trim().isEmpty ? null : a.city.text.trim(),
            state: a.state.text.trim().isEmpty ? null : a.state.text.trim(),
            postcode:
                a.postcode.text.trim().isEmpty ? null : a.postcode.text.trim(),
            country:
                a.country.text.trim().isEmpty ? null : a.country.text.trim(),
          ),
        )
        .toList();
  }
}

// ── Address editor widget ─────────────────────────────────────────────────────

class _AddressEditor extends StatelessWidget {
  final _AddressField field;
  final VoidCallback onRemove;

  const _AddressEditor({required this.field, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue:
                      ['home', 'work', 'other'].contains(field.label.text)
                          ? field.label.text
                          : 'home',
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['home', 'work', 'other']
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(l),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) field.label.text = v;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: cs.error,
                onPressed: onRemove,
              ),
            ],
          ),
          const Gap(8),
          TextField(
            controller: field.street,
            decoration: const InputDecoration(
              labelText: 'Street',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: field.city,
                  decoration: const InputDecoration(
                    labelText: 'City / Suburb',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const Gap(8),
              Expanded(
                child: TextField(
                  controller: field.state,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: field.postcode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Postcode',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const Gap(8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: field.country,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
