import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post.dart';
import '../theme/app_theme.dart';
import '../widgets/note_dialog.dart';
import '../widgets/reader_widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.favoritesBox});
  final Box<Map> favoritesBox;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Set<int> _deleting = {};

  Future<void> _editNote(Post post) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          NoteDialog(favoritesBox: widget.favoritesBox, post: post),
    );
    if (mounted && saved == true) {
      showReaderMessage(context, 'Personal note saved.');
    }
  }

  Future<void> _removeFavorite(Post post) async {
    setState(() => _deleting.add(post.id));
    try {
      await widget.favoritesBox.delete(post.id);
      if (mounted) showReaderMessage(context, 'Post removed from favorites.');
    } catch (_) {
      if (mounted) {
        showReaderMessage(
          context,
          'Could not remove this favorite. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(post.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Favorites'),
      leading: IconButton(
        tooltip: 'Go back',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: ReaderPage(
      child: ValueListenableBuilder<Box<Map>>(
        valueListenable: widget.favoritesBox.listenable(),
        builder: (context, box, child) {
          // No network request is needed to read a saved post.
          final favorites = box.values.toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: favorites.isEmpty ? 2 : favorites.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.bookmarks_rounded,
                        color: readerTeal,
                        size: 36,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your reading corner.',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Good reads, kept close. Add a note to remember why.',
                        style: TextStyle(height: 1.6, color: Color(0xFF63736F)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${favorites.length} saved ${favorites.length == 1 ? 'post' : 'posts'}  ·  Available offline',
                        style: const TextStyle(
                          color: readerTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (favorites.isEmpty) {
                return ReaderState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Save your first favorite',
                  message:
                      'Open a post and tap Save to Favorites. '
                      'Your saved posts and notes stay here after you close the app.',
                  actionLabel: 'Back to reading',
                  onAction: () => Navigator.pop(context),
                );
              }
              final value = favorites[index - 1];
              final Post post;
              try {
                post = Post.fromMap(value);
              } on FormatException {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: InlineError(
                    message: 'A saved post could not be read.',
                  ),
                );
              }
              final note = value['note'] as String? ?? '';
              final deleting = _deleting.contains(post.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(
                          20,
                          12,
                          12,
                          4,
                        ),
                        title: Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Post #${post.id}  ·  Tap to read',
                            style: const TextStyle(
                              fontSize: 12,
                              color: readerTeal,
                            ),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/details',
                          arguments: post.toMap(),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PERSONAL NOTE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF63736F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note.isEmpty
                                  ? 'A thought worth keeping? Add it here.'
                                  : note,
                              style: TextStyle(
                                height: 1.5,
                                fontStyle: note.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: deleting
                                      ? null
                                      : () => _editNote(post),
                                  icon: const Icon(Icons.edit_note_rounded),
                                  label: Text(
                                    note.isEmpty ? 'Add note' : 'Edit note',
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove favorite',
                              onPressed: deleting
                                  ? null
                                  : () => _removeFavorite(post),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
