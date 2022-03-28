// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, must_be_immutable, no_logic_in_create_state, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/subjects.dart';
import 'package:twixor_customer/HomePage.dart';
import 'package:twixor_customer/chatDetailPage.dart';
import 'package:twixor_customer/models/SavedDataModel.dart';

import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:web_socket_channel/io.dart';

import 'API/apidata-service.dart';
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
        child: SocketConnect() != false
            ? MaterialApp(
                theme: customTheme, title: "Twixor", home: const MyHomePage())
            : const CircularProgressIndicator());
  }

  getPref() async {
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

    getSubscribe();
  }
}
