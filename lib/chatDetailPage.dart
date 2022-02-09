// ignore_for_file: await_only_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/main.dart';

import 'package:twixor_customer/models/SendMessageModel.dart';
import 'package:twixor_customer/models/SocketResponseModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:web_socket_channel/io.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_url_preview/simple_url_preview.dart';

import 'dart:developer';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'helper_files/Websocket.dart';
import 'helper_files/utilities_files.dart';
import 'helper_files/webView.dart';
import 'API/apidata-service.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mime/mime.dart';
import 'models/Attachmentmodel.dart';
import 'package:path_provider/path_provider.dart';

enum ImageSourceType { gallery, camera }

class ChatDetailPage extends StatefulWidget {
  String? jsonData = "";
  String attachmentData = "";
  List<ChatMessage> messages = [];

  ChatDetailPage(this.jsonData, this.attachmentData);

  @override
  _ChatDetailPageState createState() =>
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
  String _url = '';
  String jsonData;
  String attachmentData;
  ChatUsers? userdata;
  Attachment? attachment;
  List<ChatAgent>? chatAgents;
  static const APP_URL = String.fromEnvironment('APP_URL',
      defaultValue: 'https://qa.twixor.digital/moc');

  // Attachment? attachments;

  var objFile = null;
  String? contents;
  ImagePicker picker = ImagePicker();
  var sendFileType;

  File? imageFile;
  bool _visible = false;
  double _overlap = 0;

  _getFromGallery() async {
    //  picker.pickImage(source: source)
    var pickedFile = (await picker.pickImage(
      source: ImageSource.gallery,
    ));
    if (pickedFile != null) {
      setState(() {
        //fileImg=pickedFile as File;
        imageFile = File(pickedFile.path);
        //print("pickedFile");
        //print(pickedFile);
      });
    }
  }

  String? preview;

  final ScrollController _controller =
      ScrollController(initialScrollOffset: 10);

  final TextEditingController msgController = TextEditingController();

  _onUrlChanged(String updatedUrl) {
    setState(() {
      _url = updatedUrl;
      //fetchPost();
    });
  }

  _scrollToEnd() async {
    _controller.animateTo(_controller.position.maxScrollExtent + 1000,
        duration: Duration(microseconds: 600), curve: Curves.fastOutSlowIn);
  }

  List<ChatMessage>? messages = [];
  // ScrollController _controller = ScrollController();

  _ChatDetailPageState(this.jsonData, this.attachmentData);
  @override
  initState() {
    super.initState();
    setState(() {
      var temp = jsonDecode(jsonData);
      var temp2 = attachmentData.length != 0 ? jsonDecode(attachmentData) : "";
      attachment = (attachmentData.isNotEmpty)
          ? Attachment.fromJson(jsonDecode(attachmentData))
          : Attachment();
      userdata = ChatUsers.fromJson1(temp);
      // print(userdata.toString());
      this.imageUrl = userdata!.imageURL;
      this.name = userdata!.name;
      this.msgindex = userdata!.msgindex;
      this.messages = userdata!.messages;

      this.chatAgents = userdata!.chatAgents!.cast<ChatAgent>();
      this.eId = userdata!.eId;
      //var messages=
      // this.messages =
      //     ChatMessage.fromJson(userdata.messages) as List<ChatMessage>?;
      if (attachment!.type == "MSG") {
        msgController.text = attachment!.desc!;
      } else if (attachment!.type == "URL") {
        msgController.text = attachment!.url!;
      } else if (attachment!.type == "URL") {
        // msgController.text = attachment!.url!;
        // _videoController!.add(VideoPlayerController.network(attachment!.url!)
        //   ..initialize().then((_) {
        //     // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        //     setState(() {});
        //   }));
      }

      this.actionBy = userdata!.actionBy;

      this.chatId = userdata!.chatId;
      this.eId = userdata!.eId;
    });
    WidgetsBinding.instance?.addObserver(this);
    socketMsgReceive();
    super.setState(() {});
    // if (attachments.isAttachment == true) {
    //   if (attachments.type == "MSG") msgController.text = attachments.desc!;
    // }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  didPopRoute() {
    bool override;

    return new Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    // print("rcvd fdata ${rcvdData['name']}");
    var listView = ListView.builder(
      controller: _controller,
      itemCount: messages!.length,
      addSemanticIndexes: true,
      padding: EdgeInsets.only(bottom: 60),
      itemBuilder: (context, index) {
        // print(messages![index].actionType);

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
                      alignment: (messages![index].actionType == "1"
                          ? Alignment.topLeft
                          : Alignment.topRight),
                      child: Container(
                        //width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: (messages![index].actionType == "3"
                              ? Colors.grey.shade200
                              : Colors.blue[50]),
                        ),
                        padding: EdgeInsets.all(14),
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
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('The System Back Button is Deactivated')));
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            flexibleSpace: SafeArea(
              child: Container(
                padding: EdgeInsets.only(right: 16),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CustomerApp(
                                      eId: "374",
                                      customerId: "8190083902",
                                    )));

                        setState(() {});
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    // CircleAvatar(
                    //   backgroundImage: NetworkImage(chatAgents![0].iconUrl!),
                    //   maxRadius: 20,
                    // ),
                    SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
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
                  : alignList(new Attachment(type: "MSG")),
            ],
          ),
          resizeToAvoidBottomInset: true,
        ));
  }

  ChatUtilMessage(ChatMessage message, List chatAgent) {
    var utilMsg = "";
    if (message.actionType == "2")
      utilMsg = chatAgent[0].name.toString() + " picked up the chat";
    else if (message.actionType == "4")
      utilMsg = "transferred chat To You";
    else if (message.actionType == "5")
      utilMsg = "invited";
    else if (message.actionType == "6")
      utilMsg = "accepted chat invitation";
    else if (message.actionType == "8")
      utilMsg = "closed this chat";
    else if (message.actionType == "9") utilMsg = "left this chat";
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
    var TextNode = [
      modelSheet(context),
      SizedBox(
        width: 15,
      ),
      Expanded(
        child: TextField(
          onChanged: (newValue) => _onUrlChanged(newValue),
          controller: msgController,
          decoration: InputDecoration(
            hintText: "Write message...",
            hintStyle: TextStyle(color: Colors.black54),
            border: InputBorder.none,
          ),
        ),
      ),
      SizedBox(
        width: 15,
      ),
      FloatingActionButton(
        onPressed: () {
          // print(msgController.text);
          //Attachment attachment;

          if (msgController.text.isNotEmpty) {
            var temp = new ChatMessage(
                messageContent: msgController.text,
                messageType: "sender",
                isUrl: Uri.parse(msgController.text).isAbsolute,
                contentType: "TEXT",
                url: '',
                attachment: Attachment(),
                eId: eId,
                actionType: "1",
                actionBy: actionBy!,
                actedOn: new DateTime.now().toUtc().toString());
            messages!.add(temp);
            print(actionBy);

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
              attachment = new Attachment(type: "MSG");
              attachmentData = "";
              _scrollToEnd();
              setState(() {});
            });
          }
          msgController.clear();
        },
        child: Icon(
          Icons.send,
          color: Colors.white,
          size: 18,
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
    ];
    var ImageNode = [
      Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                setState(() {});
              },
              color: Colors.blue,
              textColor: Colors.white,
              child: Icon(
                const IconData(0xe16a, fontFamily: 'MaterialIcons'),
                size: 16,
              ),
              padding: EdgeInsets.all(20),
              elevation: 5,
              shape: CircleBorder(),
            ),
            Container(
              child: Container(
                  width: 120,
                  height: 200,
                  child: Image.network((localAttachment.url.toString()),
                      fit: BoxFit.contain, width: 300, height: 180)),
            ),
            MaterialButton(
              onPressed: () {
                print(actionBy);
                messages!.add(new ChatMessage(
                    messageContent: "",
                    messageType: "sender",
                    isUrl: Uri.parse(msgController.text).isAbsolute,
                    contentType: attachment!.type,
                    url: attachment!.url,
                    attachment: attachment,
                    eId: eId,
                    actionType: "1",
                    actionBy: actionBy!,
                    actedOn: new DateTime.now().toUtc().toString()));
                //  print(messages![messages!.length - 1].isUrl);
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
                  attachment = new Attachment(type: "MSG");
                  attachmentData = "";
                  _scrollToEnd();
                });
              },
              color: Colors.blue,
              textColor: Colors.white,
              child: Icon(
                const IconData(0xe571,
                    fontFamily: 'MaterialIcons', matchTextDirection: true),
                size: 16,
              ),
              padding: EdgeInsets.all(10),
              shape: CircleBorder(),
            ),
          ])
    ];
    if (localAttachment.type == "MSG") {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
          height: (localAttachment.type == "MSG") ? 60 : 200,
          width: double.infinity,
          color: Colors.white,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: localAttachment.type == "MSG" ? (TextNode) : ImageNode),
        ),
      );
    } else if (localAttachment.type == "IMAGE") {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.only(left: 10, bottom: 10, top: 20),
          height: (localAttachment.type == "MSG") ? 60 : 200,
          width: double.infinity,
          color: Colors.white,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: localAttachment.type == "MSG" ? (TextNode) : ImageNode),
        ),
      );
    }
    // else if (localAttachment.type == "VIDEO") {
    //   return Align(
    //     alignment: Alignment.bottomLeft,
    //     child: Container(
    //       padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
    //       height: (localAttachment.type == "MSG") ? 60 : 200,
    //       width: double.infinity,
    //       color: Colors.white,
    //       child: Row(
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: localAttachment.type == "MSG" ? (TextNode) : VideoNode),
    //     ),
    //   );
    // }
    else {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
          height: (localAttachment.type == "MSG") ? 60 : 200,
          width: 200,
          color: Colors.white,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: localAttachment.type == "MSG" ? (TextNode) : ImageNode),
        ),
      );
    }
  }

  Widget modelSheet(context1) {
    return GestureDetector(
      onTap: () {
        // showModalBottomSheet(
        //     isDismissible: true,
        //     backgroundColor: Colors.transparent,
        //     context: context,
        //     builder: (builder) => bottomSheet(context1));
      },
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
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
      if (checkUrl)
        return UrlPreview(index);
      else
        return textPreview(index);
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
      if (checkUrl)
        return UrlPreview(index);
      else
        return textPreview(index);
    }
  }

  Widget bottomSheet(context1) {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(18.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(context1, Icons.insert_drive_file, Colors.indigo,
                      "Document", "document", 0),
                  SizedBox(
                    width: 40,
                  ),
                  iconCreation(
                      context1,
                      const IconData(0xe380, fontFamily: 'MaterialIcons'),
                      Colors.pink,
                      "Url",
                      "url",
                      3),
                  SizedBox(
                    width: 40,
                  ),
                  iconCreation(context1, Icons.insert_photo, Colors.purple,
                      "Gallery", "gallery", 1),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(
                      context1,
                      const IconData(0xe154, fontFamily: 'MaterialIcons'),
                      Colors.orange,
                      "Message",
                      "message",
                      7),
                  SizedBox(
                    width: 40,
                  ),
                  iconCreation(
                      context1,
                      const IconData(0xe74e, fontFamily: 'MaterialIcons'),
                      Colors.teal,
                      "Upload",
                      "upload",
                      9),
                  SizedBox(
                    width: 40,
                  ),
                  // iconCreation(Icons.person, Colors.blue, "Contact"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  isFromAttachment(isFileUri, content) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (builder) => ImageDialog(true, content));
  }

  Widget iconCreation(context1, IconData icons, Color color, String text,
      String type, int mediaType) {
    return InkWell(
      onTap: () async {
        if (type == "gallery1") {
          await _getFromGallery();
          var img1 = await imageFile!.path;
          var isImage = img1.isEmpty ? true : false;
          Navigator.pop(context);
          imageFile?.path == ""
              ? CircularProgressIndicator()
              : showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (builder) => ImageDialog(true, img1));
        } else if (type == "upload") {
          await chooseFileUsingFilePicker();
          print("Upload");
          // print(sendFileType);
          if (sendFileType == "jpg") {
            // print(objFile.path);
            print(objFile.toString());
            // messages!.add(new ChatMessage(
            //   messageContent: objFile.path.toString(),
            //   messageType: "sender",
            //   isUrl: true,
            //   contentType: sendFileType,
            //   url: objFile.path.toString(),
            //   attachment: new Attachment(),
            //   actionType: "3",
            //   actionBy: actionBy!,
            // )
            // );
          }
        } else {}
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(
              icons,
              // semanticLabel: "Help",
              size: 29,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }

  _launchURL(urllink) async {
    String url = urllink;
    print("LaunchUrl");
    print(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  chooseFileUsingFilePicker() async {
    var result = await FilePicker.platform.pickFiles(
      withReadStream: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc'],
    );
    if (result != null) {
      setState(() {
        objFile = result.files.single;

        sendFileType = objFile.extension;
        // print(objFile.name);
        // print(objFile.bytes.toString());
        // print(objFile.size);
        // print(objFile.extension);
        // print(objFile.path);
        uploadSelectedFile(objFile);
      });
    }
  }

  Widget ImageDialog(isFileUrl, content) {
    return AlertDialog(
      //contentPadding:,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0))),
      actions: <Widget>[
        Row(children: [
          MaterialButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            color: Colors.blue,
            textColor: Colors.white,
            child: Icon(
              const IconData(0xe16a, fontFamily: 'MaterialIcons'),
              size: 8,
            ),
            padding: EdgeInsets.all(8),
            shape: CircleBorder(),
          ),
          isFileUrl
              ? Container(
                  width: 120,
                  height: 100,
                  child: Image.network((content),
                      fit: BoxFit.contain, width: 300, height: 180))
              : Container(
                  width: 120,
                  height: 100,
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: content,
                    ),
                  ),
                ),
          MaterialButton(
            onPressed: () {
              // messages!.add(new ChatMessage(
              //   messageContent: content.toString(),
              //   messageType: "sender",
              //   isUrl: Uri.parse(msgController.text).isAbsolute,
              //   contentType: "img",
              //   url: content.toString(),
              //   attachment: new Attachment(),
              //   actionType: "3",
              //   eId: ,
              //   actionBy: actionBy!,
              // ));
              // print(messages![messages!.length - 1].isUrl);
              setState(() {});
            },
            color: Colors.blue,
            textColor: Colors.white,
            child: Icon(
              const IconData(0xe571,
                  fontFamily: 'MaterialIcons', matchTextDirection: true),
              size: 8,
            ),
            padding: EdgeInsets.all(8),
            shape: CircleBorder(),
          ),
        ]),
      ],
    );
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
          style: TextStyle(
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
          child: Text(
            ConvertTime(messages![index].actedOn.toString()),
            textScaleFactor: 0.7,
            textAlign: messages![index].actionType == "1"
                ? TextAlign.left
                : TextAlign.right,
          ),
        ),
      ],
    );
  }

  NetworkImage getNetworkImage(String url) {
    Map<String, String> header = Map();
    return NetworkImage(url);
  }

  Widget imagePreview(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(children: <Widget>[
          new GestureDetector(
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
          new GestureDetector(
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
                          child: Positioned(
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
                          padding: EdgeInsets.all(8), // Border width
                          decoration: BoxDecoration(
                              color: Colors.white,
                              backgroundBlendMode: BlendMode.softLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox.fromSize(
                              size: Size.fromRadius(48), // Image radius
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
                    } else
                      return CircularProgressIndicator();
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
    return new GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => WebViewEx(url)));
      },
      child: Text(
        temp!,
        style: TextStyle(fontSize: 15),
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
        maxWidth: 200,
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
      setState(() {
        _overlap = overlap;
      });
    }
  }

  socketMsgReceive() async {
    IOWebSocketChannel? channel;
    try {
      Map<String, String> mainheader = {
        "Content-type": "application/json",
        "authentication-token": await getTokenApi()
      };
      var SOUrl = APP_URL.replaceAll("http", "ws") + "/actions";
      channel = await IOWebSocketChannel.connect(SOUrl, headers: mainheader);
      channel.stream.listen(
        (message) async {
          //print(message.toString());
          var message1 = json.decode(message);
          if (message1["action"] == "onOpen") {
            // connected = true;

            print("Connection establised.");
          } else if (message1["action"] == "customerReplyChat") {
            print("Message sent Socket");
            var json = SocketResponse.fromJson(message1);
            List<ChatMessage> k = json.content![0].response!.chat!.messages!;

//ChatUsers h=

            setState(() {
              // messages!.addAll(k);

              //attachmentData = "";
              //attachment = null;

              setState(() {});
              _scrollToEnd();
            });
            print("haai");
          } else if (message1["action"] == "agentReplyChat") {
            print("Message sent Socket");
            var json = SocketResponse.fromJson(message1);
            if (json.content![0].response!.users![1].name == userdata!.name) {
              List<ChatMessage> k = json.content![0].response!.chat!.messages!;

              setState(() {
                messages!.addAll(k);

                //attachmentData = "";
                //attachment = null;

                setState(() {});
                _scrollToEnd();
              });
              print("haai");
            }
          } else if (message1["action"] == "customerStartChat") {
            print("Customer Start Chat");
            var json = SocketResponse.fromJson(message1);
            if (json.content![0].response!.users![1].name == userdata!.name) {
              // List<ChatMessage> k = json.content![0].response!.chat!.messages!;
//ChatUsers h=

              setState(() {
                //messages!.addAll(k);
                //attachmentData = "";
                //attachment = null;

                setState(() {});
                _scrollToEnd();
              });
            }
            //return message;
          } else if (message1["action"] == "agentPickupChat") {
            var json = SocketResponse.fromJson(message1);
            var chatId = json.content![0].response!.chat!.chatId;
            if (chatId == userdata!.chatId) {
              ChatUsers? k = await getChatUserInfo(context, chatId!);
              List<ChatAgent> m = json.content![0].response!.users!;
              actionBy = json.content![0].response!.chat!.messages![0].actionBy
                  .toString();

              //userdata = k;
              setState(() {
                messages!.addAll(k!.messages!);
                this.chatAgents = m.cast<ChatAgent>();
                //attachmentData = "";
                //attachment = null;

                setState(() {});
                _scrollToEnd();
              });
            }
            print("agentPickupChat");
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
        filename: objFile.name, contentType: new MediaType(t1[0], t1[1])));

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
        .catchError((err) => print('error : ' + err.toString()))
        .whenComplete(() {});
  }
}
