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

class SocketDemo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<SocketDemo> {
  IOWebSocketChannel? channel; //channel varaible for websocket
  bool? connected; // boolean value to track connection status

  String myid = "222"; //my id
  String recieverid = "111"; //reciever id
  // swap myid and recieverid value on another mobile to test send and recieve
  String auth = "chatapphdfgjd34534hjdfk"; //auth key

  List<MessageData> msglist = [];
  List<ChatMessage> messages = [];

  TextEditingController msgtext = TextEditingController();

  @override
  void initState() {
    connected = false;
    msgtext.text = "";
    // channelconnect();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

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

channelconnect() {
  //function to connect
  IOWebSocketChannel? channel;
  bool connected = false;
  try {
    Map<String, String> mainheader = {
      "Content-type": "application/json",
      "authentication-token": authToken
    };

    channel = IOWebSocketChannel.connect("wss://qa.twixor.digital/moc/actions",
        headers: mainheader);

    //channel IP : Port\\"ws://192.168.0.109:6060/$myid"
    // channel.stream.listen(
    // (message) {
    //   print((message.toString()));
    //   var message1 = json.decode(message);
    //   if (message1["action"] == "onOpen") {
    //     connected = true;

    //     print("Connection establised.");
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

  } catch (_) {
    print("error on connecting to websocket.");
  }
  // return connected;
}

getSocketResponse(String msgAction) async {
  IOWebSocketChannel? channel;
  try {
    Map<String, String> mainheader = {
      "Content-type": "application/json",
      "authentication-token": authToken
    };

    channel = IOWebSocketChannel.connect("wss://qa.twixor.digital/moc/actions",
        headers: mainheader);
    channel.stream.listen(
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
  IOWebSocketChannel? channel;
  bool connected = false;

  Map<String, String> mainheader = {
    "Content-type": "application/json",
    "authentication-token": socketToken
  };
  channel = IOWebSocketChannel.connect("wss://qa.twixor.digital/moc/actions",
      headers: mainheader); //channel IP : Port\\"ws://192.168.0.109:6060/$myid"

  var data = {};
  data["action"] = sendMessage.action;
  // data["actionBy"] = sendMessage.actionBy;
  // data["actionType"] = sendMessage.actionType;
  // data["attachment"] =
  //     sendMessage.attachment!.url != null ? sendMessage.attachment : {};
  data["chatId"] = sendMessage.chatId;
  data["contentType"] = sendMessage.contentType;
  data["eId"] = sendMessage.eId;
  data["message"] = sendMessage.message;
  data["service"] = "";
  // var temp = print(json.encode(data).toString());
  channel.sink.add(json.encode(data)); //send message to reciever channel
}
