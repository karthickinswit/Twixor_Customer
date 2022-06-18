// ignore_for_file: unnecessary_new

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:twixor_customer/chatDetailPage.dart';
import 'package:twixor_customer/missedChatDetailPage.dart';
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

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  String? customerId1;
  String? eId1;
  String? mainPageTitle;
  bool isLoading = false;
  StreamSubscription? chatListSubscription;

  late String userDetails;

  int currentPage = 0;
  int perPage = 10;

  String? ChatId;
  late SharedPreferences prefs;
  bool allowStorage = false;
  bool allowClick = true;
  List<String>? chatIds = [];

  // WebsocketsProvider wsProvider = new WebsocketsProvider();

  final List<TextEditingController> _notifyControllers = [];
  late TabController _tabController;
  final ScrollController _controller =
      ScrollController(initialScrollOffset: 10);

  _MyHomePageState();

  @override
  initState() {
    pref();
    _controller.addListener(_scrollListener);
    super.initState();
    configLoading();
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    super.setState(() {});
  }

  _scrollToEnd() async {
    print(_controller.hasClients);
    if (_controller.hasClients) {
      // print(_controller.position.haveDimensions);
      if (_controller.position.haveDimensions) {
        // print(_controller.position.maxScrollExtent ?? _controller.position);
        print("MaxScrollExtend ${_controller.position.maxScrollExtent}");

        _controller.animateTo(_controller.position.maxScrollExtent + 1000,
            duration: const Duration(microseconds: 60),
            curve: Curves.fastOutSlowIn);
      }
    }
  }

  _scrollListener() {
    // print(
    //     "Offset ${_controller.offset} -- MaxscrollExtend ${_controller.position.maxScrollExtent}");
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      var tempCurrentPage = currentPage;
      tempCurrentPage = tempCurrentPage + 1;
      print(tempCurrentPage);
      currentPage = tempCurrentPage;
      // setState(() {
      //   print("reach the bottom");
      // });
    }
    if (_controller.offset <= _controller.position.minScrollExtent &&
        !_controller.position.outOfRange) {
      // setState(() {
      //   print("reach the top");
      // });
    }
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
    // print("Resume Socket Main Page");
  }

  checkClick() {
    //canCreateChat = true;
    // print("Cancreate when CLick ${canCreateChat} ");
    print("CanCreateChat--> $canCreateChat");
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
      setState(() {});
      return;
    }
  }

  void initiateChat() async {
    if (!allowStorage) {
      requestWritePermission();
    }

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
    if (chatId == "false") {
      canCreateChat = true;
      ErrorAlert(context, "Please Retry to create new Chat");
    } else {
      canCreateChat = false;

      // ChatId = chatId;

      if (chatId != null) {
        chatId != null
            ? userChatId = chatId!
            : ErrorAlert(alertContext, "Chat Id is not present here");

        isLoading = false;

        if (await getChatUserInfo(chatId!)) {
          messages!.value = [];
          // prefs.setString('chatId', chatUser!.value.chatId!);

          Navigator.of(context, rootNavigator: true).pop();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatDetailPage(userChatId, "")));
        }
      } else {
        ErrorAlert(context, "UserDetails Not Present");
        // /ChatId = await newChatCreate();
        // prefs.setString('chatId', ChatId!);
        // initiateChat();
      }
    }
  }

  void refresh(dynamic childValue) {
    setState(() {
      // _parentVariable = childValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    alertContext = context;

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
              title: Column(
                  children: [Text(MainPageTitle, textAlign: TextAlign.center)]),
              centerTitle: false,
              flexibleSpace: Text(MainPageTitle, textAlign: TextAlign.center),

              automaticallyImplyLeading: false,
              toolbarHeight: 80,

              actions: const [],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(2.0),
                child: TabBar(
                  indicatorColor: Color.fromARGB(255, 240, 204, 204),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.blueGrey,
                  controller: _tabController,
                  tabs: const [
                    SizedBox(
                      height: 40.0,
                      //alignment: Tex,
                      child: Tab(text: 'Active Chats'),
                    ),
                    SizedBox(
                      height: 40.0,
                      child: Tab(text: 'Closed Chats'),
                    ),
                    //   Tab( text: 'Active Chats'),
                    //   Tab( text: 'Closed Chats')
                  ],
                ),
              ),
            ),
            body: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
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
                  activeChatWidget(),
                  missedChatWidget()
                ]),

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

  Widget activeChatWidget() {
    return FutureBuilder<dynamic>(
        future: getChatList('2'),
        builder: (context, snapshot) {
          // print("snapChat data -> ${snapshot.data.toString()}");
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            if (chatUser!.value.chatId == "toeknFailed") {
              return const Center(
                  child: Icon(IconData(0xe514, fontFamily: 'MaterialIcons')));
            }
            chatUser = snapshot.data;
            // print(chatUser!.value.toJson());
            return ValueListenableBuilder(
                valueListenable: chatUser!,
                builder: (BuildContext context, ChatUsers value, child) {
                  // print("chatuser-->Notifier");
                  chatUser!.value = value;
                  return snapshot.data == null || chatUser!.value.chatId == ""
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                          onTap: () async {
                            // messages!.value = chatUser!.value.messages!;
                            // prefs.setString('chatId', chatUser!.value.chatId!);
                            // print(chatUser!.value.toJson());
                            print("Chat ID -->${chatUser!.value.chatId}");
                            if (allowClick == true) {
                              print("AllowClick-->${allowClick}");
                              allowClick = false;
                              if (await getChatUserInfo(
                                  chatUser!.value.chatId!)) {
                                messages!.value = chatUser!.value.messages!;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ChatDetailPage(
                                            chatUser!.value.chatId!, "")));
                              }
                            }
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
                                            color: Colors.transparent,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    Text(
                                                      // chatUser!.value.chatId
                                                      //     .toString(),
                                                      userCustomerId.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w900),
                                                    ),
                                                    const SizedBox(
                                                      width: 80,
                                                    ),
                                                    chatCreationTime != null
                                                        ? Text(
                                                            DateFormat(
                                                                    'yyyy-MM-dd  kk:mm')
                                                                .format(
                                                                    chatCreationTime!)
                                                                .toString(),
                                                            style: const TextStyle(
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        32,
                                                                        39,
                                                                        43),
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
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
                                                  chatUser!.value.messageText
                                                      .toString(),
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color.fromARGB(
                                                          255, 53, 50, 50),
                                                      fontWeight:
                                                          FontWeight.normal),
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
        });
  }

  Widget missedChatWidget() {
    return FutureBuilder(
        future: getMissedChatList(),
        builder: (context, projectSnap) {
          print("MissedChatState ${projectSnap.connectionState.toString()}");
          if (projectSnap.connectionState == ConnectionState.done &&
              projectSnap.hasData) {
            missedChatUsers = projectSnap.data as List<ChatUsers>;

            //print('project snapshot data is: ${projectSnap.data}');
            if (missedChatUsers.length == 0) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                    Text(
                      "No more Closed Chats",
                      textScaleFactor: 1.2,
                    ),
                    SizedBox(height: 10),
                  ]));
            } else {
              return ListView.builder(
                  controller: _controller,
                  itemCount: missedChatUsers.length,
                  // physics: AlwaysScrollableScrollPhysics(),
                  //addSemanticIndexes: true,
                  padding: const EdgeInsets.only(bottom: 60),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    // print(missedChatUsers[index].name);
                    return GestureDetector(
                        onTap: () {
                          messages!.value = missedChatUsers[index].messages!;
                          // prefs.setString('chatId', missedChatUsers[index].chatId!);
                          // print(missedChatUsers[index].toJson());

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MissedChatDetailPage(
                                      missedChatUsers[index].chatId!, "")));
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
                                          color: Colors.transparent,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  Text(
                                                    missedChatUsers[index]
                                                        .name
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w900),
                                                  ),
                                                  const SizedBox(
                                                    width: 80,
                                                  ),
                                                  // chatCreationTime != null
                                                  //     ? Text(
                                                  //         DateFormat(
                                                  //                 'yyyy-MM-dd  kk:mm')
                                                  //             .format(
                                                  //                 chatCreationTime!)
                                                  //             .toString(),
                                                  //         style: const TextStyle(
                                                  //             color: Color
                                                  //                 .fromARGB(
                                                  //                     255,
                                                  //                     32,
                                                  //                     39,
                                                  //                     43),
                                                  //             fontSize: 14,
                                                  //             fontWeight:
                                                  //                 FontWeight
                                                  //                     .w400),
                                                  //       )
                                                  //     : Text(DateFormat(
                                                  //             'yyyy-MM-dd  kk:mm')
                                                  //         .format(
                                                  //             DateTime.now())
                                                  //         .toString()),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                missedChatUsers[index]
                                                    .messageText
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color.fromARGB(
                                                        255, 53, 50, 50),
                                                    fontWeight:
                                                        FontWeight.normal),
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
            }
          } else if (projectSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                  Text(
                    "There was a Problem",
                    textScaleFactor: 1.2,
                  ),
                  SizedBox(height: 10),
                ]));
          }
        });
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
    print("homePageDispose");
    getCloseSocket();
    isSocketConnection = false;
    isAlreadyPicked = false;
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // switch (state) {
    //   case AppLifecycleState.resumed:
    //     print("App has been resumed");
    //     //if (!isSocketConnection) SocketConnect();
    //     break;
    //   case AppLifecycleState.inactive:
    //     // TODO: Handle this case.
    //     break;
    //   case AppLifecycleState.paused:
    //     // TODO: Handle this case.
    //     break;
    //   case AppLifecycleState.detached:
    //     // TODO: Handle this case.
    //     break;
    // }
  }
}
