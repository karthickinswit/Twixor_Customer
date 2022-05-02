import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twixor_customer/helper_files/Websocket.dart';
import 'package:twixor_customer/helper_files/utilities_files.dart';
import 'package:twixor_customer/models/SavedDataModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:twixor_customer/main.dart';

const APP_URL = String.fromEnvironment('APP_URL',
    defaultValue: 'https://qa.twixor.digital/moc');
String url = APP_URL + '/c/enterprises/';
//const userEid = String.fromEnvironment('userEid', defaultValue: '374');
late String userEid;
late String userCustomerId;
late String userChatId;
late String cCode;
DateTime? chatCreationTime;

bool isValidToken = false;

late SharedPreferences prefs;
ListView? listView;

String? authToken;
bool isVisible = true;

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

////////////////////////////////////////////////////////
// Future<bool> _checkPrefs() async {
//   var tempCustId, tempEid;

//   prefs = await SharedPreferences.getInstance();
//   tempCustId = prefs.getString('customerId') ?? "";
//   tempEid = prefs.getString('eId') ?? "";
//   authToken = prefs.getString('authToken') ?? "";
//   //prefs.setString('title', MainPageTitle);
//   if (tempCustId == "" && tempEid == "") {
//     await clearToken();
//     prefs.setString('customerId', userCustomerId);
//     prefs.setString('eId', userEid);
//     prefs.setString('title', MainPageTitle);
//     authToken = await getTokenApi() ?? "";
//     prefs.setString('authToken', authToken!);

//     return await checktoken() ? true : await _checkPrefs();
//   } else if (tempCustId == userCustomerId && tempEid == userEid) {
//     if (authToken == "") {
//       authToken = await getTokenApi() ?? "";
//       prefs.setString('authToken', authToken!);
//       return await checktoken() ? true : await _checkPrefs();
//     } else {
//       return await checktoken() ? true : await _checkPrefs();
//     }
//   } else if (tempCustId != userCustomerId || tempEid != userEid) {
//     await clearToken();
//     prefs.setString('customerId', userCustomerId);
//     prefs.setString('eId', userEid);
//     authToken = await getTokenApi() ?? "";
//     prefs.setString('authToken', authToken!);
//     return await checktoken() ? true : await _checkPrefs();
//   } else {
//     return await checktoken() ? true : await _checkPrefs();
//   }
// }
///////////////////////////////////////////////////////

getChatUserInfo(String ChatId) async {
  var response = await http.get(Uri.parse(url + userEid + '/chat/' + ChatId),
      headers: {"authentication-token": await getTokenApi()});

  // print(response.headers.toString());
  // sleep(const Duration(seconds: 2));
  if (response.statusCode == 200) {
    var obj = checkApiResponse(response.body.replaceAll("\$", ""));
    try {
      var tempUser = obj["response"]["chat"];
      List chatuserDetails = obj["response"]["users"];
      tempUser["chatuserDetails"] = chatuserDetails;
      chatuserDetails.forEach((element) {
        print("Agnets");
        // print(element.toString());
        chatAgents.add(ChatAgent.fromJson(element));
      });
      //chatAgents = ChatAgent.fromJson(chatuserDetails) as List<ChatAgent>;
      var oh = obj["response"];
      // print(obj["response"]["chat"].runtimeType);

      chatUser!.value = ChatUsers.fromJson(tempUser);
      // messages!.value = chatUser!.value.messages!;
      // print(chatUser!.value.toJson());
      return true;

      ;
    } catch (Exp) {
      clearToken();
      // ErrorAlert(context, "Session TimeOut");
      await customerRegisterInfo();
    }
  } else {
    clearToken();
    throw ("SessionTimeOut");
  }
}

newChatCreate() async {
  var map = Map<String, dynamic>();
  map['stickySession'] = 'false';

  var response = await http.post(Uri.parse(url + userEid + '/chat/create'),
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
      // print("Chat Id generated");
      chatUser!.value.chatId = chatId;
      //websocket resume
      if (isSocketConnection == false) await SocketConnect();
      chatCreationTime = DateTime.now();
      prefs.setString('chatCreationTime', chatCreationTime!.toString());

      return chatId.toString();
    } catch (Exp) {
      // ErrorAlert(context, "Session TimeOutError");
    }
  } else {
    clearToken();
    isValidToken = false;
    //websocket pause
    //loader
    var token = await customerRegisterInfo();
    if (token) {
      newChatCreate();
    }
    throw ("New Chat Creation Failed");
  }
}

customerRegisterInfo() async {
  var map = <String, dynamic>{};

  map['name'] = userCustomerId;
  map['phoneNumber'] = userCustomerId;
  map['countryCode'] = cCode;
  map['countryAlpha2Code'] = 'IN';
  map['needVerification'] = 'false';

  map['byInvitation'] = 'false';
  map['subscribeToAll'] = 'true';
  map['enterprisesToSubscribe'] = '{"eIds":[${int.parse(userEid)}]}';
  map['clearMsgs'] = 'true';

  final response = await http
      .post(Uri.parse(APP_URL + '/account/customer/register'), body: map);

  if (response.statusCode == 200) {
    var obj = checkApiResponse(response.body.replaceAll("\$", ""));
    var token = obj["response"]["token"];
    authToken = token;
    prefs = await SharedPreferences.getInstance();
    prefs.setString('authToken', token);
    //await SocketConnect();
    return token;
  } else {
    throw ("Registration Failed");
  }
}
//4001
// getChatList() async {
//   // https://aim.twixor.com/c/enterprises/103/chats
//   List<ChatUsers> chatUsers = [];
//   var tempUrl = APP_URL +
//       'c/enterprises/chat/summary?fromDate=2019-02-16T06:34:16.859Z'; //url + userEid + '/chats
//   final response =
//       await http.get(Uri.parse(url + userEid + '/chats'), headers: {
//     'authentication-token': await getTokenApi(),
//     'Content-Type': 'application/x-www-form-urlencoded'
//   });

//   print(response.headers.toString());
//   if (response.statusCode == 200) {
//     isValidToken = true;
//     print(response.body.toString());
//     var obj = checkApiResponse(response.body.replaceAll("\$", ""));
//     //json.decode(response.body.replaceAll("\$", ""));
//     try {
//       var chats = obj["response"]["chats"];
//       if (chats.length > 0) {
//         chats.forEach((v) {
//           chatUsers.add(ChatUsers.fromJson(v));

//           //print(v);
//         });
//       }

//       //throw ("getting Chat List Failed");
//       chatUsers.add(ChatUsers.fromJson(tempChatUser));
//       return chatUsers;
//     } catch (Exp) {
//       // ErrorAlert(context, "getting Chat List Failed");
//       isValidToken = false;

//       //throw ("getting Chat List Failed");
//       return chatUsers;
//       //getChatList();
//     }
//   } else {
//     isValidToken = false;
//     clearToken();
//     await getTokenApi();

//     return chatUsers;
//     getChatList();
//   }
// }
// session start --> user register --> token --> chat --> chat close --> session active --> new chat --> check token from localstorage --> customerStartChat --> success --> live chat --> failure --> loader --> re-register --> get token

//-->customerStartChat --> attachment

//chatCreated : false --> clicked chat creation --> --> chatId --> chatCreatd : true --> chat(localStorage chatId == agentEndChat ChatId) close (inactive/agent close) --> chatCreated : false

//sendMessage common , navigator common

Future<List<ChatUsers>> getMissedChatList() async {
  List<ChatUsers> missedUsers = [];
  // https://aim.twixor.com/c/enterprises/103/chats
  List<ChatUsers> chatUsers = [];
  var tempUrl = APP_URL +
      'c/enterprises/chat/history?fromDate=2019-02-16T06:34:16.859Z'; //url + userEid + '/chats
  final response = await http.get(
      Uri.parse(url + userEid + '/chat/history?from=0&perPage=10&state=3'),
      headers: {
        'authentication-token': await getTokenApi(),
        'Content-Type': 'application/x-www-form-urlencoded'
      });

  print(response.headers.toString());
  if (response.statusCode == 200) {
    isValidToken = true;
    print(response.body.toString());
    var obj = checkApiResponse(response.body.replaceAll("\$", ""));
    print(response.body);
    //json.decode(response.body.replaceAll("\$", ""));
    try {
      var chats = obj["response"]["chats"];
      if (chats.length > 0) {
        chats.forEach((v) {
          missedUsers.add(ChatUsers.fromJson(v));
          print(v.toString());

          //print(v);
        });
        List chatuserDetails = obj["response"]["users"];
        //  chatuserDetails;
        chatuserDetails.forEach((element) {
          print("Agnets");
          // print(element.toString());
          chatAgents.add(ChatAgent.fromJson(element));
        });
      }

      //throw ("getting Chat List Failed");

      return missedUsers;
    } catch (Exp) {
      // ErrorAlert(context, "getting Chat List Failed");
      isValidToken = false;

      // throw ("getting Chat List Failed");
      return missedUsers;
      //getChatList();
    }
  } else {
    // isValidToken = false;
    // clearToken();
    // await getTokenApi();
    // print("Token Expiry {}")
    print(response.statusCode.toString());
    clearToken();

    // throw ("getting Chat List Failed");

    return getMissedChatList();
  }
}

checktoken() async {
//url + user + '/chats
  final response =
      await http.get(Uri.parse(url + userEid + '/chats'), headers: {
    'authentication-token': await getTokenApi(),
    'Content-Type': 'application/x-www-form-urlencoded'
  });

  print(response.headers.toString());
  if (response.statusCode == 200) {
    isValidToken = true;
    return true;
  } else {
    isValidToken = true;
    return true;
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
