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

import 'package:emacs_text_field/emacs_text_field.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/pages/edit_field_widgets.dart';
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

class _ContactEditState extends State<ContactEdit> with UnsavedChangesMixin {
  // ── Scalar fields ──────────────────────────────────────────────────────────
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _displayName;
  late final TextEditingController _nickname;
  late final TextEditingController _organisation;
  late final TextEditingController _jobTitle;
  late final TextEditingController _notes;
  DateTime? _birthday;
  DateTime? _updatedAt;
  bool _updatedAtEdited = false;
  late TextEditingController _gender;
  late TextEditingController _spouse;
  late List<TextEditingController> _children;

  // ── Dynamic list fields ────────────────────────────────────────────────────
  late List<LabeledField> _emails;
  late List<LabeledField> _phones;
  late List<LabeledField> _urls;
  late List<AddressField> _addresses;
  late List<TextEditingController> _tags;
  late List<FocusNode> _childFocusNodes;
  bool _focusNewTag = false;

  /// Whether any field has been edited since the editor opened. Drives the
  /// enabled state of the Save button.
  bool _dirty = false;

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
    _updatedAt = c.updatedAt;
    _gender = TextEditingController(text: c.gender ?? '');
    _spouse = TextEditingController(text: c.spouseName ?? '');
    _children =
        c.children.map((ch) => TextEditingController(text: ch)).toList();

    _emails = c.emails.map(LabeledField.from).toList();
    if (_emails.isEmpty) _emails.add(LabeledField.empty('email'));

    _phones = c.phones.map(LabeledField.from).toList();
    if (_phones.isEmpty) _phones.add(LabeledField.empty('mobile'));

    _urls = c.urls.map(LabeledField.from).toList();

    _addresses = c.addresses.map(AddressField.from).toList();

    _tags = c.tags.map((t) => TextEditingController(text: t)).toList();
    _childFocusNodes = List.generate(_children.length, (_) => FocusNode());

    // Wire change detection: any edit to a text field marks the form dirty so
    // the Save button enables. Non-text changes (dates, adding/removing list
    // items) call _markDirty() directly from their handlers.
    for (final ctrl in _allTextControllers) {
      ctrl.addListener(_markDirty);
    }
  }

  /// Every text controller currently in the form, including those inside the
  /// dynamic email/phone/url/address/tag/children lists.
  Iterable<TextEditingController> get _allTextControllers => [
        _firstName,
        _lastName,
        _displayName,
        _nickname,
        _organisation,
        _jobTitle,
        _notes,
        _gender,
        _spouse,
        ..._children,
        ..._tags,
        for (final f in _emails) ...[f.label, f.value],
        for (final f in _phones) ...[f.label, f.value],
        for (final f in _urls) ...[f.label, f.value],
        for (final f in _addresses) ...[
          f.label,
          f.street,
          f.city,
          f.state,
          f.postcode,
          f.country,
        ],
      ];

  /// Mark the form as having unsaved changes (enables the Save button).
  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  /// Attach change detection to a newly added labelled field and mark dirty.
  void _attachLabeled(LabeledField f) {
    f.label.addListener(_markDirty);
    f.value.addListener(_markDirty);
    _markDirty();
  }

  /// Attach change detection to a newly added address field and mark dirty.
  void _attachAddress(AddressField f) {
    for (final c in [
      f.label,
      f.street,
      f.city,
      f.state,
      f.postcode,
      f.country,
    ]) {
      c.addListener(_markDirty);
    }
    _markDirty();
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
    for (final n in _childFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Write the edited contact to the provider and the Pod.
  ///
  /// Does NOT pop the editor: a window close waits on this and must not
  /// disturb the navigator. Returns once the Pod write has completed — the
  /// window is destroyed the moment the close guard resolves, so a
  /// fire-and-forget write would be killed mid-flight and the edit lost.

  Future<void> _persist(BuildContext context) async {
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
      updatedAt: _updatedAtEdited ? _updatedAt : DateTime.now(),
    );
    final provider = context.read<AppProvider>();
    await provider.upsertContact(updated);
    // Persist to the pod, awaited so a window close cannot cut the write off.
    final error = await provider.saveBookToPod(updated.bookName);
    if (error != null) {
      // Leave _dirty set: nothing reached the Pod, so the close prompt must
      // still fire rather than letting the contact be lost silently.
      SolidWriteFailures.reportIfFailed(error, during: 'saving the contact');

      return;
    }
    // Everything is written, so there is nothing unsaved left to prompt about.
    if (mounted) setState(() => _dirty = false);
  }

  /// Save and close the editor.

  Future<void> _save(BuildContext context) async {
    await _persist(context);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  // The window-close prompt comes from UnsavedChangesMixin, which needs to
  // know what counts as unsaved and how to save without popping the route.

  @override
  bool get hasUnsavedChanges => _dirty;

  @override
  Future<void> saveUnsavedChanges() => _persist(context);

  /// Close the editor, but if there are unsaved changes first ask the user
  /// whether to save, discard, or keep editing.

  Future<void> _confirmDiscard() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final action = await showUnsavedChangesDialog(context);
    if (!mounted) return;
    switch (action) {
      case UnsavedChangesAction.save:
        await _save(context);
      case UnsavedChangesAction.discard:
        Navigator.of(context).pop();
      case UnsavedChangesAction.keepEditing:
        break;
    }
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
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _dirty = true;
      });
    }
  }

  // ── Updated-at picker (date + time) ───────────────────────────────────────

  String _formatTimestamp(DateTime dt) {
    final d = '${dt.day}/${dt.month}/${dt.year}';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    return '$d $h:$m';
  }

  Future<void> _pickUpdatedAt() async {
    final now = DateTime.now();
    final current = _updatedAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Select date',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Select time',
    );
    if (time == null) return;

    setState(() {
      _updatedAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _updatedAtEdited = true;
      _dirty = true;
    });
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
                    onPressed: _confirmDiscard,
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
                    editSectionLabel(context, 'Name'),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: EditField(
                            controller: _firstName,
                            label: 'First name',
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: EditField(
                            controller: _lastName,
                            label: 'Last name',
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    EditField(
                      controller: _displayName,
                      label: 'Display name',
                    ),
                    const Gap(8),
                    EditField(controller: _nickname, label: 'Nickname'),
                    const Gap(16),
                    editSectionLabel(context, 'Organisation'),
                    const Gap(8),
                    EditField(
                      controller: _organisation,
                      label: 'Organisation',
                    ),
                    const Gap(8),
                    EditField(controller: _jobTitle, label: 'Job title'),
                    const Gap(16),
                    editSectionLabel(context, 'Email'),
                    const Gap(8),
                    _buildLabeledList(
                      context,
                      fields: _emails,
                      valuePlaceholder: 'Email address',
                      keyboard: TextInputType.emailAddress,
                      defaultLabel: 'email',
                      labelOptions: ['email', 'work', 'home', 'other'],
                      onAdd: () {
                        final field = LabeledField.empty('email');
                        setState(() => _emails.add(field));
                        _attachLabeled(field);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => field.valueFocus.requestFocus(),
                        );
                      },
                      onRemove: (i) => setState(() {
                        _emails[i].dispose();
                        _emails.removeAt(i);
                        _dirty = true;
                      }),
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Phone'),
                    const Gap(8),
                    _buildLabeledList(
                      context,
                      fields: _phones,
                      valuePlaceholder: 'Phone number',
                      keyboard: TextInputType.phone,
                      defaultLabel: 'mobile',
                      labelOptions: ['mobile', 'home', 'work', 'other'],
                      onAdd: () {
                        final field = LabeledField.empty('mobile');
                        setState(() => _phones.add(field));
                        _attachLabeled(field);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => field.valueFocus.requestFocus(),
                        );
                      },
                      onRemove: (i) => setState(() {
                        _phones[i].dispose();
                        _phones.removeAt(i);
                        _dirty = true;
                      }),
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Address'),
                    const Gap(8),
                    ..._addresses.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AddressEditor(
                              field: e.value,
                              onRemove: () => setState(() {
                                _addresses[e.key].dispose();
                                _addresses.removeAt(e.key);
                                _dirty = true;
                              }),
                            ),
                          ),
                        ),
                    EditAddButton(
                      label: 'Add address',
                      onPressed: () {
                        final field = AddressField.empty();
                        setState(() => _addresses.add(field));
                        _attachAddress(field);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => field.streetFocus.requestFocus(),
                        );
                      },
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Web'),
                    const Gap(8),
                    _buildLabeledList(
                      context,
                      fields: _urls,
                      valuePlaceholder: 'URL',
                      keyboard: TextInputType.url,
                      defaultLabel: 'url',
                      labelOptions: ['url', 'work', 'home', 'other'],
                      onAdd: () {
                        final field = LabeledField.empty('url');
                        setState(() => _urls.add(field));
                        _attachLabeled(field);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => field.valueFocus.requestFocus(),
                        );
                      },
                      onRemove: (i) => setState(() {
                        _urls[i].dispose();
                        _urls.removeAt(i);
                        _dirty = true;
                      }),
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Birthday'),
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
                    editSectionLabel(context, 'Personal'),
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
                      onChanged: (v) => setState(() {
                        _gender.text = v ?? '';
                        _dirty = true;
                      }),
                    ),
                    const Gap(12),
                    EditField(
                      controller: _spouse,
                      label: 'Spouse / partner name',
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Children'),
                    const Gap(8),
                    ..._children.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: EditField(
                                    controller: e.value,
                                    focusNode: _childFocusNodes[e.key],
                                    label: 'Child name',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: cs.error,
                                  onPressed: () => setState(() {
                                    _children[e.key].dispose();
                                    _children.removeAt(e.key);
                                    _childFocusNodes[e.key].dispose();
                                    _childFocusNodes.removeAt(e.key);
                                    _dirty = true;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                    EditAddButton(
                      label: 'Add child',
                      onPressed: () {
                        final node = FocusNode();
                        final ctrl = TextEditingController();
                        ctrl.addListener(_markDirty);
                        setState(() {
                          _children.add(ctrl);
                          _childFocusNodes.add(node);
                          _dirty = true;
                        });
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => node.requestFocus(),
                        );
                      },
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Tags'),
                    const Gap(8),
                    ..._tags.asMap().entries.map(
                      (e) {
                        final isNewLast =
                            _focusNewTag && e.key == _tags.length - 1;
                        if (isNewLast) {
                          _focusNewTag = false;
                        }

                        return Padding(
                          key: ObjectKey(e.value),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: LabelAutocomplete(
                                  controller: e.value,
                                  options: context.read<AppProvider>().allTags,
                                  autofocus: isNewLast,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: cs.error,
                                onPressed: () => setState(() {
                                  _tags[e.key].dispose();
                                  _tags.removeAt(e.key);
                                  _dirty = true;
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    EditAddButton(
                      label: 'Add tag',
                      onPressed: () {
                        final ctrl = TextEditingController();
                        ctrl.addListener(_markDirty);
                        setState(() {
                          _tags.add(ctrl);
                          _focusNewTag = true;
                          _dirty = true;
                        });
                      },
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Notes'),
                    const Gap(8),
                    EmacsTextField(
                      controller: _notes,
                      minLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes (markdown supported)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: '**bold**, *italic*, - bullet lists…',
                      ),
                    ),
                    const Gap(16),
                    editSectionLabel(context, 'Last Updated'),
                    const Gap(8),
                    InkWell(
                      onTap: _pickUpdatedAt,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.edit_calendar, size: 18),
                        ),
                        child: Text(
                          _updatedAt != null
                              ? _formatTimestamp(_updatedAt!)
                              : 'Set on save',
                          style: TextStyle(
                            color: _updatedAt != null
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (_updatedAtEdited)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _updatedAt = widget.contact.updatedAt;
                            _updatedAtEdited = false;
                          }),
                          child: const Text('Reset'),
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
                    onPressed: _confirmDiscard,
                    child: const Text('Cancel'),
                  ),
                  const Gap(8),
                  FilledButton(
                    onPressed: _dirty ? () => _save(context) : null,
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
    required List<LabeledField> fields,
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
                key: ObjectKey(e.value),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label — autocomplete with standard suggestions.
                    SizedBox(
                      width: 110,
                      child: LabelAutocomplete(
                        controller: e.value.label,
                        options: labelOptions,
                      ),
                    ),
                    const Gap(8),
                    // Value field
                    Expanded(
                      child: TextField(
                        controller: e.value.value,
                        focusNode: e.value.valueFocus,
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
        EditAddButton(label: 'Add', onPressed: onAdd),
      ],
    );
  }
}
