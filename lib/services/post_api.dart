import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/post.dart';

class PostApiException implements Exception {
  const PostApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PostApi {
  const PostApi({this.client});

  static const endpoint = 'https://jsonplaceholder.typicode.com/posts';
  static const requestTimeout = Duration(seconds: 20);
  final http.Client? client;

  Future<List<Post>> fetchPosts() async {
    try {
      final response =
          await (client?.get(Uri.parse(endpoint)) ??
                  http.get(Uri.parse(endpoint)))
              .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw PostApiException(
          'Could not load posts (HTTP ${response.statusCode}). Please try again.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('Expected a list of posts.');
      }
      return decoded.map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid post.');
        }
        return Post.fromMap(item);
      }).toList();
    } on TimeoutException {
      throw const PostApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const PostApiException(
        'Could not connect. Check your internet connection and try again.',
      );
    } on FormatException {
      throw const PostApiException('The server returned invalid post data.');
    }
  }

  Future<Post> createPost({required String title, required String body}) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty || trimmedBody.isEmpty) {
      throw const PostApiException('Please enter both a title and a body.');
    }
    try {
      const headers = {'Content-Type': 'application/json; charset=UTF-8'};
      final payload = jsonEncode({
        'title': trimmedTitle,
        'body': trimmedBody,
        'userId': 1,
      });
      final response =
          await (client?.post(
                    Uri.parse(endpoint),
                    headers: headers,
                    body: payload,
                  ) ??
                  http.post(
                    Uri.parse(endpoint),
                    headers: headers,
                    body: payload,
                  ))
              .timeout(requestTimeout);
      if (response.statusCode != 201) {
        throw PostApiException(
          'Could not create the post (HTTP ${response.statusCode}). Please try again.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const FormatException('Expected a post.');
      }
      return Post.fromMap(decoded);
    } on TimeoutException {
      throw const PostApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const PostApiException(
        'Could not send the post. Check your internet connection and try again.',
      );
    } on FormatException {
      throw const PostApiException(
        'The server returned an invalid creation response.',
      );
    }
  }
}

String requestErrorMessage(Object error) => error is PostApiException
    ? error.message
    : 'Something went wrong. Please try again.';
