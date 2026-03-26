/// AppScaffold — main SolidScaffold with left nav for RoloPod.
///
// Time-stamp: <Tuesday 2026-03-24 17:03:49 +1100 Graham Williams>
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
  /// Whether the security key is currently saved/available.
  bool _isKeySaved = false;

  @override
  void initState() {
    super.initState();

    // On the first frame after login, prompt for the security key if it is
    // not already cached, then load the address books.

    WidgetsBinding.instance.addPostFrameCallback((_) => _initKeys());
  }

  Future<void> _initKeys() async {
    try {
      // Prompt for the security key if not already cached.
      // This shows the key entry popup on all platforms including Android.
      await getKeyFromUserIfRequired(context, widget);

      if (!mounted) return;
      setState(() => _isKeySaved = true);

      // Key is now available — safe to read encrypted pod files.
      await context.read<AppProvider>().loadAllBooksFromPod();
    } catch (e, st) {
      debugPrint('[AppScaffold] Security key error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();

    return SolidScaffold(
      showLogout: false,
      appBar: const SolidAppBarConfig(
        title: appName,
        versionConfig: SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/rolopod/blob/dev/CHANGELOG.md',
        ),
      ),
      menu: const [
        SolidMenuItem(
          title: 'Contacts',
          icon: Icons.contacts,
          tooltip: '**Contacts**\n\nBrowse and search all your address books.',
          child: ContactsScreen(),
        ),
        SolidMenuItem(
          title: 'Import / Export',
          icon: Icons.import_export,
          tooltip: '**Import / Export**\n\n'
              'Import contacts from BBDB or vCard files, '
              'or export a backup as JSON.',
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
      statusBar: SolidStatusBarConfig(
        serverInfo:
            const SolidServerInfo(serverUri: SolidConfig.defaultServerUrl),
        loginStatus: const SolidLoginStatus(),
        // Security key widget — allows the user to view, change or forget
        // their key. onKeyStatusChanged re-triggers loading if the key is
        // forgotten and then re-entered.
        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: _isKeySaved,
          title: 'RoloPod Security Keys',
          tooltip: '**Security Keys**\n\n'
              'Manage your Solid Pod encryption key.\n'
              'Tap to view, change or forget the key.',
          onKeyStatusChanged: (hasKey) {
            final wasKeySaved = _isKeySaved;
            setState(() => _isKeySaved = hasKey);
            if (hasKey && !wasKeySaved) {
              // Key was re-entered after being forgotten — reload.
              context.read<AppProvider>().loadAllBooksFromPod();
            }
          },
        ),
      ),
    );
  }
}
