/// CapitaliseFirstFormatter — force an upper case first character.
///
// Time-stamp: <Friday 2026-09-26 10:00:00 +1000 Graham Williams>
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

import 'package:flutter/services.dart';

/// Upper cases the first character of a text field as it is typed.
///
/// Used for name fields, where a lower case initial is almost always a typo.
/// The rest of the text is left alone, so McDonald and van Dijk survive.

class CapitaliseFirstFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    final capitalised = text[0].toUpperCase() + text.substring(1);

    // 20260926 gjw The replacement is the same length as the original, so the
    // selection and composing region carried by copyWith stay valid.

    if (capitalised == text) return newValue;

    return newValue.copyWith(text: capitalised);
  }
}
