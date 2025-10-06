import 'package:chat_ai_offline/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key, required this.id});

  static String routeName = 'Chat';
  static String routePath = '/chat';

  final String id;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _messages = [];
  var title = "Chat";

  void _getData() async {
    final db = await DatabaseHelper().database;
    var queryData = await db.query('chat_messages',
        orderBy: "created_at ASC",
        where: "chat_id = ?",
        whereArgs: [widget.id]);

    var tableInfo =
        await db.query('chats', where: "chat_id = ?", whereArgs: [widget.id]);

    setState(() {
      _messages.addAll(queryData);
      title = tableInfo[0]["chat_name"] as String;
    });
  }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ignore: slash_for_doc_comments
  /**
   * Backlog
   * TODO : (optional) add streaming
   * TODO : Make Edit chat, and send button work
   */

  Widget assistantChatBubble(String message) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(15, 5, 5, 5),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(5, 5, 5, 5),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional(1, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 2),
                  child: Text(
                    'Assistant',
                    style: TextStyle(
                      fontFamily: "Inter",
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Text(
                message,
                style: TextStyle(
                  fontFamily: "Inter",
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget userChatBubble(String message) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(5, 5, 15, 5),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: Colors.white,
        elevation: 5,
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
                padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 2),
                child: Text(
                  'User',
                  style: TextStyle(
                    fontFamily: "Inter",
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                message,
                style: TextStyle(
                  fontFamily: "Inter",
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController messageController = TextEditingController();
    TextEditingController titleController = TextEditingController(text: title);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 57, 239),
        automaticallyImplyLeading: false,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: "Inter", // tight
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size.fromRadius(40),
              backgroundColor: const Color.fromARGB(255, 75, 57, 239),
            ),
            onPressed: () async {
              return showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Edit Judul Chat'),
                    backgroundColor: Colors.white,
                    content: TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Judul Baru",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 75, 57, 239),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 75, 57, 239),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 255, 89, 100),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 255, 89, 100),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 75, 57, 239),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          var db = await DatabaseHelper().database;
                          await db.update(
                              "chats", {'chat_name': titleController.text},
                              where: "chat_id = ?", whereArgs: [widget.id]);
                          setState(() {
                            title = titleController.text;
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        centerTitle: false,
        elevation: 2,
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg["role"] == "assistant") {
                    return assistantChatBubble(msg["message_text"]);
                  } else {
                    return userChatBubble(msg["message_text"]);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional(0, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: messageController,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            isDense: true,
                            labelStyle: TextStyle(
                              fontFamily: "Inter",
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w400,
                            ),
                            hintText: 'Bercakap dengan AI',
                            hintStyle: TextStyle(
                              fontFamily: "Inter",
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w400,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 75, 57, 239),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 75, 57, 239),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 255, 89, 100),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 255, 89, 100),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: TextStyle(
                            fontFamily: "Inter",
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          cursorColor: const Color.fromARGB(255, 75, 57, 239),
                          enableInteractiveSelection: true,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        minimumSize: const Size.fromRadius(30),
                        backgroundColor: const Color.fromARGB(255, 75, 57, 239),
                      ),
                      onPressed: () async {
                        var db = await DatabaseHelper().database;

                        const uuid = Uuid();
                        String id = uuid.v4();
                        Map<String, String> userChatMessage = {
                          'message_id': id,
                          'message_text': messageController.text,
                          'role': "user",
                          'chat_id': widget.id,
                          'created_at': DateTime.now()
                              .toIso8601String()
                              .split('.')
                              .first
                              .replaceFirst('T', ' '),
                        };
                        setState(() {
                          _messages.add(userChatMessage);
                        });
                        await db.insert("chat_messages", userChatMessage);
                        messageController.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
