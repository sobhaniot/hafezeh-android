# حافظه (Hafezeh)

A Persian, offline-first Android app for learning vocabulary with spaced repetition. Built with Flutter.

## Features

- Add a word, its Persian meaning, and an example sentence
- Review flashcards with Again, Hard, Good, and Easy ratings
- Schedule the next review from each rating
- Search words and view learning progress
- Store cards locally on the device; no account or network is required
- Persian right-to-left interface

## Run

Install Flutter and Android Studio or the Android command-line tools, then run:

```sh
flutter pub get
flutter run
```

The Android Gradle Plugin requires JDK 17 or newer. The project targets Android only. Word data is stored in the app's private Android preferences and is removed when the app is uninstalled.

