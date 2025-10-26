import 'package:chat_ai_offline/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/database_mock.mocks.dart';
import 'mocks/llama_mock.mocks.dart';
import 'mocks/sqlite_database_mock.mocks.dart';

void main() {
  testWidgets("Tombol Send mengirim chat pada laman chat",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'modelPath': '/path/to/model'});

    MockDatabaseHelper mockDatabaseHelper = MockDatabaseHelper();
    MockDatabase sqlitedb = MockDatabase();
    MockLlamaController mockLlamaController = MockLlamaController();
    when(mockDatabaseHelper.database).thenAnswer((_) async => sqlitedb);
    when(sqlitedb.insert('', {})).thenAnswer((_) async => 1);
    when(mockLlamaController.isModelLoaded()).thenAnswer((_) async => true);
    when(
      mockLlamaController.generate(
        prompt: anyNamed('prompt'),
        maxTokens: anyNamed('maxTokens'),
        temperature: anyNamed('temperature'),
      ),
    ).thenAnswer((_) {
      final stream = Stream<String>.fromIterable(['Hello', ' ', 'world']);
      return stream;
    });
    when(
      sqlitedb.query(
        'chats',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      ),
    ).thenAnswer((_) async => [
          {'chat_id': 1, 'chat_name': 'Test Chat'}
        ]);

    await tester.pumpWidget(MaterialApp(
      home: ChatWidget(
        id: "fake-id",
        databaseHelper: mockDatabaseHelper,
        controller: mockLlamaController,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "Hello");
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text("User"), findsOne);
    expect(find.text("Assistant"), findsOne);
  });

  testWidgets("Tombol pada top bar halaman chat dapat mengedit judul chat",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'modelPath': '/path/to/model'});

    MockDatabaseHelper mockDatabaseHelper = MockDatabaseHelper();
    MockDatabase sqlitedb = MockDatabase();
    MockLlamaController mockLlamaController = MockLlamaController();

    when(mockDatabaseHelper.database).thenAnswer((_) async => sqlitedb);
    when(sqlitedb.insert('', {})).thenAnswer((_) async => 1);
    when(mockLlamaController.isModelLoaded()).thenAnswer((_) async => true);
    when(
      sqlitedb.query(
        'chats',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      ),
    ).thenAnswer((_) async => [
          {'chat_id': 1, 'chat_name': 'Test Chat'}
        ]);
    when(sqlitedb.update(any, any,
            where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
        .thenAnswer((_) async => 1);
    await tester.pumpWidget(MaterialApp(
      home: ChatWidget(
        id: "fake-id",
        databaseHelper: mockDatabaseHelper,
        controller: mockLlamaController,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        "new title");
    await tester.tap(find.byType(ElevatedButton));

    expect(find.text("new title"), findsAny);
  });
}
