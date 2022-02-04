import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twixor_customer/chatDetailPage.dart';

import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'API/apidata-service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper_files/FileReader.dart';

void main() {
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({Key? key}) : super(key: key);
  @override

  // This widget is the root of your application.
  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  initState() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
  }

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

  @override
  initState() {
    // TODO: implement initState
    super.initState();
    configLoading();
    getPref();
  }

  getPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _incrementCounter() async {
    //getChatUserInfo();
    isLoading = true;
    isVisible = false;
    if (!allowStorage) {
      requestWritePermission();
    }

    ChatId = prefs.getString('chatId') != null ? prefs.getString('chatId') : "";

    if (ChatId == null || ChatId == '') {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      var chatId = await newChatCreate();
      prefs.setString('chatId', chatId);
      ChatId = chatId;
    }

    userDetails = json.encode(await getChatUserInfo(ChatId!));

    isLoading = false;
    isVisible = true;

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatDetailPage(userDetails, "")));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: isLoading
          ? //check loadind status
          Center(child: CircularProgressIndicator())
          : Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: Column(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    '',
                  ),
                  Text(
                    '',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  FloatingActionButton(
                    onPressed: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  FileApp())) //FileReaderPage(
                      //       filePath:
                      //           'storage/emulated/0/Download/twixor_agent/sample document.pdf',
                      //     )))
                    },
                    tooltip: 'Increment',
                    child: const Icon(
                      IconData(0xe4cc, fontFamily: 'MaterialIcons'),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Visibility(
        visible: isVisible,
        child: new FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(
            IconData(0xf8b8, fontFamily: 'MaterialIcons'),
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
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
