/// AppScaffold — main SolidScaffold with left nav for RoloPod.
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

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:rolopod/constants/app.dart';
import 'package:rolopod/screens/contacts_screen.dart';
import 'package:rolopod/screens/duplicates_screen.dart';
import 'package:rolopod/screens/import_screen.dart';
import 'package:rolopod/screens/settings_screen.dart';
import 'package:rolopod/services/app_provider.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  void initState() {
    super.initState();
    // Load all books from pod on first frame after login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAllBooksFromPod();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();

    return const SolidScaffold(
      showLogout: false,
      appBar: SolidAppBarConfig(
        title: appName,
        versionConfig: SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/rolopod/blob/main/CHANGELOG.md',
        ),
      ),
      menu: [
        SolidMenuItem(
          title: 'Contacts',
          icon: Icons.contacts,
          tooltip: '**Contacts**\n\nBrowse and search all your address books.',
          child: ContactsScreen(),
        ),
        SolidMenuItem(
          title: 'Import',
          icon: Icons.upload_file,
          tooltip: '**Import**\n\n'
              'Import contacts from BBDB or vCard files.',
          child: ImportScreen(),
        ),
        SolidMenuItem(
          title: 'Duplicates',
          icon: Icons.content_copy,
          tooltip: '**Duplicates**\n\n'
              'Find and merge duplicate contacts across your address books.',
          child: DuplicatesScreen(),
        ),
        SolidMenuItem(
          title: 'Settings',
          icon: Icons.settings,
          tooltip: '**Settings**\n\n'
              'Manage address books, sharing and app preferences.',
          child: SettingsScreen(),
        ),
      ],
    );
  }
}
