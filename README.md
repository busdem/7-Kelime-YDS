# 7 Kelime YDS

A Flutter mobile app that helps Turkish learners prepare for the **YDS** (Turkish national English proficiency exam) by learning **7 new words every day**.

I designed and built this app as an English teacher, combining what I know about vocabulary teaching with AI-assisted coding.

## Features

- **7 words a day:** A new set of 7 words is chosen each day from a list of more than 3,400 YDS words and phrases.
- **Rich word cards:** Each word comes with its Turkish meaning, word type, IPA pronunciation, an academic example sentence and its translation.
- **Text-to-speech:** Hear the correct pronunciation of every word and example sentence.
- **Practice modes:**
  - Multiple-choice quiz with automatically generated options
  - Listening practice
  - Spelling practice
- **Spaced repetition:** Words you get wrong come back for review after 1, 3, 7 and 30 days.
- **Collections and notebooks:** Save words to lists like *Favorites*, *Critical Words* or *Words I Struggle With*, and keep your own notes.
- **Word archive and statistics:** Browse all words you have learned and track your progress.
- **Badges:** Earn achievements such as *First Step*, *Streak Fire* and *Word Hunter* to stay motivated.
- **Daily reminders:** A local notification at 09:00 reminds you to learn your new words.
- **Study guide:** Tips on how to study vocabulary for the YDS exam.
- **Themes:** Light and dark mode with several color palettes.

## Built with

- [Flutter](https://flutter.dev) & Dart
- `flutter_tts` for pronunciation
- `shared_preferences` for saving progress on the device
- `flutter_local_notifications` for daily reminders
- `google_mobile_ads` for banner ads

## Running the app

```bash
flutter pub get
flutter run
```

## About

Created by Ayşe Büşra Demirdağ — METU Foreign Language Education graduate and English teacher, currently studying AI-Powered Coding at Anadolu University.
