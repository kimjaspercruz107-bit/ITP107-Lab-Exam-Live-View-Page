import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'theme/app_theme.dart';
import 'widgets/reader_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _openFavorites();
}

Future<void> _openFavorites() async {
  try {
    await Hive.initFlutter();
    final favoritesBox = await Hive.openBox<Map>('favoritesBox');
    runApp(PostReaderApp(favoritesBox: favoritesBox));
  } catch (_) {
    // Storage failures must be visible even when the main app cannot start.
    runApp(const _StorageErrorApp());
  }
}

class _StorageErrorApp extends StatefulWidget {
  const _StorageErrorApp();

  @override
  State<_StorageErrorApp> createState() => _StorageErrorAppState();
}

class _StorageErrorAppState extends State<_StorageErrorApp> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Reader & Favorites',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Post Reader & Favorites')),
        body: Center(
          child: _retrying
              ? const CircularProgressIndicator()
              : ReaderState(
                  icon: Icons.folder_off_outlined,
                  title: 'Favorites could not be opened',
                  message:
                      'Check that storage is available, then try again. '
                      'Your saved favorites have not been cleared.',
                  actionLabel: 'Try again',
                  onAction: () async {
                    setState(() => _retrying = true);
                    await _openFavorites();
                    if (mounted) setState(() => _retrying = false);
                  },
                ),
        ),
      ),
    );
  }
}
