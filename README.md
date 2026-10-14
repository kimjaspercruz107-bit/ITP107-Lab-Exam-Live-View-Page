# Post Reader & Favorites

A Flutter lab application that combines named routes, the JSONPlaceholder REST API, and persistent Hive favorites.

## Run

```sh
flutter pub get
flutter run
```

Use Flutter 3.47 / Dart 3.13.1 or a compatible newer SDK. An internet connection is needed to fetch and submit posts. Saved favorites and notes can be read offline.

## Features

- **Posts (`/`):** fetches posts on startup, displays a searchable `ListView.builder` with `ListTile`, supports pull-to-refresh and retry, and opens Favorites from the AppBar.
- **Post Details (`/details`):** receives the post's `id`, `title`, and `body` through `Navigator.pushNamed` and reads them with `ModalRoute`. Saves a post as a Map under its integer id, preventing duplicates.
- **Favorites (`/favorites`):** reads `box.values`, opens saved posts offline, edits or clears a personal note of up to 200 characters, and removes favorites.
- **Create a post:** the floating button opens a validated title/body dialog. A JSON POST is sent to the API; HTTP 201 produces a visible result containing the returned post. Errors stay in the dialog so the user can retry without losing their draft.
- **Persistence:** `main()` initializes Flutter and Hive and opens `favoritesBox` before `runApp`. `ValueListenableBuilder` keeps saved indicators and favorite lists up to date.
- **Feedback:** loading, empty results, connection errors, unexpected HTTP statuses, invalid responses, and local storage errors are shown in the interface.

JSONPlaceholder simulates writes: a successful POST is not permanently stored on the server and does not add an item to the fetched feed. The app explains this in the creation dialog and result. Hive favorites and notes are stored on the device and survive app restarts. On web, persistence is scoped to the browser and origin; clearing site data removes it.

## Code map

- `lib/main.dart`: startup, Hive initialization, and storage error recovery.
- `lib/app.dart`: application theme and the three named routes.
- `lib/models/post.dart`: post parsing and conversion to Maps.
- `lib/services/post_api.dart`: GET, POST, JSON parsing, and request errors.
- `lib/screens/`: one class/file per screen.
- `lib/widgets/`: reusable layouts, post tiles, and input dialogs.
- `lib/theme/app_theme.dart`: shared Material 3 design.

Android's main manifest includes Internet permission. The macOS entitlements allow outgoing network connections in debug and release builds.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
```

Tests use a mock HTTP client and temporary real Hive storage. They cover successful and failed requests, invalid JSON, form validation, named-route navigation, favorite creation and deletion, note updates, and persistence after reopening the box.

Manual persistence check: save a post, add a note, close and reopen the app, and open Favorites. Remove it, reopen again, and confirm it stays removed.

## References

- [JSONPlaceholder API](https://jsonplaceholder.typicode.com/)
- [Flutter named-route arguments](https://docs.flutter.dev/cookbook/navigation/navigate-with-arguments)
- [Flutter HTTP requests and platform configuration](https://docs.flutter.dev/cookbook/networking/fetch-data)
- [Hive box operations](https://pub.dev/documentation/hive/latest/hive/Box-class.html)
