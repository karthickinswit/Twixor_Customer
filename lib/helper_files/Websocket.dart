import 'dart:async';
import 'dart:convert';

import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/models/SendMessageModel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

IOWebSocketChannel? channel;
bool isSocketConnection = false;
var channelStream;

SocketConnect() async {
  Map<String, String> mainheader = {
    "Content-type": "application/json",
    "authentication-token": await getTokenApi()!
  };
  try {
    channel = IOWebSocketChannel.connect(
        APP_URL.replaceAll("http", "ws") + "/actions",
        headers: mainheader);
    //print("Channel sink ${await channel!.sink.done}");

    isSocketConnection = true;
  } catch (Exp) {
    //ErrorAlert(context, msg)
    isSocketConnection = false;
  }
}

getCloseSocket() async {
  print(channel);
  channel!.sink.close(status.goingAway);
  print("Socket closed");
  isSocketConnection = false;
}

Stream getSocketResponse() {
  channel!.stream.asBroadcastStream();

  return channel!.stream;
}

Future<void> sendmessage(SendMessage sendMessage) async {
  // IOWebSocketChannel? channel;
  //channel IP : Port\\"ws://192.168.0.109:6060/$myid"

  var data = {};
  data["action"] = sendMessage.action;
  //data["actionBy"] = sendMessage.actionBy;
  // data["actionType"] = sendMessage.actionType;
  data["attachment"] =
      sendMessage.attachment!.url != null ? sendMessage.attachment : "";
  data["chatId"] = sendMessage.chatId;
  data["contentType"] = sendMessage.contentType;
  data["eId"] = sendMessage.eId;
  data["message"] = sendMessage.message;
  data["service"] = "";
  print(json.encode(data).toString());
  channel!.sink.add(json.encode(data)); //send message to reciever channel
}

Future<void> updateMessageStatus(SendMessage sendMessage) async {
  var data = {};
  data["action"] = sendMessage.action; //"chatMessageStatus";
  data["actionIds"] = sendMessage.actiondIds;
  data["chatId"] = sendMessage.chatId;
  data["from"] = 2;
  data["state"] = 2;
  print(json.encode(data));
  channel!.sink.add(json.encode(data));
}
