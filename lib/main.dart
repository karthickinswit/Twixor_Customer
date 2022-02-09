import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twixor_customer/chatDetailPage.dart';

import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'API/apidata-service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper_files/FileReader.dart';
import 'helper_files/Websocket.dart';
import 'helper_files/utilities_files.dart';
import 'models/chatMessageModel.dart';

void main() {
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  //CustomerApp(this.eId, this.customerId);
  const CustomerApp({Key? key}) : super(key: key);

  @override

  // This widget is the root of your application.
  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twixor',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Twixor Customer Chat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool isLoading = false;
  bool isVisible = true;
  late String userDetails;
  String? ChatId;
  late SharedPreferences prefs;
  bool allowStorage = false;
  List<String>? chatIds = [];
  List<ChatUsers> chatUsers = [];

  @override
  initState() {
    // TODO: implement initState

    //getApiPref();
    getPref();
    super.initState();
    configLoading();

    //
  }

  getPref() async {
    // getApiPref();
    if (authToken == null || authToken == "") {
      var token = await getTokenApi();
      // print(token);
    }
  }

  void _incrementCounter() async {
    //getChatUserInfo();
    isLoading = true;
    isVisible = false;
    if (!allowStorage) {
      requestWritePermission();
    }

    if (true) {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      var chatId = await newChatCreate(context);
      // chatIds!.add(chatId);
      // prefs.setStringList('chatIds', chatIds!);
      // print(prefs?.getStringList("chatIds"));
      ChatId = chatId;
      print("new Chat Id ${ChatId}");
    }
    if (ChatId != null) {
      ChatId != null
          ? userDetails = json.encode(await getChatUserInfo(context, ChatId!))
          : ErrorAlert(context, "Chat Id is not present here");

      isLoading = false;
      isVisible = true;

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatDetailPage(userDetails, "")));
    } else {
      ErrorAlert(context, "UserDetails Not Present");
      ChatId = await newChatCreate(context);
      _incrementCounter();
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return WillPopScope(
        onWillPop: () async {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('The System Back Button is Deactivated')));
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(widget.title),
          ),
          body: isLoading
              ? //check loadind status
              Center(child: CircularProgressIndicator())
              :
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Invoke "debug painting" (press "p" in the console, choose the
              // "Toggle Debug Paint" action from the Flutter Inspector in Android
              // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
              // to see the wireframe for each widget.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).

              Container(
                  child: FutureBuilder(
                      builder: (context, snapshot) {
                        print("snapChat data -> ${snapshot.data.toString()}");
                        if (snapshot.hasData) {
                          chatUsers = snapshot.data as List<ChatUsers>;
                          List<ChatUsers> chatUsers1 = [];
                          //print('receiver data -> $chatUsers');

                          chatUsers.forEach((element) {
                            if (element.state != "0") {
                              chatUsers1.add(element);
                            }
                          });
                          chatUsers = chatUsers1;

                          print("${chatUsers.toString()}" +
                              " ${chatUsers.length}");

                          return chatUsers.length == 0
                              ? Center(
                                  child:
                                      Text("There are no more Active Chats "))
                              : ListView.builder(
                                  itemCount: chatUsers.length,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.only(top: 10),
                                  itemBuilder: (context1, index) {
                                    // print(chatUsers[index].chatId);
                                    if (chatUsers.length == 0)
                                      return Center(
                                          child:
                                              Text("There is no Chats Found "));
                                    else if (chatUsers[index].state != "0") {
                                      return GestureDetector(
                                        onTap: () async {
                                          userDetails = json.encode(
                                              await getChatUserInfo(
                                                  context,
                                                  chatUsers[index]
                                                      .chatId
                                                      .toString()));

                                          isLoading = false;
                                          isVisible = true;

                                          Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          ChatDetailPage(
                                                              userDetails, "")))
                                              .then((x) {
                                            setState(() {});
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Row(
                                                  children: <Widget>[
                                                    CircleAvatar(
                                                      backgroundImage: NetworkImage(
                                                          "https://aim.twixor.com/drive/docs/61ef9d425d9c400b3c6c03f9"),
                                                      maxRadius: 30,
                                                    ),
                                                    SizedBox(
                                                      width: 16,
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        color:
                                                            Colors.transparent,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Text(
                                                              chatUsers[index]
                                                                  .chatId
                                                                  .toString(),
                                                              style: TextStyle(
                                                                  fontSize: 16),
                                                            ),
                                                            SizedBox(
                                                              height: 6,
                                                            ),
                                                            Text(
                                                              chatUsers[index]
                                                                  .eId
                                                                  .toString(),
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Text(
                                              //   "ConvertTime(chatUsers[index].time.toString())",
                                              //   style: const TextStyle(
                                              //       fontSize: 12,
                                              //       fontWeight: FontWeight.normal),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      );
                                      ///////////////////////////////
                                    } else
                                      return Container();
                                  },
                                );
                        } else
                          return Center(child: CircularProgressIndicator());
                      },
                      future: getChatList(context)),
                ),
          floatingActionButton:
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            Visibility(
              visible: isVisible,
              child: new FloatingActionButton(
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: const Icon(
                  IconData(0xf8b8, fontFamily: 'MaterialIcons'),
                ),
              ), // This trailing comma makes auto-formatting nicer for build methods.
            ),
            SizedBox(width: 10),
          ]),
        ));
  }

  requestWritePermission() async {
    PermissionStatus permissionStatus =
        await Permission.manageExternalStorage.status;
    if (permissionStatus.isGranted) {
      allowStorage = true;
    } else
      Permission.manageExternalStorage.request();
  }
}
