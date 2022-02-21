import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twixor_customer/helper_files/Websocket.dart';
import 'package:twixor_customer/helper_files/utilities_files.dart';
import 'package:twixor_customer/main.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
import 'package:twixor_customer/models/ChatSummaryModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';

const APP_URL = String.fromEnvironment('APP_URL',
    defaultValue: 'https://qa.twixor.digital/moc');
String url = APP_URL + '/c/enterprises/';
//const eId = String.fromEnvironment('eid', defaultValue: '374');
late String eId;
late String customerId;

bool isValidToken = false;

late SharedPreferences prefs;

String? authToken;

getTokenApi() async {
  prefs = await SharedPreferences.getInstance();
  authToken = (prefs.getString('authToken') != null &&
          prefs.getString('authToken') != "")
      ? prefs.getString('authToken')
      : await customerRegisterInfo();
  // ignore: avoid_print
  print("authToken $authToken");
  return authToken;
}

Future<ChatUsers?> getChatUserInfo(BuildContext context, String ChatId) async {
  var response = await http.get(Uri.parse(url + eId + '/chat/' + ChatId),
      headers: {"authentication-token": await getTokenApi()});
  ChatUsers? chatUserData;
  print(response.headers.toString());
  if (response.statusCode == 200) {
    var obj = checkApiResponse(response.body.replaceAll("\$", ""));
    try {
      var chatUser = obj["response"]["chat"];
      List chatuserDetails = obj["response"]["users"];
      chatUser["chatuserDetails"] = chatuserDetails;
      var oh = obj["response"];
      print(obj["response"]["chat"].runtimeType);
      List<ChatMessage> messages = [];
      chatUserData = ChatUsers.fromJson(chatUser);
      return chatUserData;
    } catch (Exp) {
      ErrorAlert(context, "Session TimeOut");
      await customerRegisterInfo();
    }
    return chatUserData;
  } else {
    throw ("Get Chat Information is Failed");
  }
}

newChatCreate(BuildContext context) async {
  var map = Map<String, dynamic>();
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
      var obj = checkApiResponse(response.body.replaceAll("\$", ""));
      var chatId = obj["response"]["chatId"];
      print("Chat Id generated");
      return chatId.toString();
    } catch (Exp) {
      ErrorAlert(context, "Session TimeOutError");
    }
  } else {
    clearToken();
    isValidToken = false;
    customerRegisterInfo();
    throw ("New Chat Creation Failed");
  }
}

customerRegisterInfo() async {
  var map = Map<String, dynamic>();

  map['name'] = customerId;
  map['phoneNumber'] = customerId;
  map['countryCode'] = '+91';
  map['countryAlpha2Code'] = 'IN';
  map['needVerification'] = 'false';

  map['byInvitation'] = 'false';
  map['subscribeToAll'] = 'true';
  map['enterprisesToSubscribe'] = '{"eIds":[${int.parse(eId)}]}';
  map['clearMsgs'] = 'true';

  final response = await http
      .post(Uri.parse(APP_URL + '/account/customer/register'), body: map);

  if (response.statusCode == 200) {
    var obj = checkApiResponse(response.body.replaceAll("\$", ""));
    var token = obj["response"]["token"];
    authToken = token;
    prefs = await SharedPreferences.getInstance();
    prefs.setString('authToken', token);
    return token;
  } else {
    throw ("Registration Failed");
  }
}

getChatList(BuildContext context) async {
  // https://aim.twixor.com/c/enterprises/103/chats
  List<ChatUsers> chatUsers = [];
  var tempUrl = APP_URL +
      'c/enterprises/chat/summary?fromDate=2019-02-16T06:34:16.859Z'; //url + eId + '/chats
  final response = await http.get(Uri.parse(url + eId + '/chats'), headers: {
    'authentication-token': await getTokenApi(),
    'Content-Type': 'application/x-www-form-urlencoded'
  });

  print(response.headers.toString());
  if (response.statusCode == 200) {
    isValidToken = true;
    print(response.body.toString());
    var obj = checkApiResponse(response.body.replaceAll("\$", ""));
    //json.decode(response.body.replaceAll("\$", ""));
    try {
      var chats = obj["response"]["chats"];
      chats.forEach((v) {
        chatUsers.add(ChatUsers.fromJson(v));
        //print(v);
      });

      return chatUsers;
    } catch (Exp) {
      ErrorAlert(context, "Session TimeOut");
      isValidToken = false;
    }
  } else {
    clearToken();
    throw ("getting Chat List Failed");
  }
}

checktoken() async {
  List<ChatUsers> chatUsers = [];
  var tempUrl = APP_URL +
      'c/enterprises/chat/summary?fromDate=2019-02-16T06:34:16.859Z'; //url + eId + '/chats
  final response = await http.get(Uri.parse(url + eId + '/chats'), headers: {
    'authentication-token': await getTokenApi(),
    'Content-Type': 'application/x-www-form-urlencoded'
  });

  print(response.headers.toString());
  if (response.statusCode == 200) {
    isValidToken = true;
    print(response.body.toString());
    var obj = checkApiResponse(response.body.replaceAll("\$", ""));
    //json.decode(response.body.replaceAll("\$", ""));
    try {
      var chats = obj["response"]["chats"];
      chats.forEach((v) {
        chatUsers.add(ChatUsers.fromJson(v));
        //print(v);
      });

      ///return chatUsers;
    } catch (Exp) {
      isValidToken = false;
    }
    return isValidToken;
  } else {
    isValidToken = false;
    return isValidToken;
  }
}

checkApiResponse(response) {
  var temp = json.decode(response);
  if (temp["status"] == true) {
    return temp;
  } else {
    throw ("tokenError");
  }
}

clearToken() async {
  authToken = "";
  prefs = await SharedPreferences.getInstance();
  prefs.setString('authToken', "");
  isValidToken = false;
}

// updateMessageStatus(List<String> messageIdsList) async {
//   var map = <String, dynamic>{};

//   final Map<String, dynamic> ids = <String, dynamic>{};
//   ids['messageIds'] = messageIdsList;

//   map["ids"] = ids;

//   print("map ${map.runtimeType}");
//   print("map ${map.toString()}");

//   print(json.encode(ids));
//   final response =
//       await http.post(Uri.parse(APP_URL + '/c/messages/update_status'),
//           headers: {
//             'authentication-token': await getTokenApi(),
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           body: map);
//   print(response.body.toString());
//   if (response.statusCode == 200) {
//     print(response.body.toString());
//     var obj = checkApiResponse(response.body.replaceAll("\$", ""));
//     //json.decode(response.body.replaceAll("\$", ""));
//     try {} catch (Exp) {
//       clearToken();
//       await customerRegisterInfo();
//     }
//   } else {
//     clearToken();
//     throw ("Update Chat List Failed");
//   }
// }
