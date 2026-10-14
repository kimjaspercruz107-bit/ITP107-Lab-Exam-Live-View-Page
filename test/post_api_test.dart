import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/services/post_api.dart';

const samplePost = {
  'id': 7,
  'title': 'A good read',
  'body': 'A thoughtful body.',
};

void main() {
  test('GET parses posts and uses the correct endpoint', () async {
    final api = PostApi(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), PostApi.endpoint);
        return http.Response(jsonEncode([samplePost]), 200);
      }),
    );
    final posts = await api.fetchPosts();
    expect(posts.single.id, 7);
    expect(posts.single.title, 'A good read');
    expect(posts.single.body, 'A thoughtful body.');
  });

  test('GET accepts an empty list', () async {
    final api = PostApi(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    expect(await api.fetchPosts(), isEmpty);
  });

  test('GET reports non-200 status codes', () async {
    final api = PostApi(
      client: MockClient((_) async => http.Response('', 503)),
    );
    await expectLater(
      api.fetchPosts(),
      throwsA(
        isA<PostApiException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 503'),
        ),
      ),
    );
  });

  for (final invalid in ['not json', '{}', '[{"id": 1}]', '[null]']) {
    test('GET reports malformed data: $invalid', () async {
      final api = PostApi(
        client: MockClient((_) async => http.Response(invalid, 200)),
      );
      await expectLater(
        api.fetchPosts(),
        throwsA(
          isA<PostApiException>().having(
            (error) => error.message,
            'message',
            contains('invalid post data'),
          ),
        ),
      );
    });
  }

  test('GET reports connection failures', () async {
    final api = PostApi(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      api.fetchPosts(),
      throwsA(
        isA<PostApiException>().having(
          (error) => error.message,
          'message',
          contains('internet connection'),
        ),
      ),
    );
  });

  test('GET reports a timeout', () async {
    final api = PostApi(
      client: MockClient((_) async => throw TimeoutException('slow')),
    );
    await expectLater(
      api.fetchPosts(),
      throwsA(
        isA<PostApiException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });

  test(
    'POST sends trimmed JSON with its content type and parses HTTP 201',
    () async {
      final api = PostApi(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), PostApi.endpoint);
          expect(request.headers['content-type'], contains('application/json'));
          expect(jsonDecode(request.body), {
            'title': 'New thought',
            'body': 'Some words',
            'userId': 1,
          });
          return http.Response(
            jsonEncode({
              'id': 101,
              'title': 'New thought',
              'body': 'Some words',
            }),
            201,
          );
        }),
      );
      final post = await api.createPost(
        title: '  New thought  ',
        body: ' Some words ',
      );
      expect(post.id, 101);
      expect(post.title, 'New thought');
    },
  );

  test('POST rejects blank fields without sending a request', () async {
    final api = PostApi(
      client: MockClient((_) async => fail('No HTTP request expected')),
    );
    await expectLater(
      api.createPost(title: ' ', body: 'Body'),
      throwsA(isA<PostApiException>()),
    );
    await expectLater(
      api.createPost(title: 'Title', body: '\n'),
      throwsA(isA<PostApiException>()),
    );
  });

  test('POST reports an unsuccessful status', () async {
    final api = PostApi(
      client: MockClient((_) async => http.Response('', 400)),
    );
    await expectLater(
      api.createPost(title: 'Title', body: 'Body'),
      throwsA(
        isA<PostApiException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 400'),
        ),
      ),
    );
  });

  test('POST reports invalid response data', () async {
    final api = PostApi(
      client: MockClient((_) async => http.Response('{}', 201)),
    );
    await expectLater(
      api.createPost(title: 'Title', body: 'Body'),
      throwsA(
        isA<PostApiException>().having(
          (error) => error.message,
          'message',
          contains('invalid creation response'),
        ),
      ),
    );
  });

  test('POST reports connection failures', () async {
    final api = PostApi(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      api.createPost(title: 'Title', body: 'Body'),
      throwsA(
        isA<PostApiException>().having(
          (error) => error.message,
          'message',
          contains('internet connection'),
        ),
      ),
    );
  });

  test('POST reports a timeout', () async {
    final api = PostApi(
      client: MockClient((_) async => throw TimeoutException('slow')),
    );
    await expectLater(
      api.createPost(title: 'Title', body: 'Body'),
      throwsA(
        isA<PostApiException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}
