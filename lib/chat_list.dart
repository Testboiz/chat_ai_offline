import 'dart:io';
import 'dart:typed_data';

import 'package:chat_ai_offline/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({super.key});

  static String routeName = 'ChatList';
  static String routePath = '/chatList';

  Future<Database> _openDb() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "chat_database.db");

    // delete existing if any
    // delete after testing abcde
    await deleteDatabase(path);

    // Make sure the parent directory exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Copy from asset
    ByteData data =
        await rootBundle.load(url.join("assets", "db", "chat_database.db"));
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);

    // open the database
    return openDatabase(path);
  }

  Future<List<Map<String, dynamic>>> _getData() async {
    final db = await _openDb();
    return await db.query('chats');
  }

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ignore: slash_for_doc_comments
  /**
   * Backlog
   * TODO : Refactor colors and repeating components
   * TODO : Turn the list to some ListView
   * TODO : Integrate to SQLite DB
   * TODO : Make change model button work
   */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => ChatWidget()));
        },
        backgroundColor: const Color.fromARGB(255, 75, 57, 239),
        elevation: 8,
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 57, 239),
        automaticallyImplyLeading: false,
        title: Text(
          'Daftar Chat',
          style: TextStyle(
            fontFamily: "Inter",
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size.fromRadius(40),
              backgroundColor: const Color.fromARGB(255, 75, 57, 239),
            ),
            icon: Icon(
              Icons.settings_suggest,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () async {
              await showDialog(
                    context: context,
                    builder: (alertDialogContext) {
                      return AlertDialog(
                        title: Text('Pilih Model Baru'),
                        backgroundColor: Colors.white,
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(alertDialogContext, false),
                            child: Text(
                              'Batal',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(alertDialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 75, 57, 239),
                            ),
                            child: Text(
                              'Pilih',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;
            },
          ),
        ],
        centerTitle: false,
        elevation: 2,
      ),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget._getData(),
            builder:
                (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No data'));
              }
              final data = snapshot.data!;
              print(data[0]["chat_name"]);
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatWidget(),
                          ),
                        );
                      },
                      child: Card(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(5, 5, 5, 5),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    EdgeInsetsDirectional.fromSTEB(0, 0, 0, 2),
                                child: Text(
                                  data[index]["chat_name"] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum dolor sit amet,',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: "Inter",
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(1, 0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 5, 0, 0),
                                  child: Text(
                                    data[index]["last_chat_at"] as String,
                                    style: TextStyle(
                                      fontFamily: "Inter",
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
