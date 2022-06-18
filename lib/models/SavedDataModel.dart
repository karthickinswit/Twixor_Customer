import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/helper_files/Websocket.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';

List<ChatUsers> missedChatUsers = [];

ValueNotifier<ChatUsers>? chatUser = ValueNotifier(ChatUsers(
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
    isRated: false));

List<ChatAgent> chatAgents = [];
late SharedPreferences prefs;
late BuildContext alertContext;

ValueNotifier<List<ChatMessage>>? messages = ValueNotifier([]);

bool isAlreadyPicked = false;

bool canCreateChat = false;
ScrollController _controller = ScrollController(initialScrollOffset: 10);

_scrollToEnd(int o) async {
  _controller.animateTo(_controller.position.maxScrollExtent + 1000 + o,
      duration: const Duration(microseconds: 60), curve: Curves.fastOutSlowIn);
}

// var tempChatUser = {
//   "chatId": "06d9bdb4acef11eca57cae7df2d88e58",
//   "cId": 2612,
//   "eId": 374,
//   "state": 2,
//   "customerName": "8190083902",
//   "customerNumber": "+918190083902",
//   "customerIconUrl": "",
//   //ChatMessage.fromAPItoJson(temp3)
//   //print(v);
// };

// var temp3 = {
//   "message": "hi",
//   "contentType": "TEXT",
//   "imageUrl": "",
//   "postedOn": {"date": 1648290322384},
//   "actionType": 0,
//   "actionBy": 2612,
//   "status": 2,
//   "actionId": "da03f9a77b224f7f8dfec662a8b65422",
//   "actedOn": "2022-03-26T10:25:22Z",
//   "actedDateTime": {"date": 1648290322000}
// };
// var temp = [
//   {
//     "message": "hi",
//     "contentType": "TEXT",
//     "imageUrl": "",
//     "postedOn": {"date": 1648290322384},
//     "actionType": 0,
//     "actionBy": 2612,
//     "status": 2,
//     "actionId": "da03f9a77b224f7f8dfec662a8b65422",
//     "actedOn": "2022-03-26T10:25:22Z",
//     "actedDateTime": {"date": 1648290322000}
//   },
//   {
//     "actionType": 2,
//     "actionBy": 2609,
//     "actionId": "7d538defc3c7451080a99a6280a242d1",
//     "actedOn": "2022-03-26T10:28:02Z",
//     "actedDateTime": {"date": 1648290482000}
//   },
//   {
//     "message": "sdajdhsag\n",
//     "contentType": "TEXT",
//     "imageUrl": "",
//     "postedOn": {"date": 1648290485512},
//     "actionType": 3,
//     "actionBy": 2609,
//     "status": 2,
//     "attachment": {},
//     "actionId": "48e066a8ddc34a81b4f93a8a91bed194",
//     "actedOn": "2022-03-26T10:28:05Z",
//     "actedDateTime": {"date": 1648290485000}
//   },
//   {
//     "message": "kjadgshb\n",
//     "contentType": "TEXT",
//     "imageUrl": "",
//     "postedOn": {"date": 1648290486598},
//     "actionType": 3,
//     "actionBy": 2609,
//     "status": 2,
//     "attachment": {},
//     "actionId": "2149eec195de4256840521c4dcdf25f0",
//     "actedOn": "2022-03-26T10:28:06Z",
//     "actedDateTime": {"date": 1648290486000}
//   },
//   {
//     "message": "",
//     "contentType": "IMAGE",
//     "imageUrl": "",
//     "postedOn": {"date": 1648290525358},
//     "actionType": 3,
//     "actionBy": 2609,
//     "status": 0,
//     "attachment": {
//       "isImage": true,
//       "name": "reload-1.1s-200px_623eeadd40ada25a642574e8.png",
//       "type": "IMAGE",
//       "url": "https://engagedev.knostos.com/twixor/drive/docs/623eeadd40ada25a642574e9"
//     },
//     "actionId": "57040f768c454a43bb73734ea9771a97",
//     "actedOn": "2022-03-26T10:28:45Z",
//     "actedDateTime": {"date": 1648290525000}
//   }
// ];

// checkCommonfunc() {
//   Future.delayed(const Duration(milliseconds: 10000), () {
// // Here you can write your code

//     // temp.forEach((v) {
//     //   messages!.add(ChatMessage.fromAPItoJson(v));

//       print("Second Added ${v.toString()}");
//       //print(v);
//     });
//     print("After 10 seconds Messages length-->${messages!.length}");
//   });
// }

//-----------------

/// Represents a number counter that can be incremented.
/// Notifies [Event] handlers (subscribers) when incremented.

swapMsg(List<ChatMessage> msgs) {
  List<ChatMessage> tempMessages = messages!.value;

  tempMessages.addAll(msgs);
  return tempMessages;
}

checkChatID() async {
  prefs = await SharedPreferences.getInstance();
  var storedchatId = prefs.getString('chatId') ?? "";

  print("storedChatID-->$storedchatId");
  if (storedchatId != "") {
    sleep(const Duration(seconds: 1));
    print("1-->${storedchatId.runtimeType}");
    if (await getChatUserInfo(storedchatId)) {
      // print("2-->");
      if (chatUser!.value.state == "2") {
        // print("CheckState--> ${chatUser!.value.toJson()}");
        isAlreadyPicked = true;
        if (!isSocketConnection) SocketConnect();
        // print("3--> ${chatUser!.value.toJson()}");
        canCreateChat = false;
        return await chatUser;
      } else {
        isAlreadyPicked = false;
        canCreateChat = true;
        // print("4--> ");
        if ((chatUser!.value.chatId != "" || chatUser!.value.chatId != null) &&
            chatUser!.value.state != "3" &&
            chatUser!.value.state != "4") {
          // print("5--> ");
          if (!isSocketConnection) SocketConnect();
          canCreateChat = false;
          return await chatUser;
        } else {
          // print("6--> ");
          isAlreadyPicked = false;
          canCreateChat = true;
          return await null;
        }
      }
    }
  } else {
    canCreateChat = true;
    return null;
  }
}
