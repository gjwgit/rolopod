# Rolo Pod - A Secure, Private, Sharable Address Book

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/gjwgit/rolopod)
[![GitHub License](https://img.shields.io/github/license/gjwgit/rolopod)](https://raw.githubusercontent.com/gjwgit/rolopod/dev/LICENSE)
[![Flutter Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/gjwgit/rolopod/master/pubspec.yaml&query=$.version&label=version)](https://github.com/gjwgit/rolopod/blob/dev/CHANGELOG.md)
[![Last Updated](https://img.shields.io/github/last-commit/gjwgit/rolopod?label=last%20updated)](https://github.com/gjwgit/rolopod/commits/dev/)
[![GitHub commit activity (dev)](https://img.shields.io/github/commit-activity/w/gjwgit/rolopod/dev)](https://github.com/gjwgit/rattle/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/gjwgit/rolopod)](https://github.com/gjwgit/rolopod/issues)

[Rolopod](https://gjwgit.github.io/rolopod/) is a tool to collect your
Hyundai vehicle data together in one secure and private place. You can
selectively share any parts of your data with others. The app itself
presents the data and analyses of the data. It is being developed by
[Togaware](https://togaware.com) and pair programmed by [Graham
Williams](https://togaware.com/Graham.Williams.html) and [Claude
Code](https://claude.com/product/claude-code).

We make this project available for free so if you appreciate the app
then please show some ❤️ and tap on the star at
[GitHub](https://github.com/gjwgit/rolopod) to support our work.

The latest version of the app can be run online at
[rolopod.solidcommunity.au](https://rolopod.solidcommunity.au) with no
installation required though requiring a Bluelink login, or downloaded
and installed for your platform from the [Solid Community
AU](https://solidcommunity.au) repository:

<!-- markdownlint-disable MD036 -->
+ **Web**
  [solidcommunity](https://rolopod.solidcommunity.au/);
+ **Android**
  [aab](https://solidcommunity.au/installers/rolopod.aab) or
  [apk](https://solidcommunity.au/installers/rolopod.apk);
+ **GNU/Linux**
  [deb](https://solidcommunity.au/installers/rolopod_amd64.deb) or
  [snap](https://solidcommunity.au/installers/rolopod_amd64.snap) or
  [zip](https://solidcommunity.au/installers/rolopod-linux.zip);
+ **macOS**
  [dmg](https://solidcommunity.au/installers/rolopod-macos.dmg) or
  [zip](https://solidcommunity.au/installers/rolopod-macos.zip);
+ **Windows**
  [inno](https://solidcommunity.au/installers/rolopod-windows-inno.exe) or
  [zip](https://solidcommunity.au/installers/rolopod-windows.zip).

[Installation
details](https://github.com/gjwgit/rolopod/blob/dev/installers/README.md)
are available for all platforms.

Contributions are welcome. Visit
[github](https://github.com/gjwgit/rolopod) to submit an issue or,
even better, fork the repository yourself, update the code, and submit
a Pull Request. The app is implemented in
[Flutter](https://flutter.dev) using
[solidui](https://pub.dev/packages/solidui). Thanks.

---

## Introduction

A Flutter app to view your Hyundai Bluelink vehicle data (currently
for Australia / NZ but please send in PRs for other regions).

---

## Features

+ **Login** with your Bluelink email, password & PIN
+ **Auto login** on relaunch — no need to re-enter Bluelink credentials
+ **Demo mode** — test the UI without real credentials
+ **Dashboard** showing:
  + Vehicle nickname, model, year, colour & fuel type badge
  + Lock status, engine status, charging status
  + Battery level + range bar (EV/PHEV)
  + Fuel level + range bar (ICE/HEV)
  + Door, bonnet & boot open/close
  + Defrost status
  + Tyre pressure (all 4 corners, in kPa)
  + External temperature
  + Odometer reading
  + GPS coordinates
  + Full VIN & vehicle details
  + Last updated timestamp
+ **Pull-to-refresh** and refresh button
+ **Sign out**

---

## 🔌🚗 Showcase 🌳🌞

Under settings you can specify your username, password and pin to
access your Bluelink account. This is necessary to be able to use this
app. Currently only AU/NZ are supported but we welcome pull requests
to extend to other jurisdications.

Login Screen - Here you can connect to your historic data you have
stored securely and privately on your Solid Pod.

![Login Screen](./assets/screenshots/login.png)

Changelog Screen - Tap the Version string to get the latest changes
for the app.

![Change Log](./assets/screenshots/changelog.png)

Status Page - The basic home page reports some of the key information
of interest to the driver.

![Status Page](./assets/screenshots/status.png)

Energy Page - The status of the battery and other energy related
statistics are presented here.

![Energy Page](./assets/screenshots/energy.png)

Visuals Page - Here we explore visually some of the vehicle performace
stats. The tooltip shows on this particular day the car regenerated
about half of the used power through braking, using iPedal that day.

![Visuals Page](./assets/screenshots/visuals.png)

Stats Page - Various statistics about your vehicle's performance.

![Stats Page](./assets/screenshots/stats.png)

History Page - This data is stored securely and privately on your
Solid Pod. Tap the down arrow to load any dataset into the app as the
analysed/displayed dataset (replacing the data downloaded from your
vehicle).

![History Page](./assets/screenshots/history.png)

---

## Setup to Build for Yourself

### Prerequisites

+ Flutter 3.x+ installed
+ `flutter doctor` passing for your target platform

### Install

```bash
git clone git@github.com:gjwgit/rolopod.git
cd rolopod
flutter pub get
flutter run
```
