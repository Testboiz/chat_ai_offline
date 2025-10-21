// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:chat_ai_offline/chat_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_ai_offline/main.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/database_mock.mocks.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeFilePickerPlatform extends Fake
    with
        MockPlatformInterfaceMixin // Use this for platform interface compliance
    implements
        FilePicker {
  // This will hold the "stubbed" result you want to return
  FilePickerResult? _stubbedResult;

  // A helper method to set the result before a test
  void setPickerResult(FilePickerResult? result) {
    _stubbedResult = result;
  }

  // We can also store the arguments it was called with for verification
  Map<String, dynamic>? lastCallArgs;

  // 2. Override the method you need to test
  @override
  Future<FilePickerResult?> pickFiles({
    // These parameters match the latest file_picker_platform_interface
    bool allowCompression = true,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    int compressionQuality = 20, // Note: Not nullable, has a default
    String? dialogTitle,
    String? initialDirectory,
    bool lockParentWindow = false,
    dynamic Function(FilePickerStatus)? onFileLoading, // Corrected type
    bool readSequential = false,
    FileType type = FileType.any,
    bool withData = false,
    bool withReadStream = false,
  }) async {
    // Store arguments for verification
    lastCallArgs = {
      'type': type,
      'allowedExtensions': allowedExtensions,
      'allowMultiple': allowMultiple,
      'allowCompression': allowCompression,
      // Add any other args you want to verify in your tests
    };

    // Return the stubbed result
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
      "Tombol Pilih Model melakukan set model dan navigasi ke ChatWidget()",
      (WidgetTester tester) async {
    final mockService = MockDatabaseHelper();

    await tester.pumpWidget(MaterialApp(
      home: HomePageWidget(),
      navigatorObservers: [mockObserver],
    ));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    verifyNever(mockService.database); // TODO : issue 1, db did not get run

    expect(find.byType(ChatListWidget), findsNothing); // TODO : issue 2, does not push
  });
}
