// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';

class ChatUsers {
  String? name;
  String? messageText;
  String? imageURL;
  String? time;
  int? msgindex;
  List<ChatMessage>? messages;
  String? actionBy;
  String? chatId;
  String? eId;
  List? chatAgents;
  String? state;
  String? newMessageCount;
  ChatUsers(
      {required this.name,
      required this.messageText,
      required this.imageURL,
      required this.time,
      required this.msgindex,
      required this.messages,
      required this.actionBy,
      required this.chatId,
      required this.eId,
      required this.chatAgents,
      required this.state,
      required this.newMessageCount});

  ChatUsers.fromJson(Map<String, dynamic> json) {
    name = json["customerName"] != null ? json["customerName"].toString() : "";
    messageText =
        json["lastMessage"] != null ? json["lastMessage"].toString() : "";
    imageURL = json["customerIconUrl"] == null || json["customerIconUrl"] == ""
        ? 'https://aim.twixor.com/drive/docs/61ef9d425d9c400b3c6c03f9'
        : json["customerIconUrl"];
    if (json["lastModifiedOn"] == null) {
      time = "";
    } else {
      time = (json["lastModifiedOn"]["date"] != null
          ? json["lastModifiedOn"]["date"].toString()
          : "");
    }

    actionBy =
        json["handlingAgent"] != null ? json["handlingAgent"].toString() : "";
    chatId = json["chatId"] != null ? json["chatId"].toString() : "";
    eId = json["eId"] != null ? json["eId"].toString() : "";
    messages = <ChatMessage>[];
    if (json.containsKey('messages')) {
      json['messages'].forEach((v) {
        messages!.add(ChatMessage.fromAPItoJson(v));
        //print(v);
      });
    }

    actionBy =
        json['handlingAgent'] != null ? json['handlingAgent'].toString() : "";
    chatId = json['chatId'] != null ? json["chatId"].toString() : "";
    ;
    eId = json['eId'] != null ? json["eId"].toString() : "";
    chatAgents = <ChatAgent>[];
    if (json.containsKey('chatuserDetails')) {
      json['chatuserDetails'].forEach((v) {
        chatAgents!.add(ChatAgent.fromJson(v));
        //print(v);
      });
    }
    state = json['state'] != null ? json["state"].toString() : "";
    newMessageCount = "0";
  }

  ChatUsers.fromJson1(Map<String, dynamic> data) {
    imageURL = data['imageUrl'];
    name = data['name'];
    messageText = data['messageText'];
    msgindex = data['msgindex'];
    time = data['time'];
    actionBy = data['actionBy'];
    chatId = data['chatId'];
    eId = data['eId'];
    actionBy = data["actionBy"];
    state = data["state"] as String;
    newMessageCount = "0";
    messages = <ChatMessage>[];
    chatAgents = <ChatAgent>[];
    var temp = data["messages"];
    if (temp != null) {
      temp.forEach((v) {
        //print(v.toString());
        messages!.add(ChatMessage.fromLocaltoJson(v));
      });
    }
    if (data.containsKey('chatuserDetails')) {
      for (var i = 0; i < data['chatuserDetails'].length; i++) {
        chatAgents!.add(ChatAgent.fromJson(data['chatuserDetails'][i]));
      }
    }
  }

  Map<dynamic, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['imageUrl'] = this.imageURL;
    data['name'] = this.name;
    data['messageText'] = this.messageText;
    data['msgindex'] = this.msgindex;
    data['time'] = this.time;
    data["messages"] = this.messages;
    data['actionBy'] = this.actionBy;
    data['actionBy'] = this.actionBy;
    data['chatId'] = this.chatId;
    data['eId'] = this.eId as String;
    data['state'] = this.state as String;
    data['chatuserDetails'] = this.chatAgents;
    data['newMessageCount'] = "0";
    return data;
  }
}

class ChatAgent {
  String? sId;
  String? iconUrl;
  String? name;
  int? uId;
  int? id;
  String? type;

  ChatAgent({this.sId, this.iconUrl, this.name, this.uId, this.id, this.type});

  ChatAgent.fromJson(Map<dynamic, dynamic> json) {
    sId = json['_id'];
    iconUrl = json['iconUrl'];
    name = json['name'];
    uId = json['uId'];
    id = json['id'];
    type = json['type'];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['_id'] = this.sId;
    data['iconUrl'] = this.iconUrl;
    data['name'] = this.name;
    data['uId'] = this.uId;
    data['id'] = this.id;
    data['type'] = this.type;
    return data;
  }
}
