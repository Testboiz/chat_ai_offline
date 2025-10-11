import 'package:chat_ai_offline/chat_list.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final filePath = prefs.getString('tflitePath');
  runApp(MyApp(initialRoute: filePath == null ? '/home' : '/chat_list'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: {
        '/home': (_) => HomePageWidget(),
        '/chat_list': (_) => ChatListWidget(),
      },
    );
  }
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      // allowedExtensions: ['task'],
    );
    if (result != null) {
      final filePath = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tflitePath', filePath);
      if (mounted) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => ChatListWidget()));
      }
    }
  }

  // ignore: slash_for_doc_comments
  /**
   * Backlog
   * TODO : Add ggml library
   */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 57, 239),
        automaticallyImplyLeading: false,
        title: Text(
          'Model Selection',
          style: TextStyle(
            fontFamily: "Inter",
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 2,
      ),
      body: SafeArea(
        top: true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional(0, 0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                child: Text(
                  'Pilih model .gguf untuk Chat AI test',
                  style: TextStyle(
                    fontFamily: "Inter",
                    letterSpacing: 0.0,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: pickFile,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                backgroundColor: const Color.fromARGB(255, 75, 57, 239),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Pilih Model",
                style: TextStyle(
                  fontFamily: "Inter",
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
