import 'dart:async';

import 'package:chat_ai_offline/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget(
      {super.key,
      required this.id,
      required this.databaseHelper,
      required this.controller});
  final DatabaseHelper databaseHelper;
  final LlamaController controller;

  static String routeName = 'Chat';
  static String routePath = '/chat';

  final String id;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  TextEditingController messageController = TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription? subscription;
  // final controller = LlamaController();
  late final Database db;
  late final Uuid uuid;
  var title = "Chat";
  bool sendDisable = true;

  void _getData() async {
    final db = await widget.databaseHelper.database;
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

  void initializeChat() async {
    var prefs = await SharedPreferences.getInstance();
    var filePath = prefs.get("modelPath") as String;
    var database = await widget.databaseHelper.database;

    const generator = Uuid();
    bool isModelLoaded = await widget.controller.isModelLoaded();

    if (!isModelLoaded) {
      await widget.controller
          .loadModel(modelPath: filePath, contextSize: 1024, gpuLayers: 1);
    }

    setState(() {
      sendDisable = false;
      db = database;
      uuid = generator;
    });
  }

  void chatButtonOnPressed() async {
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
    chat(messageController.text);
    messageController.clear();
  }

  Future<void> chat(String message) async {
    final completer = Completer<void>();

    String id = uuid.v4();

    final aiChatMessage = {
      'message_id': id,
      'message_text': "",
      'role': "assistant",
      'chat_id': widget.id,
      'created_at': DateTime.now()
          .toIso8601String()
          .split('.')
          .first
          .replaceFirst('T', ' '),
    };
    setState(() {
      _messages.add(aiChatMessage);
      sendDisable = true;
    });
    int index = _messages.indexWhere((message) => message['message_id'] == id);

    subscription = widget.controller
        .generate(
      prompt: message,
      maxTokens: 64,
      temperature: 0.7,
    )
        .listen(
      (token) {
        setState(() {
          _messages[index]["message_text"] += token;
        });
      },
      onError: (error) {
        setState(() {
          sendDisable = false;
        });
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () async {
        setState(() {
          sendDisable = false;
        });
        await db.insert("chat_messages", aiChatMessage);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    await completer.future;

    setState(() {
      sendDisable = false;
    });
  }

  void chatButtonPressed() async {
    setState(() {
      sendDisable = true;
    });
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
    await chat(messageController.text);
    messageController.clear();
    setState(() {
      sendDisable = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _getData();
    initializeChat();
  }

  @override
  void dispose() {
    widget.controller.stop();
    subscription?.cancel();
    widget.controller.dispose();
    db.insert("chat_messages", aiChatMessage);

    super.dispose();
  }

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
                          var db = await widget.databaseHelper.database;
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
                        sendDisable ? Icons.hourglass_bottom : Icons.send,
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
                      onPressed: sendDisable ? null : chatButtonOnPressed,
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
