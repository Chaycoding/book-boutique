# 📚 Book Boutique

A personal library manager built in Flutter — search books via the Google Books API, save them to an "Own It" or "Wishlist" shelf, and track your reading progress with a local, offline-first database.

![Platform](https://img.shields.io/badge/platform-Flutter-02569B?logo=flutter)
![Database](https://img.shields.io/badge/local%20db-Isar-orange)
![Status](https://img.shields.io/badge/status-active-brightgreen)

---

## Demo
![Link on youtube](https://youtube.com/shorts/jMDRAQ6Pi5M?feature=share)

---

## Features

- 🔍 **Search** — live search against the Google Books API, with debounced input and graceful error handling
- 📖 **Two shelves** — categorize saved books as "Own It" or "Wishlist"
- ✅ **Reading status** — track each owned book as Not Started, Reading, or Finished, right from the book cover
- 🏠 **Home dashboard** — "Reading Right Now" and "To Be Read" shelves, a reading-goal progress tracker, and curated category banners
- 📄 **Book detail view** — cover, description, publisher, and page count pulled straight from the API, with a Hero animation from the shelf
- 💾 **Local-first storage** — powered by Isar, so your library works fully offline once books are saved
- 🖼️ **Cached covers** — images are cached and downscaled on decode to keep scrolling smooth
- 🔄 **Backup & restore** — export your entire library to a JSON file and share it anywhere; import it back in on any device, with automatic duplicate detection
- 🎨 **Custom Material 3 theme** — a consistent color/typography/spacing system instead of scattered inline styles

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter / Dart |
| Local database | [Isar](https://isar.dev) (via the `isar_community` fork) |
| Remote data | Google Books REST API |
| Networking | `http` |
| Image caching | `cached_network_image` |
| Backup / restore | `file_picker`, `share_plus` |
| Secrets | `flutter_dotenv` |
| Fonts | `google_fonts` (Manrope) |
| Loading states | `shimmer` |

---

## Engineering Notes

A few decisions from building this that are worth calling out, since they involved real debugging rather than following a tutorial:

**Migrating off an abandoned package.** The original `isar` package hasn't been maintained since 2023 and its Android build config predates namespace requirements in newer Android Gradle Plugin / Gradle versions — the build failed outright on a fresh setup. Rather than patching the vendored `build.gradle` (which gets wiped on every `flutter clean`), I migrated the whole project to the actively-maintained `isar_community` fork, which is a drop-in API replacement — only the import path changes.

**Fixing an exposed API key.** The Google Books API key was originally hardcoded as a string literal, which meant it shipped inside the compiled APK. I moved it to a `.env` file loaded at runtime via `flutter_dotenv`, excluded it from version control, and restricted the key in Google Cloud Console to the Books API only — while learning along the way that Android *app*-restricted keys require headers that plain REST clients don't send automatically, so API-only restriction was the correct fit here.

**Working through a breaking dependency change mid-build.** `file_picker` shipped a major version (v12) that removed the previously-standard `FilePicker.platform` static accessor in favor of direct static methods with a different return signature — required adapting the import feature to the new API surface rather than the one most existing documentation still shows.

---

## Getting Started

```bash
git clone <your-repo-url>
cd bookmanager
flutter pub get
```

Create a `.env` file in the project root:
```
GOOGLE_BOOKS_API_KEY=your_key_here
```

Generate the Isar schema:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Run it:
```bash
flutter run
```

---

## What I'd Do Differently

- Add automated tests around the sort/status logic — this is the part that broke more than once during development, and it's exactly the kind of thing a unit test would have caught immediately
- Set up CI (GitHub Actions running `flutter analyze` + `flutter test` on push)
- Move state management to Provider/Riverpod rather than `setState` + `FutureBuilder` per screen, so shelf/status updates propagate without manual `.then((_) => setState(...))` calls
