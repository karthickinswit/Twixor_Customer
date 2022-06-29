import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/helper_files/utilities_files.dart';
import 'package:twixor_customer/main.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
import 'package:twixor_customer/models/SavedDataModel.dart';
import 'package:twixor_customer/models/SendMessageModel.dart';
import 'package:twixor_customer/models/SocketResponseModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';

IOWebSocketChannel? channel;
bool isSocketConnection = false;
var channelStream;
var bSubject = new BehaviorSubject();
var chatPageSocket = new BehaviorSubject();
var mainSocket = new BehaviorSubject();
StreamController strmControl = new StreamController();
StreamSubscription? subscription;
StreamSubscription? mainSubscription;
var aSubject = new BehaviorSubject();
// StreamSubscription? streamSubscription;
late SharedPreferences prefs;
Timer? _timer;
int HEARTBEAT_INTERVAL_TIME = 30000;
int MISSED_HEARTBEATS = 0;
int MAX_MISSED_HEARTBEATS = 2;
// heartbeatIntervalTimer = null;
Map<String, String> heartbeat_msg = {"action": "ping"};

Future<bool> SocketConnect() async {
  Map<String, String> mainheader = {
    "Content-type": "application/json",
    "authentication-token": await getTokenApi()!
  };

  try {
    getCloseSocket();

    channel = IOWebSocketChannel.connect(
        APP_URL.replaceAll("http", "ws") + "/actions",
        headers: mainheader);

    //print("Channel sink ${await channel!.sink.done}");
    print("WebSocket-->${channel!.hashCode}");
    print("InnerWebSocket-->${channel!.innerWebSocket.hashCode}");
    prefs = await SharedPreferences.getInstance();

    channel!.stream.listen(
      (data) {
        //strmControl.add(event);
        setupPingPong();

        var message1 = json.decode(data);
        //print("Socket ErrMsg ${event.toString()}");

        // print("Main PageMessage ${data.toString()}");
        message1 = json.decode(data);
        if (message1["action"] == "pong") {
          MISSED_HEARTBEATS = 0;
          print(message1.toString());
        }
        if (message1["action"] == "onOpen") {
          print("Connection establised.");
          isSocketConnection = true;
        } else if (message1["action"] == "agentReplyChat") {
          var json = SocketResponse.fromJson(message1);
          var chatId = json.content![0].response!.chat!.chatId;
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;
          if (chatId == chatUser!.value.chatId) {
            messages!.value = swapMsg(k);
            messages!.notifyListeners();
            chatUser!.value.messages = messages!.value;
            chatUser!.value.messageText = k[0].messageContent;

            chatUser!.notifyListeners();
          }

          //       print("Message sent Socket");
          //       print(message1.toString());
          //       print(userdata!.name);
          //       var json = SocketResponse.fromJson(message1);
        } else if (message1["action"] == "agentPickupChat") {
          var json = SocketResponse.fromJson(message1);
          var chatId = json.content![0].response!.chat!.chatId;
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;
          List<ChatAgent> m = json.content![0].response!.users!;
          //       actionBy =
          //           json.content![0].response!.chat!.messages!.value[0].actionBy.toString();
          //       print(message1.toString());
          if (chatId == chatUser!.value.chatId) {
            messages!.value = swapMsg(k);
            messages!.notifyListeners();
            chatUser!.notifyListeners();
            chatUser!.value.actionBy =
                json.content![0].response!.users![1].id.toString();
            chatUser!.notifyListeners();
            chatAgents = m;

            isAlreadyPicked = true;
            canCreateChat = false;
            //chatUser = m;
          }
          //       chatAgents = m.cast<ChatAgent>();

          //       prefs1!.setBool('chatCreated', true); else if (message1["action"] == "agentReplyChat") {

        } else if (message1["action"] == "agentEndChat") {
          var json = SocketResponse.fromJson(message1);
          var chatId = json.content![0].response!.chat!.chatId;
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;

          print("ChatId $chatId-->${chatUser!.value.chatId}");
          print(json.content![0].response!.chat!.messages.toString());
          if (chatId == chatUser!.value.chatId) {
            messages!.value = swapMsg(k);
            messages!.notifyListeners();
            var temp;
            chatUser!.value = ChatUsers(
                name: "",
                messageText: "",
                imageURL: "",
                time: "",
                msgindex: 0,
                messages: chatUser!.value.messages,
                actionBy: "",
                chatId: "",
                eId: "",
                chatAgents: chatAgents,
                state: "",
                newMessageCount: "",
                isRated: false);
            // messages!.value = [];
            chatUser!.notifyListeners();
            print(json.content![0].response!.chat!.messages.toString());
            // setState(() {});
            // prefs.setString('chatId', "");
            isAlreadyPicked = false;
            canCreateChat = true;
            //getCloseSocket();
          }

          // print(chatUsers.length);
          // if (index != null) chatUsers.removeAt(index);
          //  if (index1 != null) chatUsers1.removeAt(index1);

        } else if (message1["action"] == "customerStartChat") {
          print("Customer Start Chat");
          var json = SocketResponse.fromJson(message1);
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;
          var chatId = json.content![0].response!.chat!.chatId;
          print(message1.toString());
          if (chatId == chatUser!.value.chatId) {
            messages!.value = swapMsg(k);
            messages!.notifyListeners();
            chatUser!.value.chatId = chatId;
            chatUser!.value.messageText = "You Started the chat!";

            chatUser!.notifyListeners();
            canCreateChat = false;
          }
          //         messages!.value.addAll(k);
          // print("mainPageMessage ${data.toString()}");
        } else if (message1["action"] == "customerReplyChat") {
          print("Message received Socket");
          var json = SocketResponse.fromJson(message1);
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;
          var chatId = json.content![0].response!.chat!.chatId;

          if (chatId == chatUser!.value.chatId) {
            messages!.value = swapMsg(k);
            messages!.notifyListeners();
            chatUser!.value.messageText =
                json.content![0].response!.chat!.messages!.last.messageContent;
            chatUser!.notifyListeners();
          }
        } else if (message1["action"] == "agentThankyou") {
          print("Message received Socket");
          print("agentThankyou $message1");
          var json = SocketResponse.fromJson(message1);
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;
          var chatId = json.content![0].response!.chat!.chatId;

          if (chatId == chatUser!.value.chatId) {
            messages!.value = swapMsg(k);
            messages!.notifyListeners();
            chatUser!.value.messageText =
                json.content![0].response!.chat!.messages!.last.messageContent;
            chatUser!.value.isRated = true;

            chatUser!.value = ChatUsers(
                name: "",
                messageText: "",
                imageURL: "",
                time: "",
                msgindex: 0,
                messages: chatUser!.value.messages,
                actionBy: "",
                chatId: "",
                eId: "",
                chatAgents: chatAgents,
                state: "",
                newMessageCount: "",
                isRated: true);
            // messages!.value = [];
            chatUser!.notifyListeners();
          }
        } else if (message1["action"] == "chatError") {
          //       print("waitingTransferAccept");
          ChatMessage k = ChatMessage(
              messageContent: "Please wait until the Agent has Pickup a Chat",
              messageType: "receiver",
              isUrl: false,
              contentType: "MSG",
              url: url,
              actionBy: chatUser!.value.actionBy,
              attachment: new Attachment(),
              actionType: "3",
              actedOn: DateTime.now().toUtc().toString(),
              eId: chatUser!.value.eId);

          messages!.value.add(k);
          messages!.notifyListeners();
        }

        // streamBuilding(mainSocket.stream)
        // aSubject.add(event);
        // if (!bSubject.isClosed) bSubject.sink.add(event);
        // if (!chatPageSocket.isClosed) chatPageSocket.sink.add(event);
        // if (!mainSocket.isClosed) mainSocket.sink.add(data);
      },
      onDone: () async {
        debugPrint('ws error onDone ${channel!.closeCode} ');
        debugPrint('ws error onDone ${channel!.closeReason} ');
        isSocketConnection = false;
        if (channel!.closeCode != 4001 &&
            channel!.closeCode != 1005 &&
            channel!.closeCode != 1000 &&
            channel!.closeCode != null) {
          if (channel!.closeCode == 1002) {
            ErrorAlert(alertContext, "Network is Unreachable");
            errorToast("Network is Unreachable");
          }
          
          // chatUser!.value = ChatUsers(
          //     name: "",
          //     messageText: "",
          //     imageURL: "",
          //     time: "",
          //     msgindex: 0,
          //     messages: [],
          //     actionBy: "",
          //     chatId: "",
          //     eId: "",
          //     chatAgents: chatAgents,
          //     state: "",
          //     newMessageCount: "",
          //     isRated: false);
          // // messages!.value = [];
          // chatUser!.notifyListeners();
          errorToast("Socket Failed Try to Reconnect");
          // if (channel!.closeCode == 4001) {
          //   // FlutterRestart.restartApp();
          //   clearToken();
          //   // Navigator.pushReplacement(
          //   //   currentContext,
          //   //   MaterialPageRoute<dynamic>(
          //   //     builder: (BuildContext context) => CustomerApp(
          //   //         customerId: userCustomerId,
          //   //         countryCode: cCode,
          //   //         eId: userEid,
          //   //         mainPageTitle: MainPageTitle,
          //   //         theme: customTheme),
          //   //   ),
          //   // );
          // }
          clearToken();
          SocketConnect();
        }
        if(channel!.closeCode == 4001)
        {
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
              newMessageCount: "",
              isRated: false);
          // messages!.value = [];
          chatUser!.notifyListeners();
          clearToken();
          SocketConnect();
        };

        //clearToken();
        // SocketConnect();
      },
      onError: (error) {
        isSocketConnection = false;
        print("websocket onError: ${channel!.closeCode}");
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
            newMessageCount: "",
            isRated: false);
        // messages!.value = [];
        chatUser!.notifyListeners();

        errorToast("socket Connection Failed");
        throw ('socket Connection Failed');

        // clearToken();
        // debugPrint('ws error $error');
        // SocketConnect();
      },
    );

    //streamBuilder(mainSocket.stream)

    // isSocketConnection = true;
  } catch (Exp) {
    //ErrorAlert(context, msg)
    isSocketConnection = false;
    //return false;
  }
  return isSocketConnection;
}

void setupPingPong() {
  if (_timer != null) {
    _timer!.cancel();
  }
  MISSED_HEARTBEATS = 0;
  _timer = Timer.periodic(const Duration(seconds: 30), (_) {
    print("Ping Pinned after 30s");

    if (MISSED_HEARTBEATS >= MAX_MISSED_HEARTBEATS) {
      _timer!.cancel();
      SocketConnect();
      return;
    }

    SendMessage sMessage = new SendMessage();
    sMessage.action = "ping";
    sMessage.actionBy = 0;
    sMessage.actionType = 0;
    sMessage.chatId = '';
    sMessage.eId = 0;
    sMessage.message = "";
    sMessage.contentType = "";
    sMessage.attachment = new Attachment();

    sendmessage(sMessage);
    MISSED_HEARTBEATS += 1;
  });
  // window.setInterval(doStuffCallback, 1000)
}

SocketReConnect() async {
  Map<String, String> mainheader = {
    "Content-type": "application/json",
    "authentication-token": await getTokenApi()!
  };
  try {
    channel = IOWebSocketChannel.connect(
        APP_URL.replaceAll("http", "ws") + "/actions",
        headers: mainheader);
  } catch (Exp) {
    //ErrorAlert(context, msg)
    isSocketConnection = false;
  }
  getSubscribe();
}

getSubscribe() {
  mainSubscription = mainSocket.stream.listen((event) {});
  return mainSubscription;
}

getCloseSocket() {
  if (channel != null) {
    print(channel);
    channel!.sink.close();
    print("Socket closed");
    isSocketConnection = false;
  }
}

// SocketObservable() {
//   channel!.stream.listen((event) {
//     //strmControl.add(event);
//     {}
//   });
// }

// bSubject.sink.add(channel!.stream.asBroadcastStream());

// channel!.stream.asBroadcastStream().listen((event) {
//   if (!bSubject.isClosed) {
//     bSubject.add(event);
//   }
// });

Future<void> sendmessage(SendMessage sendMessage) async {
  // IOWebSocketChannel? channel;
  //channel IP : Port\\"ws://192.168.0.109:6060/$myid"

  // if (isSocketConnection == false) {
  //   SocketConnect();
  // }
  var data = {};
  data["action"] = sendMessage.action;
  data["actionBy"] = sendMessage.actionBy;
  data["actionType"] = sendMessage.actionType;
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
  if (isSocketConnection == false) {
    SocketConnect();
  }
  var data = {};
  data["action"] = sendMessage.action; //"chatMessageStatus";
  data["actionIds"] = sendMessage.actiondIds;
  data["chatId"] = sendMessage.chatId;
  data["from"] = 2;
  data["state"] = 2;

  // print(json.encode(data));
  channel!.sink.add(json.encode(data));
}

Future<void> sendRatingMsg(SendMessage sendMessage, int rating) async {
  // IOWebSocketChannel? channel;
  //channel IP : Port\\"ws://192.168.0.109:6060/$myid"

  // if (isSocketConnection == false) {
  //   SocketConnect();
  // }
  var data = {};
  data["action"] = "customerRateChat";
  data["chatId"] = sendMessage.chatId;
  // data["contentType"] = sendMessage.contentType;
  data["eId"] = sendMessage.eId;
  data["comment"] = sendMessage.message;
  data["rating"] = rating;

  print(json.encode(data).toString());
  channel!.sink.add(json.encode(data)); //send message to reciever channel
}

class WebsocketsProvider extends ChangeNotifier {
  SocketResponse? srMessage;
  int _wsEventTrack = 0;
  int get wsEventTrack => _wsEventTrack;
  set wsEventTrack(value) => _wsEventTrack = value;

  void getMessage(SocketResponse srMessage) {
    srMessage = srMessage;
    notifyListeners(); // IMPORTANT
  }

  void StreamSubscribe() {
    StreamSubscription subscription = channel!.stream.listen((payload) {
      var tempResponse = jsonDecode(payload.toString());
      if (tempResponse['action'] == 'onOpen') {}
      //ws connected and right data received
      print('triggered');
      // print(payload.toString());

      getMessage(SocketResponse.fromJson(tempResponse));
    });
  }
}

errorToast(String errortext) {
  Fluttertoast.showToast(
      msg: errortext,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);
}
