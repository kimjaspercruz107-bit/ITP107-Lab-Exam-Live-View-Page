import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'screens/details_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/posts_screen.dart';
import 'services/post_api.dart';
import 'theme/app_theme.dart';

class PostReaderApp extends StatelessWidget {
  const PostReaderApp({
    super.key,
    required this.favoritesBox,
    this.api = const PostApi(),
  });

  final Box<Map> favoritesBox;
  final PostApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Reader & Favorites',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => PostsScreen(favoritesBox: favoritesBox, api: api),
        '/details': (context) => DetailsScreen(favoritesBox: favoritesBox),
        '/favorites': (context) => FavoritesScreen(favoritesBox: favoritesBox),
      },
    );
  }
}
