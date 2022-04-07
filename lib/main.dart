// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, must_be_immutable, no_logic_in_create_state, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/subjects.dart';
import 'package:twixor_customer/HomePage.dart';
import 'package:twixor_customer/chatDetailPage.dart';
import 'package:twixor_customer/models/SavedDataModel.dart';

import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:web_socket_channel/io.dart';

import 'package:twixor_customer/API/apidata-service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper_files/Websocket.dart';
import 'helper_files/utilities_files.dart';
import 'models/SocketResponseModel.dart';
import 'models/chatMessageModel.dart';

//29900
ThemeData MyTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.blue,
  ).copyWith(
    secondary: Colors.green,
  ),
  backgroundColor: Colors.amber[50],
  appBarTheme: const AppBarTheme(
      color: Colors.blue, elevation: 0, foregroundColor: Colors.amber),
  textTheme: const TextTheme(bodyText2: TextStyle(color: Colors.black87)),
  buttonTheme: const ButtonThemeData(
    textTheme: ButtonTextTheme.normal,
  ),
  iconTheme:
      const IconThemeData(size: 30.0, color: Color.fromARGB(255, 129, 51, 51)),
);
void main() {
  runApp(CustomerApp(
    customerId: '8190083902',
    eId: '374',
    mainPageTitle: "Twixor CustomerChat",
    theme: MyTheme,
  ));
}

class CustomerApp extends StatelessWidget {
  String customerId;
  String eId;
  String mainPageTitle;
  ThemeData theme;
  //CustomerApp(this.eId, this.customerId);
  CustomerApp(
      {Key? key,
      required this.customerId,
      required this.eId,
      required this.mainPageTitle,
      required this.theme})
      : super(key: key);

  late SharedPreferences prefs;

  get refresh => null;
  @override
  @override
  Widget build(BuildContext context) {
    // print("ManPageTitile ${ThemeClass().MainPageTitile}");
    print("SocketinMain74$isSocketConnection");
    customTheme = theme;
    userCustomerId = customerId;
    userEid = eId;
    MainPageTitle = mainPageTitle;
    // getSubscribe();
    getPref();
    //SocketConnect();

    return WillPopScope(
      //////////////////////////////////////////////
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The System Back Button is Deactivated')));
        return false;
      },
      child: FutureBuilder<bool>(
          future: _checkPrefs(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            // print(const AsyncSnapshot.nothing().toString());
            // if (snapshot.connectionState == ConnectionState.none) {

            // }

            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data == true) {
                return MaterialApp(
                    theme: customTheme,
                    title: "Twixor",
                    home: const MyHomePage());
              } else {
                return MaterialApp(
                    theme: customTheme,
                    title: "Twixor",
                    home: Center(
                      child: CircularProgressIndicator(),
                    ));
              }
            } else {
              return MaterialApp(
                  theme: customTheme,
                  title: "Twixor",
                  home: Center(
                    child: CircularProgressIndicator(),
                  ));
            }
          }),
    );
  }

  getPref() async {
    print("SocketinMain125$isSocketConnection");
    // getApiPref();
    //await clearToken();

    // if (authToken == null || authToken == "") {
    //   var token = await getTokenApi();
    // } else {
    //   print(authToken);
    //   // getChatList(context);
    // }
    prefs = await SharedPreferences.getInstance();
    prefs.setString('title', mainPageTitle);

    prefs.getString('authToken');

    //getSubscribe();
    messages!.value = [];
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
    if (isSocketConnection == false) {
      getCloseSocket();
    }
  }

  Future<bool> _checkPrefs() async {
    var tempCustId, tempEid;
    print("SocketinMain$isSocketConnection");
    if (isSocketConnection == false) {
      getCloseSocket();
    }
    // if (!isSocketConnection)
    // isSocketConnection = false;
    prefs = await SharedPreferences.getInstance();
    tempCustId = prefs.getString('customerId') ?? "";
    tempEid = prefs.getString('eId') ?? "";
    authToken = prefs.getString('authToken') ?? "";

    // if (channel != null) {
    //   channel!.innerWebSocket!.done;
    // } else {
    //   print("ChannelisNotCLose");
    //   print(channel.toString());
    // }
    //prefs.setString('title', MainPageTitle);
    if (tempCustId == "" && tempEid == "") {
      clearToken();
      prefs.setString('customerId', userCustomerId);
      prefs.setString('eId', userEid);
      prefs.setString('title', MainPageTitle);
      canCreateChat = true;
      //authToken = await getTokenApi() ?? "";
      //prefs.setString('authToken', authToken!);
      return true;
    } else if (tempCustId == userCustomerId && tempEid == userEid) {
      if (authToken == "") {
        canCreateChat = false;
        //authToken = await getTokenApi() ?? "";
        //prefs.setString('authToken', authToken!);
        return true;
      } else {
        clearToken();
        return true;
      }
    } else if (tempCustId != userCustomerId || tempEid != userEid) {
      clearToken();
      canCreateChat = false;
      prefs.setString('customerId', userCustomerId);
      prefs.setString('eId', userEid);
      prefs.setString('chatId', '');
      canCreateChat = true;
      //authToken = await getTokenApi() ?? "";
      //prefs.setString('authToken', authToken!);
      return true;
    } else
      return false;
    //  else {
    //   return _checkPrefs();
    // }
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
    //     //if (!isSocketConnection) SocketConnect();
    //     break;
    // }
  }
}
