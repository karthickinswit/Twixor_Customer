import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:twixor_customer/chatDetailPage.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  String? customerId1;
  String? eId1;
  String? mainPageTitle;
  bool isLoading = false;

  late String userDetails;

  String? ChatId;
  late SharedPreferences prefs;
  bool allowStorage = false;
  List<String>? chatIds = [];
  List<ChatUsers> chatUsers = [];

  bool allowClick = false;
  // WebsocketsProvider wsProvider = new WebsocketsProvider();

  final List<TextEditingController> _notifyControllers = [];

  _MyHomePageState();

  @override
  initState() {
    socketMsgReceiveMain();
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
    if (mainSocket.hasListener) {
      getSubscribe();
      print("Resume Socket Main Page");
    } else {}
  }

  checkClick() {
    print("FloatButtonClicked");
    if (!allowClick && chatUsers.length <= 0) {
      print(chatUsers.length);
      allowClick = true;
      print("Clicked");

      _incrementCounter();
    }
    return;
  }

  void _incrementCounter() async {
    //getChatUserInfo();
    isLoading = true;

    if (!allowStorage) {
      requestWritePermission();
    }

    if (await checktoken()) {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      var chatId = await newChatCreate(context);
      // chatIds!.add(chatId);
      // prefs.setStringList('chatIds', chatIds!);
      // print(prefs?.getStringList("chatIds"));
      ChatId = chatId;
      print("new Chat Id ${ChatId}");

      if (ChatId != null) {
        ChatId != null
            ? userChatId = ChatId!
            : ErrorAlert(context, "Chat Id is not present here");

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
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatDetailPage(userChatId, "")));
      } else {
        ErrorAlert(context, "UserDetails Not Present");
        ChatId = await newChatCreate(context);
        _incrementCounter();
      }
    } else {
      clearToken();
      // customerRegisterInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
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

                FutureBuilder(
                    builder: (context, snapshot) {
                      print("snapChat data -> ${snapshot.data.toString()}");
                      if (snapshot.hasData) {
                        chatUsers = snapshot.data as List<ChatUsers>;
                        List<ChatUsers> chatUsers1 = [];

                        //print('receiver data -> $chatUsers');

                        // for (var element in chatUsers) {
                        //   if (element.state == "2") {
                        //     chatUsers1.add(element);
                        //   }
                        // }
                        // chatUsers = chatUsers1;
                        chatUsers.asMap().forEach((key, value) {
                          if (value.state == "2") {
                            chatUsers1.add(value);
                            _notifyControllers.add(TextEditingController());
                          }
                        });
                        chatUsers = chatUsers1;

                        print("${chatUsers.toString()}" " ${chatUsers.length}");
                        if (chatUsers1.length > 0) {
                          //  isVisible = false;
                        }

                        return chatUsers.isEmpty
                            ? Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                            : ListView.builder(
                                itemCount: chatUsers.length,
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(top: 10),
                                itemBuilder: (context1, index) {
                                  //_notifyControllers[index].text = "0";
                                  // print(chatUsers[index].chatId);
                                  List<ChatMessage> nonReadMessages = [];
                                  for (ChatMessage message1
                                      in chatUsers[index].messages!) {
                                    // if (message1.status != "2") {
                                    //   nonReadMessages.add(message1);
                                    // }
                                  }
                                  // isVisible = false;
                                  // print("${_notifyControllers}");

                                  _notifyControllers[index].text =
                                      _notifyControllers[index].text;

                                  print(
                                      "nonReadmessages Length ${nonReadMessages.length}");
                                  // _notifyControllers[index].text =
                                  //     nonReadMessages.length.toString();

                                  if (chatUsers.isEmpty) {
                                    return const Center(
                                        child:
                                            Text("There is no Chats Found "));
                                  } else if (chatUsers[index].state != "0") {
                                    return GestureDetector(
                                      onTap: () async {
                                        var userChatId =
                                            chatUsers[index].chatId.toString();

                                        isLoading = false;
                                        // isVisible = true;
                                        //subscriber!.cancel();
                                        // mainSubscription!.pause();

                                        // Navigator.pushAndRemoveUntil<dynamic>(
                                        //   context,
                                        //   MaterialPageRoute<dynamic>(
                                        //     builder: (BuildContext context) => ChatDetailPage(userDetails, ""),
                                        //   ),
                                        //   (route) => false, //if you want to disable back feature set to false
                                        // );
                                        //  if (strmControl.hasListener) {}
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChatDetailPage(
                                                        userChatId, "")));
                                        //.then(
                                        //   (value) => setState(() {
                                        //     print("ISBack");
                                        //     if (mainSubscription!.isPaused) {
                                        //       getSubscribe();
                                        //     }
                                        //   }),
                                        // ); //if you want to disable back feature set to false
                                        // ).then((x) {
                                        //   setState(() {});
                                        //   // Navigator.push(
                                        //   //         context,
                                        //   //         MaterialPageRoute(
                                        //   //             builder: (context) =>
                                        //   //                 ChatDetailPage(
                                        //   //                     userDetails, "")))
                                        //   //     .then((x) {
                                        //   //   setState(() {});
                                        //   // });
                                        // });
                                      },
                                      child: Container(
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
                                                      color: Colors.transparent,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                            chatUsers[index]
                                                                .chatId
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        16),
                                                          ),
                                                          const SizedBox(
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
                                                  const SizedBox(width: 10),
                                                  _notifyControllers[index]
                                                              .text ==
                                                          ""
                                                      ? Container()
                                                      : Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          constraints:
                                                              const BoxConstraints(
                                                            minWidth: 14,
                                                            minHeight: 14,
                                                          ),
                                                          child: Text(
                                                            _notifyControllers[
                                                                    index]
                                                                .text,
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 8,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                        child: Text("There was a Problem "));
                                  }
                                },
                              );
                      } else if (snapshot.hasError) {
                        // ErrorAlert(context, snapshot.error.toString());

                        return Center(
                          child: Column(children: <Widget>[
                            const Text(
                                "There was a Problem.Please click to retry "),
                            IconButton(
                                onPressed: () {
                                  // _checkPrefs();
                                  // // //clearToken();

                                  // MaterialPageRoute(
                                  //     builder: (context) => CustomerApp(
                                  //           customerId: customerId,
                                  //           eId: eId,
                                  //           mainPageTitle: MainPageTitle,
                                  //           theme: customTheme,
                                  //         ));
                                  // setState(() {});
                                  // setState(() {});
                                },
                                icon: const Icon(IconData(0xf2f7,
                                    fontFamily: 'MaterialIcons')))
                          ]),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                    future: getChatList(context)),
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

  socketMsgReceiveMain() {
    var message1;
    print("Socket main is Calling");

    // // await SocketConnect();
    // //SocketObservable();
    // print("isSocketConnection $isSocketConnection");
    // mainSocket = bSubject;
    // if (mainSocket!.isClosed) {
    //   print("ChatPage Socket Closed");
    //   SocketObservable();
    //   mainSocket = bSubject;
    // }
    if (mainSubscription!.isPaused) {
      print("mainSubscription is paused");
      mainSubscription!.resume();
    }

    mainSubscription!.onData((data) {
      print("Main PageMessage ${data.toString()}");
      message1 = json.decode(data);
      if (message1["action"] == "onOpen") {
        print("Connection establised.");
      } else if (message1["action"] == "customerReplyChat") {
        print("Message sent Socket");
        setState(() {
          //  setState(() {});
        });
      } else if (message1["action"] == "agentPickupChat") {
        setState(() {});
      } else if (message1["action"] == "agentReplyChat") {
        print("Message sent Socket");
        var json = SocketResponse.fromJson(message1);
        var temp = json.content![0].response!.chat!.chatId;
        print("ChatId $temp");
        var index = chatUsers.indexWhere((element) => element.chatId == temp);

        int count = _notifyControllers[index].text != ""
            ? int.parse(_notifyControllers[index].text)
            : 0;
        _notifyControllers[index].text =
            _notifyControllers[index].text != "" ? (count + 1).toString() : "1";
        print("${chatUsers[index].chatId} ${_notifyControllers[index].text}");
        setState(() {});
      } else if (message1["action"] == "agentEndChat") {
        var json = SocketResponse.fromJson(message1);
        var temp = json.content![0].response!.chat!.chatId;
        print("ChatId $temp");
        var index = chatUsers.indexWhere((element) => element.chatId == temp);

        print(chatUsers.length);
        if (index != null) chatUsers.removeAt(index);
        //  if (index1 != null) chatUsers1.removeAt(index1);

        setState(() {
          chatUsers = <ChatUsers>[];

          print("ChatUsersIndex--> ${index}");
        });
      }
      print("mainPageMessage ${data.toString()}");
    });
  }

  @override
  void dispose() {
    print("isSocketConnection $isSocketConnection");
    //_notifyControllers
    // mainSubscription!.pause();
    print("MainSocketisClosed");
    super.dispose();
    // mainSocket!.sink.close();
  }
}
