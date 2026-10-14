import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post.dart';
import '../theme/app_theme.dart';
import '../widgets/reader_widgets.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.favoritesBox});
  final Box<Map> favoritesBox;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool _saving = false;
  String? _error;

  Future<void> _saveFavorite(Post post) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // The id is the key, so saving a post cannot create a duplicate.
      final existing = widget.favoritesBox.get(post.id);
      await widget.favoritesBox.put(post.id, {
        ...post.toMap(),
        'note': existing?['note'] ?? '',
      });
      if (mounted) showReaderMessage(context, 'Post saved to favorites.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save this favorite. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Named-route arguments are retrieved here, as required by the exercise.
    final arguments = ModalRoute.of(context)!.settings.arguments;
    Post? post;
    if (arguments is Map) {
      try {
        post = Post.fromMap(arguments);
      } on FormatException {
        post = null;
      }
    }
    final selectedPost = post;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        leading: IconButton(
          tooltip: 'Back to posts',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Open favorites',
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReaderPage(
        child: selectedPost == null
            ? const ReaderState(
                icon: Icons.article_outlined,
                title: 'Post unavailable',
                message: 'Open a post from the Posts or Favorites screen.',
              )
            : ValueListenableBuilder<Box<Map>>(
                valueListenable: widget.favoritesBox.listenable(
                  keys: [selectedPost.id],
                ),
                builder: (context, box, child) {
                  final saved = box.containsKey(selectedPost.id);
                  final note =
                      box.get(selectedPost.id)?['note'] as String? ?? '';
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F0E9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.article_outlined,
                              color: readerTeal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'POST ${selectedPost.id.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                              color: readerTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SelectableText(
                        selectedPost.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),
                      SelectableText(
                        selectedPost.body,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(height: 1.9),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: saved || _saving
                            ? null
                            : () => _saveFavorite(selectedPost),
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_add_outlined,
                        ),
                        label: Text(
                          _saving
                              ? 'Saving...'
                              : saved
                              ? 'Saved to Favorites'
                              : 'Save to Favorites',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        saved
                            ? 'This post is available offline in your favorites.'
                            : 'Keep this post on your device to read it again later.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF63736F),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        InlineError(message: _error!),
                      ],
                      if (saved) ...[
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOUR PERSONAL NOTE',
                                  style: TextStyle(
                                    color: readerTeal,
                                    fontSize: 11,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  note.isEmpty
                                      ? 'Add a personal note from the Favorites screen.'
                                      : note,
                                  style: const TextStyle(height: 1.6),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/favorites',
                                  ),
                                  icon: const Icon(Icons.edit_note_rounded),
                                  label: const Text('Manage in Favorites'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }
}
