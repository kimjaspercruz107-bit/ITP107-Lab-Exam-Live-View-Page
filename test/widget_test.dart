import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/screens/posts_screen.dart';
import 'package:flutter_application_1/services/post_api.dart';

const postData = {
  'id': 7,
  'title': 'A good read',
  'body': 'A thoughtful body.',
};

void main() {
  late Directory storageDirectory;
  late Box<Map> box;

  setUp(() async {
    storageDirectory = await Directory.systemTemp.createTemp(
      'post_reader_test_',
    );
    Hive.init(storageDirectory.path);
    box = await Hive.openBox<Map>('favoritesBox');
  });

  tearDown(() async {
    await Hive.close();
    final temporaryRoot =
        '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}';
    if (!storageDirectory.absolute.path.startsWith(
      '${temporaryRoot}post_reader_test_',
    )) {
      throw StateError(
        'Refusing to clean up a directory outside the test temporary directory.',
      );
    }
    await storageDirectory.delete(recursive: true);
  });

  PostApi apiFor(http.Response Function(http.Request) response) =>
      PostApi(client: MockClient((request) async => response(request)));

  Future<void> startApp(WidgetTester tester, {PostApi? api}) async {
    await tester.pumpWidget(
      PostReaderApp(
        favoritesBox: box,
        api: api ?? apiFor((_) => http.Response(jsonEncode([postData]), 200)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapStorageAction(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await box.flush();
    });
    await tester.pumpAndSettle();
  }

  testWidgets('named routes, favorite CRUD, and persistence work together', (
    tester,
  ) async {
    await startApp(tester);
    expect(find.text('A good read'), findsOneWidget);
    await tester.tap(find.text('A good read'));
    await tester.pumpAndSettle();
    expect(find.text('Post Details'), findsOneWidget);
    expect(find.text('A thoughtful body.'), findsOneWidget);

    await tapStorageAction(tester, find.text('Save to Favorites'));
    expect(box.length, 1);
    expect(box.get(7)?['title'], 'A good read');
    expect(find.text('Saved to Favorites'), findsOneWidget);
    final savedButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Saved to Favorites'),
    );
    expect(savedButton.onPressed, isNull);

    await tester.tap(find.byTooltip('Open favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Read this again tomorrow.');
    await tapStorageAction(tester, find.text('Save note'));
    expect(box.get(7)?['note'], 'Read this again tomorrow.');
    expect(find.text('Read this again tomorrow.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await box.close();
      box = await Hive.openBox<Map>('favoritesBox');
    });
    expect(box.length, 1);
    expect(box.get(7)?['note'], 'Read this again tomorrow.');
    await startApp(tester);
    await tester.tap(find.byTooltip('Open favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Read this again tomorrow.'), findsOneWidget);

    await tester.tap(find.text('Edit note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tapStorageAction(tester, find.text('Save note'));
    expect(box.get(7)?['note'], '');

    await tapStorageAction(tester, find.byTooltip('Remove favorite'));
    expect(box.isEmpty, isTrue);
    expect(find.text('Save your first favorite'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await box.close();
      box = await Hive.openBox<Map>('favoritesBox');
    });
    expect(box.isEmpty, isTrue);
  });

  testWidgets('load error is visible and retry fetches posts', (tester) async {
    var requests = 0;
    await startApp(
      tester,
      api: apiFor((_) {
        requests++;
        return requests == 1
            ? http.Response('', 503)
            : http.Response(jsonEncode([postData]), 200);
      }),
    );
    expect(find.textContaining('HTTP 503'), findsOneWidget);
    await tester.ensureVisible(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('A good read'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets(
    'new-post dialog validates, preserves failed drafts, and shows success',
    (tester) async {
      var submissions = 0;
      await startApp(
        tester,
        api: apiFor((request) {
          if (request.method == 'GET') {
            return http.Response(jsonEncode([postData]), 200);
          }
          submissions++;
          if (submissions == 1) return http.Response('', 500);
          return http.Response(
            jsonEncode({
              'id': 101,
              'title': 'My new post',
              'body': 'A new thought.',
            }),
            201,
          );
        }),
      );
      await tester.tap(find.text('New post'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send post'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a title.'), findsOneWidget);
      expect(find.text('Please enter a body.'), findsOneWidget);
      expect(submissions, 0);

      await tester.enterText(find.byType(TextFormField).at(0), 'My new post');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'A new thought.',
      );
      await tester.tap(find.text('Send post'));
      await tester.pumpAndSettle();
      expect(find.textContaining('HTTP 500'), findsOneWidget);
      expect(find.text('My new post'), findsOneWidget);
      await tester.tap(find.text('Send post'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Post #101 created (HTTP 201)'), findsOneWidget);
      expect(find.text('My new post'), findsOneWidget);
      expect(submissions, 2);
    },
  );

  testWidgets('search filters posts and shows a useful empty state', (
    tester,
  ) async {
    await startApp(tester);
    await tester.enterText(find.byType(TextField), 'unmatched');
    await tester.pumpAndSettle();
    expect(find.text('No matching posts'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'thoughtful');
    await tester.pumpAndSettle();
    expect(find.text('A good read'), findsOneWidget);
  });

  testWidgets('favorites remain readable when the posts API is offline', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await box.put(7, {...postData, 'note': 'Kept offline.'});
    });
    await startApp(tester, api: apiFor((_) => http.Response('', 503)));
    await tester.tap(find.byTooltip('Open favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Kept offline.'), findsOneWidget);
    await tester.tap(find.text('A good read'));
    await tester.pumpAndSettle();
    expect(find.text('A thoughtful body.'), findsOneWidget);
    expect(find.text('Saved to Favorites'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to posts'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(PostsScreen), findsOneWidget);
  });

  testWidgets('narrow screens display the reading layout without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await startApp(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('A good read'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A good read'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Post Details'), findsOneWidget);
  });
}
