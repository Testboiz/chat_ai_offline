import 'package:chat_ai_offline/chat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_ai_offline/chat_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/database_mock.mocks.dart';
import 'mocks/sqlite_database_mock.mocks.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockDatabaseFactory extends Mock implements DatabaseFactory {}

class FakeFilePickerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FilePicker {
  FilePickerResult? _stubbedResult;

  void setPickerResult(FilePickerResult? result) {
    _stubbedResult = result;
  }

  Map<String, dynamic>? lastCallArgs;

  @override
  Future<FilePickerResult?> pickFiles({
    bool allowCompression = true,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    int compressionQuality = 20,
    String? dialogTitle,
    String? initialDirectory,
    bool lockParentWindow = false,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool readSequential = false,
    FileType type = FileType.any,
    bool withData = false,
    bool withReadStream = false,
  }) async {
    final fakeFile = PlatformFile(
      name: 'model.gguf',
      size: 1024,
      path: '/new/fake/path/model.gguf',
    );
    _stubbedResult = FilePickerResult([fakeFile]);
    return _stubbedResult;
  }
}

void main() {
  late MockNavigatorObserver mockObserver;
  late FakeFilePickerPlatform fakePicker;

  setUp(() {
    fakePicker = FakeFilePickerPlatform();
    mockObserver = MockNavigatorObserver();
    FilePicker.platform = fakePicker;
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;
  });

  testWidgets("Tombol + pada daftar chat membuat chat baru",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'modelPath': '/path/to/model'});

    MockDatabaseHelper database = MockDatabaseHelper();
    MockDatabase sqlitedb = MockDatabase();
    when(database.database).thenAnswer((_) async => sqlitedb);
    when(sqlitedb.insert('', {})).thenAnswer((_) async => 1);

    await tester.pumpWidget(MaterialApp(
      home: ChatListWidget(
        dbHelper: database,
      ),
      navigatorObservers: [mockObserver],
    ));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(ChatWidget), findsOneWidget);
  });

  testWidgets("Tombol pada top bar halaman chat mengubah model",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'modelPath': '/path/to/model'});
    MockDatabaseHelper database = MockDatabaseHelper();

    await tester.pumpWidget(MaterialApp(
      home: ChatListWidget(
        dbHelper: database,
      ),
      navigatorObservers: [mockObserver],
    ));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('modelPath'), '/new/fake/path/model.gguf');
  });
}
