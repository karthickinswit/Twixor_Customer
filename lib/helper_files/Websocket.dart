import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
import 'package:twixor_customer/models/SendMessageModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:web_socket_channel/io.dart';

import '../chatDetailPage.dart';

class Attachement {
  String? id;
  String? docType;
  String? docFileUrl;

  Attachement(this.id, this.docType, this.docFileUrl);
}

class MessageData {
  //message data model
  String msgtext, userid;
  bool isme;
  MessageData(
      {required this.msgtext, required this.userid, required this.isme});
}

IOWebSocketChannel? channel;
bool SocConnection = false;

channelconnect() {
  //function to connect

  Map<String, String> mainheader = {
    "Content-type": "application/json",
    "authentication-token": authToken!
  };
  try {
    channel = IOWebSocketChannel.connect(
        APP_URL.replaceAll("http", "ws") + "/actions",
        headers: mainheader);
  } catch (Exp) {
    print("SocketError");
  }
  //channel IP : Port\\"ws://192.168.0.109:6060/$myid"
  channel!.stream.listen((message) {
    print((message.toString()));
    var message1 = json.decode(message);
    if (message1["action"] == "onOpen") {
      SocConnection = true;

      print("Connection establised.");
    }
    //   } else if (message1["action"] == "customerReplyChat") {
    //     print("Message sent");
    //   } else if (message1 == "customerStartChat") {
    //     print("Customer Start Chat");
    //   } else if (message1 == "waitingInviteAccept") {
    //     print("waitingInviteAccept");
    //   } else if (message1 == "waitingTransferAccept") {
    //     print("waitingTransferAccept");
    //   }
    // },
    // onDone: () {
    //if WebSocket is disconnected
    // print("Web socket is closed");

    // return connected;
  });
}

getSocketResponse(String msgAction) async {
  // IOWebSocketChannel? channel;
  try {
    Map<String, String> mainheader = {
      "Content-type": "application/json",
      "authentication-token": authToken!
    };

    // channel = IOWebSocketChannel.connect(
    //     APP_URL.replaceAll("https://", "wss://") + "/actions",
    //     headers: mainheader);
    channel!.stream.listen(
      (message) {
        var message1 = json.decode(message);
        if (message1["action"] == "onOpen") {
          // connected = true;

          print("Connection establised.");
        } else if (message1["action"] == "customerReplyChat") {
          print("Message sent");
        } else if (message1 == "customerStartChat") {
          print("Customer Start Chat");
          return message;
        } else if (message1 == "waitingInviteAccept") {
          print("waitingInviteAccept");
        } else if (message1 == "waitingTransferAccept") {
          print("waitingTransferAccept");
        }
      },
      onDone: () {
        //if WebSocket is disconnected
        print("Web socket is closed");
        // setState(() {
        //   //connected = false;
        // });
      },
      onError: (error) {
        print(error.toString());
      },
    );
  } catch (_) {
    print("SocketIO Error");
  }
}

Future<void> sendmessage(SendMessage sendMessage) async {
  // IOWebSocketChannel? channel;
  bool connected = false;

  Map<String, String> mainheader = {
    "Content-type": "application/json",
    "authentication-token": authToken!
  };

  var channel = IOWebSocketChannel.connect(
      APP_URL.replaceAll("http", "ws") + "/actions",
      headers: mainheader); //channel IP : Port\\"ws://192.168.0.109:6060/$myid"

  var data = {};
  data["action"] = sendMessage.action;
  //data["actionBy"] = sendMessage.actionBy;
  // data["actionType"] = sendMessage.actionType;
  // data["attachment"] =
  //     sendMessage.attachment!.url != null ? sendMessage.attachment : {};
  data["chatId"] = sendMessage.chatId;
  data["contentType"] = sendMessage.contentType;
  data["eId"] = sendMessage.eId;
  data["message"] = sendMessage.message;
  data["service"] = "";
  //print(json.encode(data).toString());
  channel.sink.add(json.encode(data)); //send message to reciever channel
}
