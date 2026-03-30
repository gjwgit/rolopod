# Rolo Pod Change Log

Noted here are the high level changes for the app.  Each update
includes a short user-oriented description.  The next release is 0.2
following incremental updates through the 0.1.n series.

You can run the app in your browser from the
[**web**](https://rolopod.solidcommunity.au) or else download and
install locally the latest version from the [Solid Community
AU](https://solidcommunity.au) or directly: for **Android** as
[aab](https://solidcommunity.au/installers/rolopod.aab) or
[apk](https://solidcommunity.au/installers/rolopod.apk); for
**GNU/Linux** as
[deb](https://solidcommunity.au/installers/rolopod_amd64.deb) or
[snap](https://solidcommunity.au/installers/rolopod_amd64.snap) or
[zip](https://solidcommunity.au/installers/rolopod-linux.zip); for
**macOS** as
[dmg](https://solidcommunity.au/installers/rolopod-macos.dmg) or
[zip](https://solidcommunity.au/installers/rolopod-macos.zip); for
**Windows** as
[inno](https://solidcommunity.au/installers/rolopod-windows-inno.exe)
or [zip](https://solidcommunity.au/installers/rolopod-windows.zip).

Contributions are welcome. Visit
[github](https://github.com/gjwgit/rolopod) to submit an issue or, even
better, fork the repository yourself, update the code, and submit a
Pull Request. Coding documentation is
[available](https://solidcommunity.au/docs/rolopod/).

We make this project available for free so if you appreciate the app
then please show some ❤️ and tap on the star at
[GitHub](https://github.com/gjwgit/rolopod) to support our work.

This app has been pair programmed by [Graham
Williams](https://togaware.com/Graham.Williams.html) and [Claude
Code](https://claude.com/product/claude-code).

## ToDo

Pod sharing — implement the share UI in Settings (enter a WebID to
share a book with)

Search enhancements — spouse:name, child:name search prefixes
alongside tag:

Duplicate detection — wire up the merge to also save to pod after
merging

vCard import — wire up the file picker for vCard the same way BBDB is
done

BBDB field mapping — the parser currently skips positions [2]/[3]
(org/nickname); some BBDB files may have data there worth extracting

Export — export a book back to BBDB or vCard format

Settings screen — flesh out the book management (rename, delete,
sharing UI)

## 0.2 Basic Functionality

+ Bug - Can not delete Display Name [0.1.11 20260331 gjw]
+ Bug - delete phone retains old labels [0.1.10 20260331 gjw]
+ Cleanup and export with timestamp [0.1.9 20260326 gjw]
+ Be more informative with the deduplicate operation [0.1.8 20260326 gjw]
+ Import and Export internal JSON format for backup [0.1.7 20260326 gjw]
+ Initial address book sharing functionality [0.1.6 20260326 gjw]
+ Prompt for the security key if it is not cached [0.1.5 20260324 gjw]
+ Updated icons [0.1.4 20260324 gjw]
+ Meta infrastructure for building installers [0.1.3 20260324 gjw]
+ Support load, save, editing, linking contacts [0.1.2 20260323 gjw]
+ Support basic import of BBDB [0.1.1 20260323 gjw]

## 0.1 Initial Shell App

+ Initial working app to view the design [0.1.0 20260323 gjw]
