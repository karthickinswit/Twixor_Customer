import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twixor_customer/helper_files/Websocket.dart';
import 'package:twixor_customer/helper_files/utilities_files.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
import 'package:twixor_customer/models/ChatSummaryModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';

const APP_URL = String.fromEnvironment('APP_URL',
    defaultValue: 'https://qa.twixor.digital/moc');
String url = APP_URL + '/c/enterprises/';
const eId = String.fromEnvironment('eid', defaultValue: '374');

late SharedPreferences prefs;

String? authToken;

getTokenApi() async {
  prefs = await SharedPreferences.getInstance();
  authToken = prefs.getString('authToken') != null
      ? prefs.getString('authToken')
      : await customerRegisterInfo();
  print("EID ${eId}");
  return authToken;

  print(authToken);
}

// // ""; //"P11FI/5sJrC08gVXgVsbZpJI8xHugmxj/+LYQc521vwfXZJCEMLuKFgxM9RtZPcl";
// String socketToken = "";
// //""; //    'BgLEkVzBi6r3Bx0bed4moFE04H/JWlVmcbODDnTw448fXZJCEMLuKFgxM9RtZPcl';

Future<List<Attachment>> getAttachments(int mediaType) async {
  List<Attachment>? attachments = [];
  var response = await http.get(
      Uri.parse(url +
          "artifacts?type=${mediaType.toString()}&from=0&perPage=10&desc=&visibility=public"),
      headers: {"authentication-token": await getTokenApi()});
  print(response.body.toString());

  if (response.statusCode == 200) {
    //print(response.body.toString());
    //print(response.body.toString());
    var obj = json.decode(response.body); //.replaceAll("\$", ""));
    var obj1 = obj["response"]["artifacts"];
    for (var i = 0; i < obj1.length; i++) {
      attachments.add(Attachment.fromAPItoJson(obj1[i]["data"]));
    }
    print(obj1.runtimeType);

    return attachments;
  }
  return attachments;
}

Future<List<ChatUsers>> getChatUserLists() async {
  var response = await http.get(Uri.parse(url + 'chat/summary'),
      headers: {"authentication-token": await getTokenApi()});
  List<ChatUsers> chatUsersData = [];

  if (response.statusCode == 200) {
    //print(response.body.toString());
    var obj = json.decode(response.body.replaceAll("\$", ""));
    var chatUsers = obj["response"]["chats"];
    var oh = obj["response"];
    print(obj["response"]["chats"].runtimeType);

    for (var i = 0; i < chatUsers.length; i++) {
      var obj1 = chatUsers[i];
      List<ChatMessage> messages = [];

      if (obj1['chatId'] != null && obj1['chatId'] != "") {
        print("data inside for with if -> ${obj1.toString().substring(0, 50)}");
        var chatmessages = obj1["messages"];

        // for (var chatObj in chatmessages) {
        //   if (chatObj.containsKey('message')) {
        //     messages.add(ChatMessage.fromAPItoJson(chatObj));
        //   }
        // }
        var lastKnownTime = obj1["lastModifiedOn"];

        //print('return data $chatUsersData');
        chatUsersData.add(
          ChatUsers.fromJson(obj1),
        );
      }
    }

    // print('return data $chatUsersData';
    return chatUsersData;
  }
  print('return data $chatUsersData');
  return chatUsersData;
}

Future<ChatUsers?> getChatUserInfo(BuildContext context, String ChatId) async {
  var response = await http.get(Uri.parse(url + eId + '/chat/' + ChatId),
      headers: {"authentication-token": await getTokenApi()});

  ChatUsers? chatUserData;
  print(response.headers.toString());
  if (response.statusCode == 200) {
    //print(response.body.toString());
    var obj = json.decode(response.body.replaceAll("\$", ""));
    try {
      var chatUser = obj["response"]["chat"];
      List chatuserDetails = obj["response"]["users"];
      chatUser["chatuserDetails"] = chatuserDetails;
      var oh = obj["response"];
      print(obj["response"]["chat"].runtimeType);

      List<ChatMessage> messages = [];

      //print('return data $chatUsersData');
      chatUserData = ChatUsers.fromJson(chatUser);

      // print('return data $chatUsersData');
      return chatUserData;
    } catch (Exp) {
      ErrorAlert(context, "Session TimeOut");
      customerRegisterInfo();
    }
    //print('return data $chatUserData');
    return chatUserData;
  }
}

newChatCreate(BuildContext context) async {
  var map = new Map<String, dynamic>();
  map['stickySession'] = 'false';

  var response = await http.post(Uri.parse(url + eId + '/chat/create'),
      headers: {
        'authentication-token': await getTokenApi(),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: map);
  ChatUsers? chatUserData;

  //print(response.headers.toString());
  if (response.statusCode == 200) {
    //print(response.body.toString());
    try {
      var obj = json.decode(response.body.replaceAll("\$", ""));
      var chatId = obj["response"]["chatId"];
      print("Chat Id generated");
      return chatId.toString();
    } catch (Exp) {
      ErrorAlert(context, "Session TimeOutError");
    }
  }
}

customerRegisterInfo() async {
  var map = new Map<String, dynamic>();
  map['name'] = '8190083902';
  map['phoneNumber'] = '8190083902';
  map['countryCode'] = '+91';
  map['countryAlpha2Code'] = 'IN';
  map['needVerification'] = 'false';

  map['byInvitation'] = 'false';
  map['subscribeToAll'] = 'true';
  map['enterprisesToSubscribe'] = '{"eIds":[${int.parse(eId)}]}';
  map['clearMsgs'] = 'true';

  final response = await http
      .post(Uri.parse(APP_URL + '/account/customer/register'), body: map);
  ChatUsers? chatUserData;

  //print(response.headers.toString());
  if (response.statusCode == 200) {
    //print(response.body.toString());
    var obj = json.decode(response.body.replaceAll("\$", ""));
    var token = obj["response"]["token"];
    authToken = token;
    prefs = await SharedPreferences.getInstance();
    prefs.setString('authToken', token);
    return token;
  }
}

getChatList(BuildContext context) async {
  // https://aim.twixor.com/c/enterprises/103/chats
  List<ChatUsers> chatUsers = [];
  final response = await http.get(Uri.parse(url + eId + '/chats'), headers: {
    'authentication-token': await getTokenApi(),
    'Content-Type': 'application/x-www-form-urlencoded'
  });

  //print(response.headers.toString());
  if (response.statusCode == 200) {
    //print(response.body.toString());
    var obj = json.decode(response.body.replaceAll("\$", ""));
    try {
      var chats = obj["response"]["chats"];
      chats.forEach((v) {
        chatUsers.add(new ChatUsers.fromJson(v));
        //print(v);
      });

      return chatUsers;
    } catch (Exp) {
      ErrorAlert(context, "Session TimeOut");
      customerRegisterInfo();
    }
  }
  return chatUsers;
}
