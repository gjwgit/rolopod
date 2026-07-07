/// AppScaffold — main SolidScaffold with left nav for RoloPod.
///
// Time-stamp: <Sunday 2026-06-28 11:49:45 +1000 Graham Williams>
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
import 'package:rolopod/screens/birthday_calendar_screen.dart';
import 'package:rolopod/screens/contacts_screen.dart';
import 'package:rolopod/screens/duplicates_screen.dart';
import 'package:rolopod/screens/import_screen.dart';
import 'package:rolopod/screens/settings_screen.dart';
import 'package:rolopod/services/app_provider.dart';
import 'package:rolopod/widgets/pod_refresh_action.dart';
import 'package:rolopod/widgets/startup_overlay.dart';

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
    final provider = context.read<AppProvider>();
    provider.setStartupPhase(StartupPhase.unlocking);
    try {
      // Prompt for the security key if not already cached.
      // This shows the key entry popup on all platforms including Android.
      await getKeyFromUserIfRequired(context, widget);

      if (!mounted) return;
      setState(() => _isKeySaved = true);

      // Key is now available — safe to read encrypted pod files.
      provider.setStartupPhase(StartupPhase.loading);
      await provider.loadAllBooksFromPod();
    } catch (e, st) {
      debugPrint('[AppScaffold] Security key error: $e\n$st');
    } finally {
      provider.setStartupPhase(StartupPhase.ready);
    }
  }

  // Wrap a menu screen so the busy overlay covers it while the Pod is being
  // unlocked and contacts are loading, regardless of which screen is shown.
  Widget _withStartupOverlay(Widget child) {
    return Builder(
      builder: (context) {
        final phase = context.watch<AppProvider>().startupPhase;
        return StartupOverlay(phase: phase, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();

    return SolidScaffold(
      showLogout: false,
      showLogin: false,
      themeToggle: const SolidThemeToggleConfig(enabled: true),
      aboutConfig: SolidAboutConfig(
        applicationName: appName,
        applicationIcon: Image.asset(
          'assets/images/app_icon.png',
          width: 64,
          height: 64,
        ),
        applicationLegalese: '''

        © 2026 Togaware Pty Ltd

        ''',
        text: '''

        RoloPod is a private contact manager that stores your address books —
        contacts, phone numbers, emails, addresses and notes — encrypted in
        your personal Solid Pod, so your data stays under your control. Your
        Solid Pod can be hosted on any Solid server and being encrypted it is
        protected against casual access by anyone, including the server
        administrators.

        ### Key features

        - Browse and search across multiple address books
        - Import from Emacs BBDB or vCard files
        - Find and merge duplicate contacts
        - Backup and restore your contacts as JSON
        - Share address books with other Pod owners
        - Export contacts as JSON, BBDB, vCard or PDF
        - Security key management for encrypted data
        - Theme switching (light / dark / system)

        For more information, visit the
        [RoloPod](https://github.com/gjwgit/rolopod) GitHub repository and our
        [Australian Solid Community](https://solidcommunity.au) web site.

        ''',
        readmeUrl: 'https://gjwgit.github.io/rolopod',
      ),
      appBar: SolidAppBarConfig(
        title: appName,
        versionConfig: const SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/rolopod/blob/dev/CHANGELOG.md',
        ),
        actions: [
          buildPodRefreshAction(
            context: context,
            onRefresh: context.read<AppProvider>().refreshFromPod,
          ),
        ],
      ),
      menu: [
        SolidMenuItem(
          title: 'Contacts',
          icon: Icons.contacts,
          tooltip: '**Contacts**\n\nBrowse and search all your address books.',
          child: _withStartupOverlay(const ContactsScreen()),
        ),
        SolidMenuItem(
          title: 'Birthdays',
          icon: Icons.cake,
          tooltip: '**Birthdays**\n\nA month calendar with your contacts'
              ' birthdays marked.',
          child: _withStartupOverlay(const BirthdayCalendarScreen()),
        ),
        SolidMenuItem(
          title: 'Duplicates',
          icon: Icons.content_copy,
          tooltip: '**Duplicates**\n\n'
              'Find and merge duplicate contacts across your address books.',
          child: _withStartupOverlay(const DuplicatesScreen()),
        ),
        SolidMenuItem(
          title: 'Books',
          icon: Icons.library_books,
          tooltip: '**Books**\n\n'
              'Manage address books, sharing and app preferences.',
          child: _withStartupOverlay(const SettingsScreen()),
        ),
        SolidMenuItem(
          title: 'Backup',
          icon: Icons.save_alt,
          tooltip: '**Backup**\n\n'
              'Back up and restore your contacts, or import from '
              'BBDB or vCard files.',
          child: _withStartupOverlay(const ImportScreen()),
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
