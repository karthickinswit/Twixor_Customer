import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:twixor_customer/helper_files/Websocket.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
import 'package:twixor_customer/models/ChatSummaryModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';

const APP_URL = String.fromEnvironment('APP_URL',
    defaultValue: 'https://qa.twixor.digital/moc');
String url = APP_URL + '/c/enterprises/';
String eId = "374";

String authToken =
    "P11FI/5sJrC08gVXgVsbZpJI8xHugmxj/+LYQc521vwfXZJCEMLuKFgxM9RtZPcl";
String socketToken =
    'BgLEkVzBi6r3Bx0bed4moFE04H/JWlVmcbODDnTw448fXZJCEMLuKFgxM9RtZPcl';
Map<String, String> mainheader = {
  "Content-Type": "application/json",
  "authentication-token": authToken
};

Future<List<Attachment>> getAttachments(int mediaType) async {
  List<Attachment>? attachments = [];
  final response = await http.get(
      Uri.parse(url +
          "artifacts?type=${mediaType.toString()}&from=0&perPage=10&desc=&visibility=public"),
      headers: mainheader);
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
  final response =
      await http.get(Uri.parse(url + 'chat/summary'), headers: mainheader);
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

    // print('return data $chatUsersData');
    return chatUsersData;
  }
  print('return data $chatUsersData');
  return chatUsersData;
}

Future<ChatUsers?> getChatUserInfo(String ChatId) async {
  var token = await customerRegisterInfo();
  final response = await http.get(
      Uri.parse(APP_URL + '/c/enterprises/' + eId + '/chat/' + ChatId),
      headers: {'authentication-token': token});
  socketToken = token;
  ChatUsers? chatUserData;
  print(response.headers.toString());
  if (response.statusCode == 200) {
    //print(response.body.toString());
    var obj = json.decode(response.body.replaceAll("\$", ""));
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
  }
  print('return data $chatUserData');
  return chatUserData;
}

newChatCreate() async {
  var map = new Map<String, dynamic>();
  map['stickySession'] = 'false';

  final response = await http.post(
      Uri.parse(APP_URL + '/c/enterprises/' + eId + '/chat/create'),
      headers: {
        'authentication-token': await customerRegisterInfo(),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: map);
  ChatUsers? chatUserData;

  print(response.headers.toString());
  if (response.statusCode == 200) {
    //print(response.body.toString());
    var obj = json.decode(response.body.replaceAll("\$", ""));
    var chatId = obj["response"]["chatId"];
    return chatId.toString();
  }
}

customerRegisterInfo() async {
  var map = new Map<String, dynamic>();
  map['name'] = '1234';
  map['phoneNumber'] = '1234';
  map['countryCode'] = '+91';
  map['countryAlpha2Code'] = 'IN';
  map['needVerification'] = 'false';

  map['byInvitation'] = 'false';
  map['subscribeToAll'] = 'true';
  map['enterprisesToSubscribe'] = '{"eIds":[374]}';
  map['clearMsgs'] = 'true';

  final response = await http
      .post(Uri.parse(APP_URL + '/account/customer/register'), body: map);
  ChatUsers? chatUserData;

  print(response.headers.toString());
  if (response.statusCode == 200) {
    //print(response.body.toString());
    var obj = json.decode(response.body.replaceAll("\$", ""));
    var token = obj["response"]["token"];
    return token;
  }
}
