// ignore_for_file: await_only_futures, duplicate_import, unnecessary_import, avoid_print, non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/main.dart';

import 'package:twixor_customer/models/SendMessageModel.dart';
import 'package:twixor_customer/models/SocketResponseModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'helper_files/Websocket.dart';
import 'helper_files/utilities_files.dart';
import 'helper_files/webView.dart';
import 'API/apidata-service.dart';
import 'dart:ui';
import 'package:mime/mime.dart' show lookupMimeType;
import 'models/Attachmentmodel.dart';

enum ImageSourceType { gallery, camera }

// ignore: must_be_immutable
class ChatDetailPage extends StatefulWidget {
  String? jsonData = "";
  String attachmentData = "";
  List<ChatMessage> messages = [];

  ChatDetailPage(this.jsonData, this.attachmentData);

  @override
  _ChatDetailPageState createState() =>
      // ignore: no_logic_in_create_state
      _ChatDetailPageState(jsonData!, attachmentData);
}

class _ChatDetailPageState extends State<ChatDetailPage>
    with WidgetsBindingObserver {
  String? imageUrl;
  String? name;
  int? msgindex;
  String? actionBy;
  String? chatId;
  String? eId;
  String jsonData;
  String attachmentData;
  ChatUsers? userdata;
  Attachment? attachment;
  List<ChatAgent>? chatAgents;
  List<ChatMessage>? messages = [];

  List<ChatMessage> nonReadMessages = [];
  StreamController chatSocketStream = StreamController();
  ThemeData themeData = ThemeData(
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
    ).copyWith(
      secondary: Colors.green,
    ),
    appBarTheme: AppBarTheme(
      color: Colors.transparent,
      brightness: Brightness.light,
      elevation: 0,
      //I want the defaults, which is why I'm copying an 'empty' ThemeData
      //perhaps there's a better way to do this?
      textTheme: ThemeData().textTheme,
      iconTheme: ThemeData().iconTheme,
    ),
    textTheme: const TextTheme(bodyText2: TextStyle(color: Colors.purple)),
  );

  static const APP_URL = String.fromEnvironment('APP_URL',
      defaultValue: 'https://qa.twixor.digital/moc');

  // Attachment? attachments;

  var objFile;
  String? contents;
  ImagePicker picker = ImagePicker();
  var sendFileType;

  File? imageFile;

  String? preview;

  final ScrollController _controller =
      ScrollController(initialScrollOffset: 10);

  final TextEditingController msgController = TextEditingController();

  _onUrlChanged(String updatedUrl) {
    setState(() {
      //fetchPost();
    });
  }

  _scrollToEnd() async {
    _controller.animateTo(_controller.position.maxScrollExtent + 1000,
        duration: const Duration(microseconds: 600),
        curve: Curves.fastOutSlowIn);
  }

  // ScrollController _controller = ScrollController();

  _ChatDetailPageState(this.jsonData, this.attachmentData);
  @override
  initState() {
    super.initState();
    socketMsgReceive();
    setState(() {
      var temp = jsonDecode(jsonData);
      attachment = (attachmentData.isNotEmpty)
          ? Attachment.fromJson(jsonDecode(attachmentData))
          : Attachment();
      userdata = ChatUsers.fromJson1(temp);
      // print(userdata.toString());
      imageUrl = userdata!.imageURL;
      name = userdata!.name;
      msgindex = userdata!.msgindex;
      messages = userdata!.messages;
      for (ChatMessage message1 in messages!) {
        if (message1.status != "2") {
          nonReadMessages.add(message1);
        }
      }
      messages;

      chatAgents = userdata!.chatAgents!.cast<ChatAgent>();
      eId = userdata!.eId;

      //var messages=
      // this.messages =
      //     ChatMessage.fromJson(userdata.messages) as List<ChatMessage>?;
      if (attachment!.type == "MSG") {
        msgController.text = attachment!.desc!;
      } else if (attachment!.type == "URL") {
        msgController.text = attachment!.url!;
      } else if (attachment!.type == "video") {
        // msgController.text = attachment!.url!;
        // _videoController!.add(VideoPlayerController.network(attachment!.url!)
        //   ..initialize().then((_) {
        //     // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        //     setState(() {});
        //   }));
      }

      actionBy = userdata!.actionBy;

      chatId = userdata!.chatId;
      eId = userdata!.eId;
    });
    WidgetsBinding.instance?.addObserver(this);
    //socketMsgReceive();
    super.setState(() {});
    // if (attachments.isAttachment == true) {
    //   if (attachments.type == "MSG") msgController.text = attachments.desc!;
    // }
  }

  @override
  void dispose() {
    print("Chat Socket Closed");
    chatSocketStream.close();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  didPopRoute() {
    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    // print("rcvd fdata ${rcvdData['name']}");

    var listView = ListView.builder(
      controller: _controller,
      itemCount: messages!.length,
      addSemanticIndexes: true,
      padding: const EdgeInsets.only(bottom: 60),
      itemBuilder: (context, index) {
        List<String> messageIds = [];
        messageIds.add(messages![index].actionId.toString());
        print("messageIds ${messageIds.runtimeType}");
        if (messages![index].status != "2" &&
            messages![index].actionType == "1") {
          print("messageIds1");
          SendMessage temp = SendMessage();

          temp.action = "chatMessageStatus";

          temp.chatId = chatId;

          List<String> m = [];
          m.add(messages![index].actionId!);
          temp.actiondIds = m;

          updateMessageStatus(temp);
          messages![index].status = "2";
          // setState(() {});
        }

        return Column(
          children: <Widget>[
            messages![index].actionType != "3"
                ? ChatUtilMessage(messages![index], chatAgents!)
                : Container(),
            (messages![index].actionType == "1" ||
                    messages![index].actionType == "3")
                ? Container(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 5, bottom: 5),
                    child: Align(
                      alignment: (messages![index].actionType == "3"
                          ? Alignment.topLeft
                          : Alignment.topRight),
                      child: Container(
                        //width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: (messages![index].actionType == "1"
                              ? Colors.grey.shade200
                              : Colors.blue[50]),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: CheckType(index, messages![index].url),
                      ),
                    ),
                  )
                : Container(),
          ],
        );
      },
    );

    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The System Back Button is Deactivated')));
        return false;
      },
      child: MaterialApp(
          // theme: themeData,
          home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          flexibleSpace: SafeArea(
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil<dynamic>(
                          context,
                          MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) => CustomerApp(
                                  customerId: customerId, eId: eId!)),
                          (route) =>
                              false //if you want to disable back feature set to false
                          );
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => CustomerApp(
                      //             customerId: customerId, eId: eId!)));

                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(
                    width: 2,
                  ),
                  // CircleAvatar(
                  //   backgroundImage: NetworkImage(chatAgents![0].iconUrl!),
                  //   maxRadius: 20,
                  // ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Text(
                          //'${chatAgents![0].name}',
                          'Chat With Agent',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        // SizedBox(
                        //   height: 6,
                        // ),
                        // Text(
                        //   "Online",
                        //   style: TextStyle(
                        //       color: Colors.grey.shade600, fontSize: 12),
                        // ),
                      ],
                    ),
                  ),
                  // PopupMenuButton(
                  //   itemBuilder: (BuildContext bc) => [
                  //     PopupMenuItem(
                  //         child: ListTile(
                  //       title: Text(
                  //         'Coversation',
                  //         textAlign: TextAlign.left,
                  //       ),
                  //       enabled: true,
                  //     )),
                  //     PopupMenuItem(
                  //         child: ListTile(
                  //           leading: Icon(const IconData(0xf006a,
                  //               fontFamily: 'MaterialIcons')),
                  //           title: Text('Invite Agents'),
                  //           enabled: true,
                  //         ),
                  //         value: "/chat"),
                  //     PopupMenuItem(
                  //         child: ListTile(
                  //           leading: Icon(const IconData(0xe20a,
                  //               fontFamily: 'MaterialIcons')),
                  //           title: Text('Transfer Chat'),
                  //           enabled: true,
                  //         ),
                  //         value: "/chat"),
                  //     PopupMenuItem(
                  //         child: ListTile(
                  //           leading: Icon(const IconData(0xf02a3,
                  //               fontFamily: 'MaterialIcons')),
                  //           title: Text('Chat History'),
                  //           enabled: true,
                  //         ),
                  //         value: "/chat"),
                  //     PopupMenuItem(
                  //         child: ListTile(
                  //           leading: Icon(const IconData(0xe312,
                  //               fontFamily: 'MaterialIcons')),
                  //           title: Text('Close Chat'),
                  //           enabled: true,
                  //         ),
                  //         value: "/chat"),
                  //     PopupMenuItem(
                  //         child: ListTile(
                  //           leading: Icon(const IconData(0xf271,
                  //               fontFamily: 'MaterialIcons')),
                  //           title: Text('Customer Details'),
                  //           enabled: true,
                  //         ),
                  //         value: "/chat"),
                  //   ],
                  //   onSelected: (route) {
                  //     print(route);
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: <Widget>[
            // inspect(messages)

            listView,
            //  alignList("text", false, "")
            (attachment!.url != null && attachment!.url != "")
                ? alignList(attachment!)
                : alignList(Attachment(type: "MSG")),
          ],
        ),
        resizeToAvoidBottomInset: true,
      )),
    );
  }

  // ignore: non_constant_identifier_names
  ChatUtilMessage(ChatMessage message, List chatAgent) {
    var utilMsg = "";
    if (message.actionType == "2") {
      utilMsg = chatAgent[0].name.toString() + " picked up the chat";
    } else if (message.actionType == "4") {
      utilMsg = "transferred chat To You";
    } else if (message.actionType == "5") {
      utilMsg = "invited";
    } else if (message.actionType == "6") {
      utilMsg = "accepted chat invitation";
    } else if (message.actionType == "8") {
      utilMsg = "closed this chat";
    } else if (message.actionType == "9") {
      utilMsg = "left this chat";
    }
    return utilMsg != ""
        ? Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: (Colors.blue[200]),
            ),
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 5),
            child: Text(utilMsg),
          )
        : Container();
  }

  Widget alignList(Attachment localAttachment) {
    // ignore: non_constant_identifier_names
    var TextNode = [
      modelSheet(context),
      const SizedBox(
        width: 15,
      ),
      Expanded(
        child: TextField(
          textInputAction: TextInputAction.go,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              // var temp = ChatMessage(
              //     messageContent: value,
              //     messageType: "sender",
              //     isUrl: Uri.parse(value).isAbsolute,
              //     contentType: "TEXT",
              //     url: '',
              //     attachment: Attachment(),
              //     eId: eId,
              //     actionType: "1",
              //     actionBy: actionBy!,
              //     actedOn: DateTime.now().toUtc().toString());
              // messages!.add(temp);
              // print(actionBy);

              sendmessage(SendMessage(
                  action: actionBy != ""
                      ? "customerReplyChat"
                      : "customerStartChat",
                  actionBy: actionBy != "" ? int.parse(actionBy!) : 0,
                  actionType: 1,
                  attachment: Attachment(),
                  chatId: chatId!,
                  contentType: "TEXT",
                  eId: int.parse(eId!),
                  message: value));

              setState(() {
                attachment = Attachment(type: "MSG");
                attachmentData = "";
                _scrollToEnd();
                setState(() {});
              });
            }
            msgController.clear();
          },
          onChanged: (newValue) => _onUrlChanged(newValue),
          controller: msgController,
          decoration: const InputDecoration(
            hintText: "Write message...",
            hintStyle: TextStyle(color: Colors.black54),
            border: InputBorder.none,
          ),
        ),
      ),
      const SizedBox(
        width: 15,
      ),
      FloatingActionButton(
        onPressed: () {
          // print(msgController.text);
          //Attachment attachment;

          if (msgController.text.isNotEmpty) {
            // var temp = ChatMessage(
            //     messageContent: msgController.text,
            //     messageType: "sender",
            //     isUrl: Uri.parse(msgController.text).isAbsolute,
            //     contentType: "TEXT",
            //     url: '',
            //     attachment: Attachment(),
            //     eId: eId,
            //     actionType: "1",
            //     actionBy: actionBy!,
            //     actedOn: DateTime.now().toUtc().toString());
            // messages!.add(temp);
            // print(actionBy);

            sendmessage(SendMessage(
                action:
                    actionBy != "" ? "customerReplyChat" : "customerStartChat",
                actionBy: actionBy != "" ? int.parse(actionBy!) : 0,
                actionType: 1,
                attachment: Attachment(),
                chatId: chatId!,
                contentType: "TEXT",
                eId: int.parse(eId!),
                message: msgController.text));

            setState(() {
              attachment = Attachment(type: "MSG");
              attachmentData = "";
              _scrollToEnd();
              setState(() {});
            });
          }
          msgController.clear();
        },
        child: const Icon(
          Icons.send,
          color: Colors.white,
          size: 18,
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
    ];

    if (localAttachment.type == "MSG") {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
          height: (localAttachment.type == "MSG") ? 60 : 200,
          width: double.infinity,
          color: Colors.white,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: TextNode),
        ),
      );
    } else if (localAttachment.type == "IMAGE") {
      // return ImageDialog(true, localAttachment.url);
      return Align(
        alignment: Alignment.bottomLeft,
        child: FractionallySizedBox(
            child: AlertDialog(
          //contentPadding:,
          scrollable: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(60.0))),
          actions: <Widget>[
            Row(children: [
              MaterialButton(
                onPressed: () {
                  setState(() {
                    attachment = new Attachment();
                  });
                },
                color: Colors.blue,
                textColor: Colors.white,
                child: const Icon(
                  IconData(0xe16a, fontFamily: 'MaterialIcons'),
                  size: 14,
                ),
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
              SizedBox(
                  width: 120,
                  height: 100,
                  child: Image.network((localAttachment.url!),
                      fit: BoxFit.contain, width: 50, height: 50)),
              MaterialButton(
                onPressed: () {
                  sendmessage(SendMessage(
                    action: actionBy != ""
                        ? "customerReplyChat"
                        : "customerStartChat",
                    actionBy: actionBy != "" ? int.parse(actionBy!) : 0,
                    actionType: 1,
                    attachment: attachment,
                    chatId: chatId!,
                    contentType: attachment!.type,
                    eId: int.parse(eId!),
                  ));
                  setState(() {
                    attachment = Attachment(type: "MSG");
                    attachmentData = "";
                    _scrollToEnd();
                  });
                },
                color: Colors.blue,
                textColor: Colors.white,
                child: const Icon(
                  IconData(0xe571,
                      fontFamily: 'MaterialIcons', matchTextDirection: true),
                  size: 14,
                ),
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
            ]),
          ],
        )),
      );

      // return Align(
      //   alignment: Alignment.bottomLeft,
      //   child: Container(
      //     padding: const EdgeInsets.only(left: 10, bottom: 10, top: 20),
      //     height: (localAttachment.type == "MSG") ? 60 : 200,
      //     width: double.infinity,
      //     color: Colors.white,
      //     child: Row(
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: localAttachment.type == "MSG" ? (TextNode) : ImageNode),
      //   ),
      // );
    } else if (localAttachment.type == "VIDEO") {
      return Align(
        alignment: Alignment.bottomLeft,
        child: FractionallySizedBox(
            child: AlertDialog(
          //contentPadding:,
          scrollable: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(60.0))),
          actions: <Widget>[
            Row(children: [
              MaterialButton(
                onPressed: () {
                  setState(() {
                    attachment = new Attachment();
                  });
                },
                color: Colors.blue,
                textColor: Colors.white,
                child: const Icon(
                  IconData(0xe16a, fontFamily: 'MaterialIcons'),
                  size: 14,
                ),
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
              FutureBuilder<dynamic>(
                  future: getThumbnail(localAttachment.url.toString()),
                  builder: (context, snapshot) {
                    //try {} catch(Exception){}

                    // print(snapshot);
                    if (snapshot.connectionState != ConnectionState.waiting) {
                      print(snapshot.data.toString());
                      if (snapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.all(1.0),
                          width: 120.0,
                          height: 100.0,
                          child: const Positioned(
                              child: Icon(
                            IconData(0xf2b1, fontFamily: 'MaterialIcons'),
                            size: 40,
                            color: Colors.white,
                          )),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              image: DecorationImage(
                                  image: MemoryImage(snapshot.data),
                                  fit: BoxFit.cover)),
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(8), // Border width
                          decoration: BoxDecoration(
                              color: Colors.white,
                              backgroundBlendMode: BlendMode.softLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox.fromSize(
                              size: const Size.fromRadius(48), // Image radius
                              child: Image.network(
                                  APP_URL +
                                      '/drive/docs/61eba0785d9c400b3c6a8dcf',
                                  fit: BoxFit.cover),
                            ),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    } else {
                      return const CircularProgressIndicator();
                    }
                  }),
              MaterialButton(
                onPressed: () {
                  sendmessage(SendMessage(
                    action: actionBy != ""
                        ? "customerReplyChat"
                        : "customerStartChat",
                    actionBy: actionBy != "" ? int.parse(actionBy!) : 0,
                    actionType: 1,
                    attachment: attachment,
                    chatId: chatId!,
                    contentType: attachment!.type,
                    eId: int.parse(eId!),
                  ));
                  setState(() {
                    attachment = Attachment(type: "MSG");
                    attachmentData = "";
                    _scrollToEnd();
                  });
                },
                color: Colors.blue,
                textColor: Colors.white,
                child: const Icon(
                  IconData(0xe571,
                      fontFamily: 'MaterialIcons', matchTextDirection: true),
                  size: 14,
                ),
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
            ]),
          ],
        )),
      );
    } else if (localAttachment.type == "DOC") {
      return Align(
        alignment: Alignment.bottomLeft,
        child: FractionallySizedBox(
            child: AlertDialog(
          //contentPadding:,
          scrollable: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(60.0))),
          actions: <Widget>[
            Row(children: [
              MaterialButton(
                onPressed: () {
                  setState(() {
                    attachment = new Attachment();
                  });
                },
                color: Colors.blue,
                textColor: Colors.white,
                child: const Icon(
                  IconData(0xe16a, fontFamily: 'MaterialIcons'),
                  size: 14,
                ),
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  localAttachment.name.toString(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: Colors.amber),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  sendmessage(SendMessage(
                    action: actionBy != ""
                        ? "customerReplyChat"
                        : "customerStartChat",
                    actionBy: actionBy != "" ? int.parse(actionBy!) : 0,
                    actionType: 1,
                    attachment: attachment,
                    chatId: chatId!,
                    contentType: attachment!.type,
                    eId: int.parse(eId!),
                  ));
                  setState(() {
                    attachment = Attachment(type: "MSG");
                    attachmentData = "";
                    _scrollToEnd();
                  });
                },
                color: Colors.blue,
                textColor: Colors.white,
                child: const Icon(
                  IconData(0xe571,
                      fontFamily: 'MaterialIcons', matchTextDirection: true),
                  size: 14,
                ),
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
            ]),
          ],
        )),
      );
    } else {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
          height: 60,
          width: 200,
          color: Colors.white,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: TextNode),
        ),
      );
    }
  }

  Widget modelSheet(context1) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
            isDismissible: true,
            backgroundColor: Colors.transparent,
            context: context,
            builder: (builder) => bottomSheet(context1));
      },
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  CheckType(index, url) {
    if (messages![index].contentType == "TEXT") {
      var checkUrl = false;
      try {
        checkUrl = Uri.parse(messages![index].messageContent!).isAbsolute;
      } catch (Exc) {
        checkUrl = false;
      }
      if (checkUrl) {
        return UrlPreview(index);
      } else {
        return textPreview(index);
      }
    }
    if (messages![index].contentType == "DOC") {
      return UrlPreview(index);
    }
    if (messages![index].contentType == "VIDEO") {
      return videoPreview(messages![index]);
    }

    if (messages![index].contentType == "IMAGE") {
      return imagePreview(messages![index]);
    }
    // if (messages![index].contentType == "DOC") {
    //   return docPreview(index, url);
    // }

    if (messages![index].isUrl == "") {
      return (UrlPreview(index));
    } else {
      var checkUrl = false;
      try {
        checkUrl = Uri.parse(messages![index].messageContent!).isAbsolute;
      } catch (Exc) {
        checkUrl = false;
      }
      if (checkUrl) {
        return UrlPreview(index);
      } else {
        return textPreview(index);
      }
    }
  }

  Widget bottomSheet(context1) {
    return Container(
      height: 140,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(20.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(context1, Icons.insert_drive_file, Colors.indigo,
                      "Document", "document", 0),
                  const SizedBox(
                    width: 40,
                  ),
                  iconCreation(
                      context1,
                      const IconData(0xe130, fontFamily: 'MaterialIcons'),
                      Colors.pink,
                      "Camera",
                      "camera",
                      3),
                  const SizedBox(
                    width: 40,
                  ),
                  iconCreation(context1, Icons.insert_photo, Colors.purple,
                      "Gallery", "gallery", 1),
                  const SizedBox(
                    width: 0,
                  ),
                  // iconCreation(
                  //     context1,
                  //     const IconData(0xe7b4, fontFamily: 'MaterialIcons'),
                  //     Colors.orange,
                  //     "Audio",
                  //     "audio",
                  //     7)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // isFromAttachment(isFileUri, content) {
  //   showModalBottomSheet(
  //       backgroundColor: Colors.transparent,
  //       context: context,
  //       builder: (builder) => ImageDialog(true, content));
  // }

  Widget iconCreation(context1, IconData icons, Color color, String text,
      String type, int mediaType) {
    return InkWell(
      onTap: () async {
        print("icon creaation");
        if (type == "gallery") {
          //await _getFromGallery();
          //await imageFile;
          //print("img1--> ${img1}");
          Navigator.pop(context);

          await showModalBottomSheet(
              backgroundColor: Colors.transparent,
              isDismissible: true,
              context: context,
              builder: (builder) => ImageDialog(true, _getFromGallery()));
        } else if (type == "camera") {
          // await _getFromCamera();
          // var img1 = await _getFromCamera();
          Navigator.pop(context);
          // imageFile?.path == ""
          //  ? const CircularProgressIndicator()
          showModalBottomSheet(
              backgroundColor: Colors.transparent,
              context: context,
              builder: (builder) => ImageDialog(true, _getFromCamera()));
        } else if (type == "document") {
          Navigator.pop(context);
          //objFile = await chooseFileUsingFilePicker();
          print("Upload");
          //if (sendFileType == "jpg") {
          print(objFile.toString());
          //objFile?.path == ""
          // ? const CircularProgressIndicator()
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (builder) =>
                ImageDialog(true, chooseFileUsingFilePicker()),
          );
        }
        // } else {}
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(
              icons,
              // semanticLabel: "Help",
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }

  chooseFileUsingFilePicker() async {
    var result = await FilePicker.platform.pickFiles(
      withReadStream: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'mp4', 'jpeg'],
    );
    if (result != null) {
      setState(() {
        print("ObjFile ${result.files.single.runtimeType}");
        var objFile = result.files.single;
        print("objfile type --> ${objFile.runtimeType}");
        print("ObjFile ${result.files.single.runtimeType}");
        //sendFileType = result.files.single.extension;
        print("SendFileType ${sendFileType}");
        // ignore: void_checks
        return uploadSelectedFile(objFile);
      });
    }
  }

  _getFromGallery() async {
    var pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      print("pickedFile-->${pickedFile.path}");
      return uploadSelectedFilefromGallery(pickedFile);
      // return File(pickedFile.path);
      // setState(() {
      //   imageFile = File(pickedFile.path);
      // });
    }
  }

  _getFromCamera() async {
    //  picker.pickImage(source: source)
    var pickedFile = (await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 200,
      maxHeight: 200,
    ));
    var imageFile;
    if (pickedFile != null) {
      print(" pickedFile type--> ${pickedFile.runtimeType}");
      return uploadSelectedFilefromGallery(pickedFile);
      //fileImg=pickedFile as File;
      // imageFile = pickedFile.path;
      //print("pickedFile");
      //print(pickedFile);

      //return imageFile;
    }
  }

// ignore: unused_element

  Widget ImageDialog(isFileUrl, temp) {
    return FutureBuilder<dynamic>(
        future: temp,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FractionallySizedBox(
                child: Row(
              children:
                  //contentPadding:,
                  // scrollable: true,
                  // shape: const RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.all(Radius.circular(50.0))),
                  // actions:
                  <Widget>[
                Row(children: [
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    color: Colors.blue,
                    textColor: Colors.white,
                    child: const Icon(
                      IconData(0xe16a, fontFamily: 'MaterialIcons'),
                      size: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    shape: const CircleBorder(),
                  ),
                  SizedBox(
                      width: 120,
                      height: 100,
                      child: Image.network((snapshot.data),
                          fit: BoxFit.contain, width: 50, height: 50)),
                  MaterialButton(
                    onPressed: () {
                      setState(() {});
                    },
                    color: Colors.blue,
                    textColor: Colors.white,
                    child: const Icon(
                      IconData(0xe571,
                          fontFamily: 'MaterialIcons',
                          matchTextDirection: true),
                      size: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    shape: const CircleBorder(),
                  ),
                ]),
              ],
            ));
          } else {
            return const FractionallySizedBox(
                heightFactor: 10,
                child: AlertDialog(
                    //contentPadding:,
                    scrollable: true,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50.0))),
                    actions: <Widget>[
                      Center(child: CircularProgressIndicator())
                    ]));
          }
        });
  }

  Widget UrlPreview(index) {
    String? urlText = messages![index].messageContent != ""
        ? messages![index].messageContent
        : messages![index].attachment!.name;
    String? urlLink = messages![index].messageContent != ""
        ? messages![index].messageContent
        : messages![index].attachment!.url;

    return GestureDetector(
      child: Text(urlText!,
          style: const TextStyle(
              decoration: TextDecoration.underline, color: Colors.blue)),
      onTap: () async {
        if (messages![index].messageContent != "") {
          if (await canLaunch(urlLink!)) launch(urlLink);
        } else {
          var tempPath = await StoredtoFile(
              messages![index].attachment!.url!.toString(),
              messages![index].attachment!.name.toString());
          OpenFile.open(tempPath.toString());
        }
      },
    );
  }

  Widget textPreview(index) {
    print("Message Status${messages![index].status}");
    String? temp = messages![index].messageContent;
    return Column(
        crossAxisAlignment: messages![index].actionType == "1"
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Column(children: <Widget>[
            Text(
              temp!,
              //overflow: TextOverflow.clip,
              textAlign: messages![index].actionType == "1"
                  ? TextAlign.left
                  : TextAlign.right,
              softWrap: true,
              textScaleFactor: 1,
            ),
          ]),
          Container(
            margin: const EdgeInsets.only(top: 5.0, left: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                messages![index].status == "0"
                    ? const IconData(0xe73b, fontFamily: 'MaterialIcons')
                    : (messages![index].status == "2"
                        ? const IconData(0xe1f7, fontFamily: 'MaterialIcons')
                        : const IconData(0xe1f6, fontFamily: 'MaterialIcons')),
                size: 10,
                color: Colors.blue,
              ),
              const SizedBox(width: 5),
              Text(
                ConvertTime(messages![index].actedOn.toString()),
                textScaleFactor: 0.7,
                textAlign: messages![index].actionType == "1"
                    ? TextAlign.left
                    : TextAlign.right,
              ),
            ]),
          ),
        ]);
  }

  NetworkImage getNetworkImage(String url) {
    return NetworkImage(url);
  }

  Widget imagePreview(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => WebViewEx(message.attachment)));
            },
            child: Container(
              padding: const EdgeInsets.all(1.0),
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                  color: Colors.white,
                  image: DecorationImage(
                      image:
                          getNetworkImage(message.attachment!.url.toString()),
                      fit: BoxFit.cover)),
            ),
          ),
        ]),
        Container(
          margin: const EdgeInsets.only(top: 5.0),
          child: Text(ConvertTime(message.actedOn.toString()),
              textScaleFactor: 0.7,
              textAlign:
                  message.actionType == "3" ? TextAlign.left : TextAlign.right),
        ),
      ],
    );
  }

  videoPreview(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(children: <Widget>[
          GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WebViewEx(message.attachment)));
              },
              child: FutureBuilder<dynamic>(
                  future: getThumbnail(message.attachment!.url.toString()),
                  builder: (context, snapshot) {
                    //try {} catch(Exception){}

                    // print(snapshot);
                    if (snapshot.connectionState != ConnectionState.waiting) {
                      print(snapshot.data.toString());
                      if (snapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.all(1.0),
                          width: 200.0,
                          height: 100.0,
                          child: const Positioned(
                              child: Icon(
                            IconData(0xf2b1, fontFamily: 'MaterialIcons'),
                            size: 40,
                            color: Colors.white,
                          )),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              image: DecorationImage(
                                  image: MemoryImage(snapshot.data),
                                  fit: BoxFit.cover)),
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(8), // Border width
                          decoration: BoxDecoration(
                              color: Colors.white,
                              backgroundBlendMode: BlendMode.softLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox.fromSize(
                              size: const Size.fromRadius(48), // Image radius
                              child: Image.network(
                                  APP_URL +
                                      '/drive/docs/61eba0785d9c400b3c6a8dcf',
                                  fit: BoxFit.cover),
                            ),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    } else {
                      return const CircularProgressIndicator();
                    }
                  })),
        ]),
        Container(
          margin: const EdgeInsets.only(top: 5.0),
          child: Text(ConvertTime(message.actedOn.toString()),
              textScaleFactor: 0.7,
              textAlign:
                  message.actionType == "3" ? TextAlign.left : TextAlign.right),
        ),
      ],
    );
  }

  Widget docPreview(index, url) {
    // String _image1=_image;
    String? temp = messages![index].messageContent;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => WebViewEx(url)));
      },
      child: Text(
        temp!,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  getThumbnail(String videoUrl) async {
    // Image.memory(Uint8List bytes);

    var fileName = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxHeight:
            100, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
        quality: 60,
        maxWidth: 80,
        timeMs: 2000);
    // print(fileName);
    return fileName;
  }

  @override
  Future<void> didChangeMetrics() async {
    final renderObject = context.findRenderObject();
    final renderBox = renderObject as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final widgetRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
    final keyboardTopPixels =
        window.physicalSize.height - window.viewInsets.bottom;
    final keyboardTopPoints = keyboardTopPixels / window.devicePixelRatio;
    final overlap = widgetRect.bottom - keyboardTopPoints;
    if (overlap >= 0) {
      setState(() {});
    }
  }

  socketMsgReceive() async {
    print("socketMsgReceive isSocketConnection $isSocketConnection");
    var message1;
    actionBy != "" ? getCloseSocket() : "";
    //getSocketResponse().
    await SocketConnect();
    Stream chatPageSocket = await getSocketResponse();
    chatPageSocket.listen((data) async {
      message1 = json.decode(data);
      print("ChatPageMessage ${data.toString()}");
      if (message1["action"] == "onOpen") {
        // connected = true;

        print("Connection establised.");
      } else if (message1["action"] == "customerReplyChat") {
        print("Message sent Socket");
        var json = SocketResponse.fromJson(message1);
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;
        setState(() {
          messages!.addAll(k);
          _scrollToEnd();
        });
      } else if (message1["action"] == "agentReplyChat") {
        print("Message sent Socket");
        var json = SocketResponse.fromJson(message1);
        if (json.content![0].response!.users![1].name == userdata!.name) {
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;
          setState(() {
            messages!.addAll(k);
            //setState(() {});
            _scrollToEnd();
          });
          print("haai");
        }
      } else if (message1["action"] == "customerStartChat") {
        print("Customer Start Chat");
        var json = SocketResponse.fromJson(message1);
        if (json.content!.elementAt(0).response!.users!.elementAt(1).name ==
            userdata!.name) {
          setState(() {
            _scrollToEnd();
          });
        }
      } else if (message1["action"] == "agentPickupChat") {
        var json = SocketResponse.fromJson(message1);
        var chatId = json.content![0].response!.chat!.chatId;
        if (chatId == userdata!.chatId) {
          ChatUsers? k = await getChatUserInfo(context, chatId!);
          List<ChatAgent> m = json.content![0].response!.users!;
          actionBy =
              json.content![0].response!.chat!.messages![0].actionBy.toString();
          setState(() {
            messages!.addAll(k!.messages!);
            chatAgents = m.cast<ChatAgent>();
            setState(() {});
            _scrollToEnd();
          });
        }
        print("agentPickupChat");
      } else if (message1 == "waitingTransferAccept") {
        print("waitingTransferAccept");
      }
    });
  }

  void uploadSelectedFile(objFile) async {
    //---Create http package multipart request object

    var headers = {'authentication-token': authToken!};
    var mimeType = lookupMimeType(objFile.path);
    var t1 = mimeType.toString().split("/");

    var formData = {
      'message': objFile.name.toString(),
      'multipart': mimeType.toString(),
      //'file':objFile
    };

    final request = http.MultipartRequest(
      "POST",
      Uri.parse(APP_URL + "/c/drive/upload"),
    );
    request.headers.addAll(headers);
    //-----add other fields if needed
    request.fields.addAll(formData);
    // request.fields["id"] = "abc";
    //-----add selected file with request
    // ignore: unnecessary_new
    request.files.add(new http.MultipartFile(
        "file", objFile.readStream, objFile.size,
        filename: objFile.name, contentType: MediaType(t1[0], t1[1])));

    //-------Send request
    // print(request.headers.toString());
    //print(request.fields.toString());
    request
        .send()
        .then((result) async {
          http.Response.fromStream(result).then((response) {
            if (response.statusCode == 200) {
              print("Uploaded! ");
              //print('response.body ' + response.body);
              var temp = json.decode(response.body);
              print(temp["secureUrl"]);
              attachment?.url = temp["secureUrl"];
              attachment?.name = temp["name"];
              attachment?.type =
                  ContentReturnType(temp["contentType"]).toString();
              attachment?.contentType = temp["contentType"];
              attachment?.isDocument = false;
              attachment?.desc = "";
              attachment?.id = temp["id"];

              setState(() {
                Navigator.pop(context);
              });
            }

            return response.body;
          });
        })
        // ignore: invalid_return_type_for_catch_error
        .catchError((err) => print('error : ' + err.toString()))
        .whenComplete(() {});
  }

  uploadSelectedFilefromGallery(XFile objFile) async {
    //---Create http package multipart request object

    var headers = {'authentication-token': authToken!};
    var mimeType = lookupMimeType(objFile.path);
    var t1 = mimeType.toString().split("/");

    var formData = {
      'message': objFile.name.toString(),
      'multipart': mimeType.toString(),
      //'file':objFile
    };
    print(formData.toString());

    final request = http.MultipartRequest(
      "POST",
      Uri.parse(APP_URL + "/c/drive/upload"),
    );
    request.headers.addAll(headers);
    //-----add other fields if needed
    request.fields.addAll(formData);
    // request.fields["id"] = "abc";
    //-----add selected file with request
    // ignore: unnecessary_new
    var bytes = objFile.readAsBytes();

    request.files.add(http.MultipartFile.fromBytes(
        'file', await File.fromUri(Uri.parse(objFile.path)).readAsBytes(),
        filename: objFile.name, contentType: new MediaType(t1[0], t1[1])));
    print("${request.files.first.toString()}");

    //-------Send request
    // print(request.headers.toString());
    //print(request.fields.toString());
    await request
        .send()
        .then((result) async {
          http.Response.fromStream(result).then((response) {
            if (response.statusCode == 200) {
              print("Uploaded! ");
              print('response.body ' + response.body);
              var temp = json.decode(response.body);
              print(temp["secureUrl"]);
              attachment?.url = temp["secureUrl"];
              attachment?.name = temp["name"];
              attachment?.type =
                  ContentReturnType(temp["contentType"]).toString();
              attachment?.contentType = temp["contentType"];
              attachment?.isDocument = false;
              attachment?.desc = "";
              attachment?.id = temp["id"];

              setState(() {
                Navigator.pop(context);
              });
            }

            return attachment!.url;
          });
        })
        // ignore: invalid_return_type_for_catch_error
        .catchError((err) => print('error : ' + err.toString()))
        .whenComplete(() {});
  }
}
