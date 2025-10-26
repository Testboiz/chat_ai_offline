import 'package:chat_ai_offline/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/database_mock.mocks.dart';
import 'mocks/llama_mock.mocks.dart';
import 'mocks/sqlite_database_mock.mocks.dart';

void main() {
  testWidgets("Tampilan Chat jika terisi memiliki chat dari Assistant dan User",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'modelPath': '/path/to/model'});

    MockDatabaseHelper mockDatabaseHelper = MockDatabaseHelper();
    MockDatabase sqlitedb = MockDatabase();
    MockLlamaController mockLlamaController = MockLlamaController();
    when(mockDatabaseHelper.database).thenAnswer((_) async => sqlitedb);
    when(sqlitedb.insert('', {})).thenAnswer((_) async => 1);
    when(sqlitedb.query(any,
            orderBy: anyNamed("orderBy"),
            where: anyNamed("where"),
            whereArgs: anyNamed("whereArgs")))
        .thenAnswer((_) async => [
              {
                'message_id': "1",
                'message_text': "lorem",
                'chat_name': "lorem ipsum",
                'role': "user",
                'chat_id': "1",
                'created_at': DateTime.now()
                    .toIso8601String()
                    .split('.')
                    .first
                    .replaceFirst('T', ' '),
              },
              {
                'message_id': "2",
                'message_text': "ipsum",
                'chat_name': "lorem ipsum",
                'role': "assistant",
                'chat_id': "1",
                'created_at': DateTime.now()
                    .toIso8601String()
                    .split('.')
                    .first
                    .replaceFirst('T', ' '),
              },
            ]);
    when(mockLlamaController.isModelLoaded()).thenAnswer((_) async => true);

    await tester.pumpWidget(MaterialApp(
      home: ChatWidget(
        id: "fake-id",
        databaseHelper: mockDatabaseHelper,
        controller: mockLlamaController,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text("Assistant"), findsOne);
    expect(find.text("User"), findsOne);
  });
  testWidgets(
      "Tombol Send mengirim pesan ke model LLM dan menghasilkan assistantChatBubble",
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

    expect(find.text("Assistant"), findsOne);
  });

  testWidgets("Tombol Edit Chat mengedit tampilan ChatWidget ",
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
