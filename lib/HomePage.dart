import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:twixor_customer/chatDetailPage.dart';
import 'package:twixor_customer/models/SavedDataModel.dart';

import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'API/apidata-service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper_files/Websocket.dart';
import 'helper_files/utilities_files.dart';
import 'models/SocketResponseModel.dart';
import 'models/chatMessageModel.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  // final String customerId1;
  // final String eId1;
  // final String title;

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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  String? customerId1;
  String? eId1;
  String? mainPageTitle;
  bool isLoading = false;
  StreamSubscription? chatListSubscription;

  late String userDetails;

  String? ChatId;
  late SharedPreferences prefs;
  bool allowStorage = false;
  List<String>? chatIds = [];

  // WebsocketsProvider wsProvider = new WebsocketsProvider();

  final List<TextEditingController> _notifyControllers = [];

  _MyHomePageState();

  @override
  initState() {
    pref();
    super.initState();
    configLoading();

    //getSubscribe();
    // if (wsProvider.srMessage != null) {
    //   print(wsProvider.srMessage!.toJson().toString());
    // }

    //
  }

  pref() async {
    prefs = await SharedPreferences.getInstance();
    //prefs.setString('title', mainPageTitle);
    MainPageTitle = prefs.getString('title')!;
    chatCreationTime = DateTime.parse(prefs.getString('chatCreationTime')!);

    // if (mainSocket.hasListener) {
    // chatListSubscription = getSubscribe();
    //print("chatListSubscription prefs ${chatListSubscription.hashCode}");
    //getSubscribe();
    //socketMsgReceiveMain();
    print("Resume Socket Main Page");
  }

  checkClick() {
    //canCreateChat = true;
    print("Cancreate when CLick ${canCreateChat} ");
    if (canCreateChat) {
      canCreateChat = false;
      initiateChat();
    } else {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Dialog(
              child: Container(
                height: 50,
                width: 120,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    // Icon(
                    //     IconData(0xe8ac,
                    //         fontFamily: 'MaterialIcons'),
                    //     color: Colors.red),
                    SizedBox(
                      width: 40,
                    ),
                    Text(
                      "Cannot create new chat now!",
                      textScaleFactor: 1.0,
                    ),
                  ],
                ),
              ),
            );
          });
      return;
    }
  }

  void initiateChat() async {
    //getChatUserInfo();

    if (!allowStorage) {
      requestWritePermission();
    }

    // if (isSocketConnection) {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    BuildContext loadingContext;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          loadingContext = context;
          return Dialog(
            child: Container(
              height: 50,
              width: 120,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // Icon(
                  //     IconData(0xe8ac,
                  //         fontFamily: 'MaterialIcons'),
                  //     color: Colors.red),
                  SizedBox(
                    width: 10,
                  ),
                  CircularProgressIndicator(),
                  Text(
                    "Please wait for creating new Chat!",
                    textScaleFactor: 1.0,
                  ),
                ],
              ),
            ),
          );
        });
    var chatId = await newChatCreate();
    canCreateChat = false;

    // chatIds!.add(chatId);
    // prefs.setStringList('chatIds', chatIds!);
    // print(prefs?.getStringList("chatIds"));
    ChatId = chatId;
    print("new Chat Id $ChatId");

    if (ChatId != null) {
      ChatId != null
          ? userChatId = ChatId!
          : ErrorAlert(alertContext, "Chat Id is not present here");

      isLoading = false;
      // mainSubscription!.pause();

      // Navigator.pushAndRemoveUntil<dynamic>(
      //   context,
      //   MaterialPageRoute<dynamic>(
      //     builder: (BuildContext context) => ChatDetailPage(userDetails, ""),
      //   ),
      //   (route) => false, //if you want to disable back feature set to false
      // );
      //  if (strmControl.hasListener) {}
      // chatListSubscription!.cancel();
      // messages!.value = [];
      if (await getChatUserInfo(ChatId!)) {
        // messages!.value = chatUser!.value.messages!;
        messages!.value = [];
        prefs.setString('chatId', chatUser!.value.chatId!);

        // print(chatUser!.value.toJson());
        // await SocketConnect();
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatDetailPage(userChatId, "")));
      }
    } else {
      ErrorAlert(context, "UserDetails Not Present");
      ChatId = await newChatCreate();
      prefs.setString('chatId', ChatId!);
      // initiateChat();
    }
    // } else {
    //   //clearToken();
    //   await SocketConnect();
    //   initiateChat();
    //   // customerRegisterInfo();
    // }
  }

  void refresh(dynamic childValue) {
    setState(() {
      // _parentVariable = childValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    alertContext = context;
    // final wsProvider = context.watch<WebsocketsProvider>();
    // print("WsProVider");

    // if (wsProvider.srMessage != null) {
    //   print(wsProvider.srMessage!.toJson().toString());
    // }
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return WillPopScope(
        onWillPop: () async {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('The System Back Button is Deactivated')));
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Text(MainPageTitle),
              automaticallyImplyLeading: false,

              actions: const [],
            ),
            body:
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

                // print("snapChat data -> ${snapshot.data.toString()}");
                // if (snapshot.hasData) {
                //   chatUser = snapshot.data as List<ChatUser>;
                //   List<ChatUsers> chatUsers1 = [];

                //   temp.forEach((v) {
                //     messages!.add(ChatMessage.fromAPItoJson(v));
                //     print("First Added ${v.toString()}");
                //     //print(v);
                //   });

                //print('receiver data -> $chatUsers');

                // for (var element in chatUsers) {
                //   if (element.state == "2") {
                //     chatUsers1.add(element);
                //   }
                // }
                // chatUsers = chatUsers1;

                FutureBuilder(
                    future: checkChatID(),
                    builder: (context, snapshot) {
                      print("snapChat data -> ${snapshot.data.toString()}");
                      if (snapshot.connectionState == ConnectionState.done) {
                        print(chatUser!.value.toJson());
                        return ValueListenableBuilder(
                            valueListenable: chatUser!,
                            builder:
                                (BuildContext context, ChatUsers value, child) {
                              print("chatuser-->Notifier");
                              chatUser!.value = value;
                              return snapshot.data == null ||
                                      chatUser!.value.chatId == ""
                                  ? Center(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                          const Text(
                                            "Currently no Active Chats, ",
                                            textScaleFactor: 1.2,
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                const Text(
                                                  "To start a new Chat, please press",
                                                  textScaleFactor: 0.96,
                                                ),
                                                const SizedBox(width: 3),
                                                Image.network(
                                                  "https://qa.twixor.digital/moc/drive/docs/6221e181524ff067fa675220",
                                                  height: 36,
                                                  width: 34,
                                                  color: Colors.black,
                                                ),
                                                const SizedBox(width: 3),
                                                const Text(
                                                  "below",
                                                  textScaleFactor: 0.96,
                                                ),
                                              ])
                                        ]))
                                  : GestureDetector(
                                      onTap: () {
                                        messages!.value =
                                            chatUser!.value.messages!;
                                        // prefs.setString('chatId', chatUser!.value.chatId!);
                                        print(chatUser!.value.toJson());

                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChatDetailPage(
                                                        chatUser!.value.chatId!,
                                                        "")));
                                      },
                                      child: Column(children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Row(
                                                  children: <Widget>[
                                                    const CircleAvatar(
                                                      backgroundImage: NetworkImage(
                                                          "https://aim.twixor.com/drive/docs/61ef9d425d9c400b3c6c03f9"),
                                                      maxRadius: 30,
                                                    ),
                                                    const SizedBox(
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
                                                            Row(
                                                              children: <
                                                                  Widget>[
                                                                Text(
                                                                  userCustomerId
                                                                      .toString(),
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w900),
                                                                ),
                                                                const SizedBox(
                                                                  width: 80,
                                                                ),
                                                                chatCreationTime !=
                                                                        null
                                                                    ? Text(
                                                                        DateFormat('yyyy-MM-dd  kk:mm')
                                                                            .format(chatCreationTime!)
                                                                            .toString(),
                                                                        style: const TextStyle(
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                32,
                                                                                39,
                                                                                43),
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w400),
                                                                      )
                                                                    : Text(DateFormat(
                                                                            'yyyy-MM-dd  kk:mm')
                                                                        .format(
                                                                            DateTime.now())
                                                                        .toString()),
                                                                const SizedBox(
                                                                  height: 20,
                                                                ),
                                                              ],
                                                            ),
                                                            Text(
                                                              chatUser!.value
                                                                  .messageText
                                                                  .toString(),
                                                              style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          53,
                                                                          50,
                                                                          50),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]));
                            });
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    }),

            // ErrorAlert(context, snapshot.error.toString());

            floatingActionButton: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Visibility(
                    visible: isVisible,

                    child: FloatingActionButton(
                        onPressed: checkClick,
                        tooltip: 'Increment',
                        child: const ImageIcon(
                          NetworkImage(
                              "https://qa.twixor.digital/moc/drive/docs/6221e181524ff067fa675220"),
                          //color: Colors.white,

                          size: 30,
                          color: Colors.white,
                        )), // This trailing comma makes auto-formatting nicer for build methods.
                  ),
                  const SizedBox(width: 10),
                ])));
  }

  requestWritePermission() async {
    PermissionStatus permissionStatus =
        await Permission.manageExternalStorage.status;
    if (permissionStatus.isGranted) {
      allowStorage = true;
    } else {
      Permission.manageExternalStorage.request();
    }
  }

  @override
  void dispose() {
    print("isSocketConnection $isSocketConnection");
    //_notifyControllers
    // mainSubscription!.pause();
    // chatListSubscription!.cancel();
    // print("chatListSubscription dispose ${chatListSubscription.hashCode}");
    getCloseSocket();
    isSocketConnection = false;
    isAlreadyPicked = false;
    print("HomePageConnection$isSocketConnection");
    print("MainSocketisClosed");

    super.dispose();
    // mainSocket!.sink.close();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // switch (state) {
    //   case AppLifecycleState.inactive:
    //   case AppLifecycleState.paused:
    //   case AppLifecycleState.detached:
    //     // await detachedCallBack();
    //     print("App has Idle State");
    //     getCloseSocket();
    //     break;
    //   case AppLifecycleState.resumed:
    //     print("App has been resumed");
    //     if (!isSocketConnection) SocketConnect();

    //     break;
    // }
  }
}
