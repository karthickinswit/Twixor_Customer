import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:twixor_customer/chatDetailPage.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // These are the callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        // widget is resumed
        print("HomePop-->Resumed");
        break;
      case AppLifecycleState.inactive:
        // widget is inactive
        print("HomePop-->Inactive");
        break;
      case AppLifecycleState.paused:
        // widget is paused
        print("HomePop-->Paused");
        break;
      case AppLifecycleState.detached:
        print("HomePop-->Detached");
        // widget is detached
        break;
    }
  }

  pref() async {
    prefs = await SharedPreferences.getInstance();
    //prefs.setString('title', mainPageTitle);
    MainPageTitle = prefs.getString('title')!;

    // if (mainSocket.hasListener) {
    // chatListSubscription = getSubscribe();
    //print("chatListSubscription prefs ${chatListSubscription.hashCode}");
    //getSubscribe();
    socketMsgReceiveMain();
    print("Resume Socket Main Page");

    // } else {
    //   await SocketConnect();
    // }
  }

  checkChatID() async {
    prefs = await SharedPreferences.getInstance();
    var storedchatId = prefs.getString('chatId');
    print("storedChatID-->${storedchatId}");
    if (storedchatId != null) {
      if (await getChatUserInfo(storedchatId)) {
        if (chatUser!.value.state == "2") {
          print("CheckState--> ${chatUser!.value.toJson()}");
          isAlreadyPicked = true;
          return chatUser;
        } else {
          isAlreadyPicked = false;
          return null;
        }
      }
    } else
      return null;
  }

  checkClick() {
    if (!isAlreadyPicked) {
      initiateChat();
    }
  }

  void initiateChat() async {
    //getChatUserInfo();

    if (!allowStorage) {
      requestWritePermission();
    }

    if (isSocketConnection) {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      var chatId = await newChatCreate();
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
        // chatListSubscription!.cancel();
        // messages!.value = [];
        if (await getChatUserInfo(ChatId!)) {
          messages!.value = chatUser!.value.messages!;
          prefs.setString('chatId', chatUser!.value.chatId!);
          print(chatUser!.value.toJson());

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
    } else {
      clearToken();
      await SocketConnect();
      initiateChat();
      // customerRegisterInfo();
    }
  }

  void refresh(dynamic childValue) {
    setState(() {
      // _parentVariable = childValue;
    });
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
                              return chatUser!.value.chatId == null ||
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
                                                Image.asset(
                                                    "images/add_chat_256.png",
                                                    height: 30,
                                                    width: 30),
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
                                                      backgroundImage:
                                                          AssetImage(
                                                              "images/pp.png"),
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
                                                            Text(
                                                              chatUser!
                                                                  .value.chatId
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
                                                              chatUser!.value
                                                                  .messageText
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
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]));
                            });
                      } else
                        return Center(child: CircularProgressIndicator());
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
                          AssetImage("images/add_chat_256.png"),
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
    // if (mainSubscription!.isPaused) {
    //   print("mainSubscription is paused");
    //   mainSubscription!.resume();
    // }

    mainSubscription!.onData((data) {
      print("Main PageMessage ${data.toString()}");
      message1 = json.decode(data);
      if (message1["action"] == "onOpen") {
        print("Connection establised.");
        isSocketConnection = true;
      } else if (message1["action"] == "agentReplyChat") {
        var json = SocketResponse.fromJson(message1);
        var chatId = json.content![0].response!.chat!.chatId;
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;
        if (chatId == chatUser!.value.chatId) {
          messages!.value = swapMsg(k);
          messages!.notifyListeners();
        }

        //       print("Message sent Socket");
        //       print(message1.toString());
        //       print(userdata!.name);
        //       var json = SocketResponse.fromJson(message1);
      } else if (message1["action"] == "agentPickupChat") {
        var json = SocketResponse.fromJson(message1);
        var chatId = json.content![0].response!.chat!.chatId;
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;
        List<ChatAgent> m = json.content![0].response!.users!;
        //       actionBy =
        //           json.content![0].response!.chat!.messages!.value[0].actionBy.toString();
        //       print(message1.toString());
        if (chatId == chatUser!.value.chatId) {
          messages!.value = swapMsg(k);
          messages!.notifyListeners();
          chatUser!.notifyListeners();
          chatUser!.value.actionBy =
              json.content![0].response!.users![1].id.toString();
          chatUser!.notifyListeners();
          chatAgents = m;
          isAlreadyPicked = true;
          //chatUser = m;
        }
        //       chatAgents = m.cast<ChatAgent>();

        //       prefs1!.setBool('chatCreated', true); else if (message1["action"] == "agentReplyChat") {

      } else if (message1["action"] == "agentEndChat") {
        var json = SocketResponse.fromJson(message1);
        var chatId = json.content![0].response!.chat!.chatId;
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;

        // print("ChatId $temp");
        if (chatId == chatUser!.value.chatId) {
          messages!.value = swapMsg(k);
          messages!.notifyListeners();
          var temp;
          chatUser!.value = ChatUsers(
              name: "",
              messageText: "",
              imageURL: "",
              time: "",
              msgindex: 0,
              messages: [],
              actionBy: "",
              chatId: "",
              eId: "",
              chatAgents: chatAgents,
              state: "",
              newMessageCount: "");
          chatUser!.notifyListeners();
          prefs.setString('chatId', "");
          isAlreadyPicked = false;
        }

        // print(chatUsers.length);
        // if (index != null) chatUsers.removeAt(index);
        //  if (index1 != null) chatUsers1.removeAt(index1);

        setState(() {
          //chatUser = <ChatUsers>[];

          // print("ChatUsersIndex--> ${index}");
        });
      } else if (message1["action"] == "customerStartChat") {
        print("Customer Start Chat");
        var json = SocketResponse.fromJson(message1);
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;
        var chatId = json.content![0].response!.chat!.chatId;
        print(message1.toString());
        if (chatId == chatUser!.value.chatId) {
          messages!.value = swapMsg(k);
          messages!.notifyListeners();
          chatUser!.notifyListeners();
        }
        //         messages!.value.addAll(k);
        // print("mainPageMessage ${data.toString()}");
      } else if (message1["action"] == "customerReplyChat") {
        print("Message received Socket");
        var json = SocketResponse.fromJson(message1);
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;
        var chatId = json.content![0].response!.chat!.chatId;

        if (chatId == chatUser!.value.chatId) {
          messages!.value = swapMsg(k);
          messages!.notifyListeners();
          chatUser!.notifyListeners();
        }
      } else if (message1["action"] == "chatError") {
        //       print("waitingTransferAccept");
        ChatMessage k = ChatMessage(
            messageContent: "Please wait until the Agent has Pickup a Chat",
            messageType: "receiver",
            isUrl: false,
            contentType: "MSG",
            url: url,
            actionBy: chatUser!.value.actionBy,
            attachment: new Attachment(),
            actionType: "3",
            actedOn: DateTime.now().toUtc().toString(),
            eId: chatUser!.value.eId);

        messages!.value.add(k);
        messages!.notifyListeners();

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    print("isSocketConnection $isSocketConnection");
    //_notifyControllers
    // mainSubscription!.pause();
    // chatListSubscription!.cancel();
    // print("chatListSubscription dispose ${chatListSubscription.hashCode}");

    print("MainSocketisClosed");
    super.dispose();
    // mainSocket!.sink.close();
  }
}
