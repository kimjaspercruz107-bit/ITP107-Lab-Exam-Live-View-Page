import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_api.dart';
import 'reader_widgets.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key, required this.api});
  final PostApi api;

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final post = await widget.api.createPost(
        title: _titleController.text,
        body: _bodyController.text,
      );
      if (!mounted) return;
      Navigator.pop<Post>(context, post);
    } catch (error) {
      if (mounted) setState(() => _error = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      title: const Text('Create a post'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share a thought with JSONPlaceholder.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a title.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyController,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Body'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a body.'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demo API: new posts are not permanently saved online.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  InlineError(message: _error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined, size: 18),
          label: Text(_submitting ? 'Sending...' : 'Send post'),
        ),
      ],
    ),
  );
}
