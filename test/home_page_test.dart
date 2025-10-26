// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:chat_ai_offline/chat_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_ai_offline/main.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

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
      path: '/fake/path/model.gguf',
    );
    _stubbedResult = FilePickerResult([fakeFile]);
    return _stubbedResult;
  }
}

void main() {
  late FakeFilePickerPlatform fakePicker;
  late MockNavigatorObserver mockObserver;

  setUp(() {
    fakePicker = FakeFilePickerPlatform();
    mockObserver = MockNavigatorObserver();
    FilePicker.platform = fakePicker;
    SharedPreferences.setMockInitialValues({});
  });
  test('Tampilan awal pada pembukaan aplikasi adalah HomePageWidget()',
      () async {
    SharedPreferences.setMockInitialValues({});
    final route = await getInitialRoute();
    expect(route, '/home');
  });

  test('Tampilan awal jika telah memilih model adalah ChatListWidget()',
      () async {
    SharedPreferences.setMockInitialValues({'modelPath': '/path/to/model'});
    final route = await getInitialRoute();
    expect(route, '/chat_list');
  });

  testWidgets(
      "Tombol Pilih Model melakukan set model dan navigasi ke ChatListWidget()",
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomePageWidget(),
      navigatorObservers: [mockObserver],
    ));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('modelPath'), '/fake/path/model.gguf');
    expect(find.byType(ChatListWidget), findsOneWidget);
  });
}
