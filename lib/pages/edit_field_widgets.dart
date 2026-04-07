/// EditFieldWidgets — shared helper widgets for the ContactEdit form.
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

import 'package:rolopod/models/contact.dart';

// ── Section label ─────────────────────────────────────────────────────────────

Widget editSectionLabel(BuildContext context, String text) => Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );

// ── Add button ────────────────────────────────────────────────────────────────

class EditAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const EditAddButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

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

class EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;

  const EditField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
}

// ── Labeled field pair (label + value controllers) ────────────────────────────

class LabeledField {
  final TextEditingController label;
  final TextEditingController value;
  final FocusNode valueFocus;

  LabeledField({required String label, required String value})
      : label = TextEditingController(text: label),
        value = TextEditingController(text: value),
        valueFocus = FocusNode();

  factory LabeledField.from(ContactField f) =>
      LabeledField(label: f.label, value: f.value);

  factory LabeledField.empty(String defaultLabel) =>
      LabeledField(label: defaultLabel, value: '');

  void dispose() {
    label.dispose();
    value.dispose();
    valueFocus.dispose();
  }
}

extension LabeledFieldListX on List<LabeledField> {
  List<ContactField> toFields() => where((f) => f.value.text.trim().isNotEmpty)
      .map(
        (f) => ContactField(
          label: f.label.text.trim().isEmpty ? 'other' : f.label.text.trim(),
          value: f.value.text.trim(),
        ),
      )
      .toList();
}

// ── Label with autocomplete (free-text with standard suggestions) ─────────

/// A label editor that suggests [options] but accepts any typed value.
class LabelAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;
  final bool autofocus;

  const LabelAutocomplete({
    super.key,
    required this.controller,
    required this.options,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Autocomplete<String>(
      initialValue: controller.value,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return options;

        return options.where((o) => o.toLowerCase().contains(query)).toList();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        // Keep our backing controller in sync.

        fieldController
            .addListener(() => controller.text = fieldController.text);

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          autofocus: autofocus,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 14,
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 0,
            ),
          ),
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 160),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);

                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(option, style: const TextStyle(fontSize: 13)),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: (value) => controller.text = value,
    );
  }
}

// ── Address field group ───────────────────────────────────────────────────────

class AddressField {
  final TextEditingController label;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController postcode;
  final TextEditingController country;
  final FocusNode streetFocus;

  AddressField({
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
        country = TextEditingController(text: country),
        streetFocus = FocusNode();

  factory AddressField.from(ContactAddress a) => AddressField(
        label: a.label,
        street: a.street ?? '',
        city: a.city ?? '',
        state: a.state ?? '',
        postcode: a.postcode ?? '',
        country: a.country ?? '',
      );

  factory AddressField.empty() => AddressField(
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
    streetFocus.dispose();
  }
}

extension AddressFieldListX on List<AddressField> {
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

class AddressEditor extends StatelessWidget {
  final AddressField field;
  final VoidCallback onRemove;

  const AddressEditor({
    super.key,
    required this.field,
    required this.onRemove,
  });

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
                        (l) => DropdownMenuItem(value: l, child: Text(l)),
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
            focusNode: field.streetFocus,
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
