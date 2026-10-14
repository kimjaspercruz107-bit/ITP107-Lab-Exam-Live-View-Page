import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/post.dart';
import 'reader_widgets.dart';

class NoteDialog extends StatefulWidget {
  const NoteDialog({super.key, required this.favoritesBox, required this.post});
  final Box<Map> favoritesBox;
  final Post post;

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.favoritesBox.get(widget.post.id)?['note'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.favoritesBox.get(widget.post.id);
      if (existing == null) {
        setState(() => _error = 'This post is no longer in your favorites.');
        return;
      }
      await widget.favoritesBox.put(widget.post.id, {
        ...existing,
        'note': _controller.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your note. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Personal note'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                enabled: !_saving,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Your note',
                  hintText: 'What stood out to you?',
                  helperText: 'Leave blank to clear the note.',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                InlineError(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save note'),
        ),
      ],
    ),
  );
}
