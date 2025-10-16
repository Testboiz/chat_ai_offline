import 'package:chat_ai_offline/chat.dart';
import 'package:chat_ai_offline/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import "package:timeago/timeago.dart" as timeago;

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({super.key});

  static String routeName = 'ChatList';
  static String routePath = '/chatList';

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Map<String, dynamic>>> chatData;

  Future<List<Map<String, dynamic>>> _getData() async {
    final db = await DatabaseHelper().database;
    return await db.rawQuery("""
WITH latest AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY chat_id ORDER BY created_at DESC) AS rn
  FROM chat_messages
)
SELECT 
  p.chat_id AS chat_id,
  p.chat_name,
  c.message_text,
  COALESCE(c.created_at, p.created_at)  AS last_chat_at
FROM chats p
LEFT JOIN latest c
  ON p.chat_id = c.chat_id AND c.rn = 1;
    """);
  }

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages("id_short", timeago.IdShortMessages());
    setState(() {
      chatData = _getData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      chatData = _getData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var uuid = Uuid();
          String id = uuid.v4();
          var db = await DatabaseHelper().database;
          try {
            await db.insert("chats", {
              'chat_id': id,
              'chat_name': "New Chat",
            });
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Something Went Wrong"),
                ),
              );
            }
          }
          if (context.mounted) {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => ChatWidget(id: id),
                  ),
                )
                .then((_) => _loadData());
          }
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
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['gguf'],
                              );
                              if (result != null) {
                                final filePath = result.files.single.path!;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString('modelPath', filePath);
                                if (alertDialogContext.mounted) {
                                  Navigator.pop(alertDialogContext, true);
                                }
                              }
                            },
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: chatData,
          builder:
              (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child:
                    Text('Belum ada chat, Ayo kita chat dengan klik tombol +'),
              );
            }
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  var chatData = data[index];
                  return Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) => ChatWidget(
                                  id: chatData["chat_id"],
                                ),
                              ),
                            )
                            .then((_) => _loadData());
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
                                  chatData["chat_name"] as String,
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
                                chatData["message_text"] ?? "",
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
                                    timeago.format(
                                        DateTime.parse(
                                            chatData["last_chat_at"]),
                                        locale: "id_short"),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
