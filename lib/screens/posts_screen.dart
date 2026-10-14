import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post.dart';
import '../services/post_api.dart';
import '../theme/app_theme.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/reader_widgets.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key, required this.favoritesBox, required this.api});

  final Box<Map> favoritesBox;
  final PostApi api;

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<Post> _posts = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  Post? _createdPost;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await widget.api.fetchPosts();
      if (!mounted) return;
      setState(() => _posts = posts);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPost() async {
    final post = await showDialog<Post>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreatePostDialog(api: widget.api),
    );
    if (!mounted || post == null) return;
    setState(() => _createdPost = post);
    showReaderMessage(
      context,
      'Post #${post.id} created successfully (HTTP 201).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final posts = _posts
        .where(
          (post) =>
              post.title.toLowerCase().contains(query) ||
              post.body.toLowerCase().contains(query),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        leading: const Icon(Icons.auto_stories_rounded, color: readerTeal),
        actions: [
          IconButton(
            tooltip: 'Refresh posts',
            onPressed: _loading ? null : _fetchPosts,
            icon: const Icon(Icons.refresh_rounded),
          ),
          ValueListenableBuilder<Box<Map>>(
            valueListenable: widget.favoritesBox.listenable(),
            builder: (context, box, child) => IconButton(
              tooltip: 'Open favorites',
              onPressed: () => Navigator.pushNamed(context, '/favorites'),
              icon: Badge(
                isLabelVisible: box.isNotEmpty,
                label: Text('${box.length}'),
                child: const Icon(Icons.bookmarks_outlined),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReaderPage(
        child: ValueListenableBuilder<Box<Map>>(
          valueListenable: widget.favoritesBox.listenable(),
          builder: (context, box, child) => RefreshIndicator(
            onRefresh: _fetchPosts,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
              itemCount:
                  1 +
                  (_loading || _error != null || posts.isEmpty
                      ? 1
                      : posts.length),
              itemBuilder: (context, index) {
                if (index == 0) return _header(posts.length);
                if (_loading) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 18),
                        Text('Finding your next read...'),
                      ],
                    ),
                  );
                }
                if (_error != null) {
                  return ReaderState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load posts',
                    message: _error!,
                    actionLabel: 'Try again',
                    onAction: _fetchPosts,
                  );
                }
                if (posts.isEmpty) {
                  return ReaderState(
                    icon: Icons.search_off_rounded,
                    title: query.isEmpty ? 'No posts yet' : 'No matching posts',
                    message: query.isEmpty
                        ? 'The server returned an empty list. Pull down to refresh.'
                        : 'Try another title or a word from the post.',
                  );
                }
                final post = posts[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PostTile(
                    post: post,
                    saved: box.containsKey(post.id),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/details',
                      arguments: post.toMap(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New post'),
      ),
    );
  }

  Widget _header(int visibleCount) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: readerTeal,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'POST READER & FAVORITES',
                style: TextStyle(
                  color: Color(0xFFC6E3D8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A little reading.\nA lot to discover.',
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find a good read. Save a favorite. Make a note.',
                style: TextStyle(color: Color(0xFFE1F0E9), height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search posts',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (_createdPost case final post?) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F0E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: readerTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Post #${post.id} created (HTTP 201)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss creation result',
                      onPressed: () => setState(() => _createdPost = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  post.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(post.body),
                const SizedBox(height: 10),
                const Text(
                  'JSONPlaceholder simulates creation. This post is not '
                  'stored on the server and will not appear in the feed.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Explore posts',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!_loading && _error == null)
              Text(
                '$visibleCount ${visibleCount == 1 ? 'post' : 'posts'}',
                style: const TextStyle(color: Color(0xFF63736F)),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
