// ignore_for_file: await_only_futures, duplicate_import, unnecessary_import, avoid_print, non_constant_identifier_names, constant_identifier_names, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:rxdart/subjects.dart';
import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/HomePage.dart';
import 'package:twixor_customer/main.dart';

import 'package:twixor_customer/models/SendMessageModel.dart';
import 'package:twixor_customer/models/SocketResponseModel.dart';
import 'package:twixor_customer/models/chatMessageModel.dart';
import 'package:twixor_customer/models/chatUsersModel.dart';
import 'package:twixor_customer/previewPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'helper_files/Websocket.dart';
import 'helper_files/utilities_files.dart';
import 'helper_files/webView.dart';
import 'API/apidata-service.dart';
import 'dart:ui';
import 'package:mime/mime.dart' show lookupMimeType;
import 'models/Attachmentmodel.dart';
import 'package:path_provider/path_provider.dart';

enum ImageSourceType { gallery, camera }

// ignore: must_be_immutable
class ChatDetailPage extends StatefulWidget {
  String? jsonData = "";
  String attachmentData = "";
  String userChatId = "";
  List<ChatMessage> messages = [];

  ChatDetailPage(this.userChatId, this.attachmentData);

  @override
  _ChatDetailPageState createState() =>
      // ignore: no_logic_in_create_state

      _ChatDetailPageState(userChatId, attachmentData);
}

class _ChatDetailPageState extends State<ChatDetailPage>
    with WidgetsBindingObserver {
  String? imageUrl;
  String? name;
  int? msgindex;
  String? actionBy;
  String? chatId;
  String? eId;
  String? jsonData;
  String attachmentData;
  ChatUsers? userdata;
  Attachment? attachment;
  List<ChatAgent>? chatAgents;
  List<ChatMessage>? messages = [];
  String userChatId;
  List<ChatMessage> nonReadMessages = [];
  StreamController chatSocketStream = StreamController();
  StreamSubscription? chatSubscription;
  BuildContext? dialogContext;
  BuildContext? tempContext;
  var isKeyboardOpen = false;

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

  final shouldEnable = false;
  bool isLoading = false;
  bool isDisable = false;

  _onUrlChanged(String updatedUrl) {}

  _scrollToEnd(int o) async {
    _controller.animateTo(_controller.position.maxScrollExtent + 1000 + o,
        duration: const Duration(microseconds: 60),
        curve: Curves.fastOutSlowIn);
  }

  // ScrollController _controller = ScrollController();

  _ChatDetailPageState(this.userChatId, this.attachmentData);

  getMsg(String userChatId) async {
    print("ChatID2--> $userChatId");
    return jsonData = json.encode(await getChatUserInfo(context, userChatId));
  }

  @override
  initState() {
    super.initState();
    socketMsgReceive();
    getMsg(userChatId).then((result) {
      print(result);
      setState(() {
        print("ChatID--> $userChatId");

        var temp = jsonDecode(result!);
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
    });
    WidgetsBinding.instance?.addObserver(this);
    //

    //socketMsgReceive();
    //super.setState(() {});
    // if (attachments.isAttachment == true) {
    //   if (attachments.type == "MSG") msgController.text = attachments.desc!;
    // }
  }

  @override
  void dispose() {
    print("Chat Socket Closed");

    WidgetsBinding.instance?.removeObserver(this);

    // mainSocket!.close();
    super.dispose();
  }

  @override
  didPopRoute() {
    WidgetsBinding.instance?.removeObserver(this);
    return Future<bool>.value(false);
  }

  @override
  Widget build(BuildContext context) {
    dialogContext = context;
    // print("rcvd fdata ${rcvdData['name']}");

    var listView = ListView.builder(
      controller: _controller,
      itemCount: messages!.length,
      addSemanticIndexes: true,
      padding: const EdgeInsets.only(bottom: 60),
      itemBuilder: (context, index) {
        List<String> messageIds = [];
        messageIds.add(messages![index].actionId.toString());
        // print("messageIds ${messageIds.runtimeType}");
        if (messages![index].status != "2" &&
                messages![index].actionType == "1" ||
            messages![index].actionType == "0") {
          // print("messageIds1");
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
            const SizedBox(
              height: 10,
            ),
            (messages![index].actionType != "1" ||
                    messages![index].actionType != "3")
                ? ChatUtilMessage(messages![index], chatAgents!)
                : Container(),
            (messages![index].actionType == "1" ||
                    messages![index].actionType == "0" ||
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
                          color: (messages![index].actionType == "1" ||
                                  messages![index].actionType == "0"
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
    /////////////////////////////////////////////////
    return WillPopScope(
        //////////////////////////////////////////////
        onWillPop: () async {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('The System Back Button is Deactivated')));
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
              elevation: 10,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
              leading: IconButton(
                onPressed: () {
                  // Navigator.of(context).pop(false);
                  // mainSubscription!.pause();
                  // Navigator.of(context).pop(true);
                  Navigator.pushAndRemoveUntil<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => const MyHomePage(),
                    ),
                    (route) =>
                        true, //if you want to disable back feature set to false
                  );
                  // Navigator.pushAndRemoveUntil<dynamic>(
                  //   context,
                  //   MaterialPageRoute<dynamic>(
                  //     builder: (BuildContext context) => MyHomePage(
                  //       customerId1: customerId,
                  //       eId1: eId!,
                  //       title: MainPageTitle,
                  //     ),
                  //   ),
                  //   (route) =>
                  //       false, //if you want to disable back feature set to false
                  // );

                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => MyHomePage(
                  //               customerId1: customerId,
                  //               eId1: eId!,
                  //               title: MainPageTitle,
                  //             )));
                },
                icon: IconTheme(
                  data: Theme.of(context).copyWith().iconTheme,
                  child: const Icon(
                    Icons.arrow_back,
                  ),
                ),
              ),
              title: Row(children: <Widget>[
                SizedBox(width: 60),
                Container(
                  padding: EdgeInsets.only(right: 90),
                  child: const Text(
                    //'${chatAgents![0].name}',
                    'Chat With Agent',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ])),
          body: Stack(
            children: <Widget>[
              // inspect(messages)

              listView,
              //  alignList("text", false, "")
              // (attachment!.url != null && attachment!.url != "")
              //? alignList(attachment!)
              // alignList(Attachment(type: "MSG")),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
                  height: 60,
                  width: double.infinity,
                  color: Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      modelSheet(context),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: TextField(
                          textInputAction: TextInputAction.go,
                          onSubmitted: (value) {
                            FocusScopeNode currentFocus =
                                FocusScope.of(context);

                            if (!currentFocus.hasPrimaryFocus) {
                              currentFocus.unfocus();
                            }
                            if (value.isNotEmpty) {
                              sendmessage(SendMessage(
                                  action: actionBy != ""
                                      ? "customerReplyChat"
                                      : "customerStartChat",
                                  actionBy:
                                      actionBy != "" ? int.parse(actionBy!) : 0,
                                  actionType: 1,
                                  attachment: Attachment(),
                                  chatId: chatId!,
                                  contentType: "TEXT",
                                  eId: int.parse(eId!),
                                  message: value));

                              setState(() {
                                attachment = Attachment();
                                attachmentData = "";
                                // WidgetsBinding.instance?.removeObserver(this);

                                _scrollToEnd(0);
                                setState(() {});
                              });
                            }
                            msgController.clear();
                          },
                          //onChanged: (newValue) => _onUrlChanged(newValue),
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
                          FocusScopeNode currentFocus = FocusScope.of(context);

                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }
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
                                action: actionBy != ""
                                    ? "customerReplyChat"
                                    : "customerStartChat",
                                actionBy:
                                    actionBy != "" ? int.parse(actionBy!) : 0,
                                actionType: 1,
                                attachment: Attachment(),
                                chatId: chatId!,
                                contentType: "TEXT",
                                eId: int.parse(eId!),
                                message: msgController.text));

                            setState(() {
                              attachment = Attachment();
                              attachmentData = "";
                              //WidgetsBinding.instance?.removeObserver(this);
                              _scrollToEnd(0);
                            });
                          }
                          msgController.clear();
                        },
                        child: IconTheme(
                          data: Theme.of(context).copyWith().iconTheme,
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        backgroundColor: Colors.blue,
                        elevation: 0,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          resizeToAvoidBottomInset: true,
        ));
  }

  FiledALert() {
    //BuildContext
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              height: 50,
              width: 120,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // Icon(
                  //     IconData(0xe8ac,
                  //         fontFamily: 'MaterialIcons'),
                  //     color: Colors.red),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Failed to Upload File",
                    textScaleFactor: 1.0,
                  ),
                ],
              ),
            ),
          );
        });
  }

  // ignore: non_constant_identifier_names
  ChatUtilMessage(ChatMessage message, List chatAgent) {
    // print("ChatUtilMessage ${message.toString()}");
    var utilMsg = "", relativeMsg = "";
    if (message.actionType != "1" && message.actionType != "3") {
      if (message.actionType == "0") {
        relativeMsg = "You started the chat";
      } else if (message.actionType == "2") {
        relativeMsg = " picked up the chat";
      } else if (message.actionType == "4") {
        relativeMsg = " transferred chat To You";
      } else if (message.actionType == "5") {
        relativeMsg = " invited ";
      } else if (message.actionType == "6") {
        relativeMsg = " accepted chat invitation";
      } else if (message.actionType == "8") {
        relativeMsg = " Closed this chat";
      } else if (message.actionType == "9") {
        relativeMsg = " left this chat";
      }
      if (message.actionType == "0") {
        utilMsg = relativeMsg;
      } else {
        utilMsg = chatAgent[0].name.toString() + relativeMsg;
        // if (chatAgent[0].name.toString() == "Medplus") {
        //   utilMsg = chatAgent[0].name.toString() + relativeMsg;
        // } else {
        //   utilMsg = "Medplus" + relativeMsg;
        // }
      }
    }
    return utilMsg != ""
        ? Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: (Colors.blue[200]),
            ),
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 5),
            child: Text(utilMsg),
          )
        : Container();
  }

  Widget modelSheet(context1) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
            isDismissible: true,
            backgroundColor: Colors.transparent,
            context: context1,
            builder: (builder) => bottomSheet(context1));
      },
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.circular(30),
        ),
        child: IconTheme(
          data: Theme.of(context).copyWith().iconTheme,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 20,
          ),
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
    //WidgetsBinding.instance?.removeObserver(this);
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

  Widget iconCreation(context1, IconData icons, Color color, String text,
      String type, int mediaType) {
    return InkWell(
      onTap: () async {
        print("icon creaation");
        if (type == "gallery") {
          //await _getFromGallery();
          //await imageFile;
          //print("img1--> ${img1}");
          Navigator.pop(context1);
          var localFileData = await _getFromGallery();
          if (localFileData != null) {
            showModalBottomSheet(
                backgroundColor: Colors.transparent,
                isDismissible: true,
                context: context1,
                builder: (builder) =>
                    ImageDialog(true, localFileData, context1));
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (_) => FileReaderPage(
            //               localFileData: localFileData,
            //             )));
          }
        } else if (type == "camera") {
          // await _getFromCamera();
          // var img1 = await _getFromCamera();
          Navigator.pop(context1);
          // imageFile?.path == ""
          //  ? const CircularProgressIndicator()
          var localFileData = await _getFromCamera();
          if (localFileData != null) {
            showModalBottomSheet(
                backgroundColor: Colors.transparent,
                context: context,
                builder: (builder) =>
                    ImageDialog(true, localFileData, context1));
          }
        } else if (type == "document") {
          Navigator.pop(context1);
          //objFile = await chooseFileUsingFilePicker();
          print("Upload");
          //if (sendFileType == "jpg") {
          print(objFile.toString());
          //objFile?.path == ""
          // ? const CircularProgressIndicator()
          var localFileData = await chooseFileUsingFilePicker();

          if (localFileData != null) {
            showModalBottomSheet(
              backgroundColor: Colors.transparent,
              context: context1,
              builder: (builder) => ImageDialog(true, localFileData, context1),
            );
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (_) => FileReaderPage(
            //               localFileData: localFileData,
            //             )));
          }
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
    var fileTemp = {};
    FilePickerResult? result;
    File objFile;
    try {
      result = await FilePicker.platform.pickFiles(
        withReadStream: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'pdf',
          'doc',
          'mp4',
          'jpeg',
          'docx',
          'doc',
          'ppt',
          'pptx',
          'png'
        ],
      );
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (result != null) {
      print("ObjFile ${result.files.single.runtimeType}");
      if (result.files.single.extension == "webp") {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: Container(
                  height: 50,
                  width: 120,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        "Failed to Read a File",
                        textScaleFactor: 1.0,
                      ),
                    ],
                  ),
                ),
              );
            });
        return;
      }
      objFile = File((result.files.single.path) ?? "");
      print("objfile type --> ${objFile.runtimeType}");
      print("ObjFile ${result.files.single.runtimeType}");
      //sendFileType = result.files.single.extension;
      print("SendFileType ${sendFileType}");
      fileTemp['contentType'] = ContentReturnType(
          lookupMimeType(result.files.single.path ?? "") ?? "");
      fileTemp['url'] = result.files.single.path;
      fileTemp['name'] = result.files.single.name;

      // fileTemp.type = pickedFile.mimeType;

      return fileTemp;
      // ignore: void_checks
      return objFile.path; //?? uploadSelectedFile(objFile);

    } else
      return;
  }

  _getFromGallery() async {
    var fileTemp = {};
    var pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      print("pickedFile-->${pickedFile.path}");

      fileTemp['contentType'] =
          ContentReturnType(pickedFile.mimeType ?? "image/jpeg") ?? "";
      fileTemp['url'] = pickedFile.path;
      fileTemp['type'] = pickedFile.mimeType;
      fileTemp['name'] = pickedFile.path.split('/').last;
      print("Gallery Mime type ${pickedFile.path.split('.').last}");
      if (pickedFile.path.split('.').last == "webp") {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: Container(
                  height: 50,
                  width: 120,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        "Failed to Read a File",
                        textScaleFactor: 1.0,
                      ),
                    ],
                  ),
                ),
              );
            });
        return;
      } else
        return fileTemp;
      // uploadSelectedFilefromGallery(pickedFile);
      // return File(pickedFile.path);
      // setState(() {
      //   imageFile = File(pickedFile.path);
      // });
    } else
      return;
  }

  _getFromCamera() async {
    var fileTemp = {};
    //  picker.pickImage(source: source)
    var pickedFile = (await picker.pickImage(
      source: ImageSource.camera,
    ));
    var imageFile;
    if (pickedFile != null) {
      print(" pickedFile type--> ${pickedFile.runtimeType}");
      pickedFile.path;
      fileTemp['contentType'] =
          ContentReturnType(pickedFile.mimeType ?? "image/jpeg") ?? "";
      fileTemp['url'] = pickedFile.path;
      fileTemp['type'] = pickedFile.mimeType;
      fileTemp['name'] = pickedFile.path.split('/').last;
      return fileTemp;
      // uploadSelectedFilefromGallery(pickedFile);
      //fileImg=pickedFile as File;
      // imageFile = pickedFile.path;
      //print("pickedFile");
      //print(pickedFile);

      //return imageFile;
    } else
      return;
  }

// ignore: unused_element

  Widget ImageDialog(isFileUrl, localFileData, context1) {
    return AlertDialog(
      content: Column(children: <Widget>[
        localFileData['contentType'] == "IMAGE"
            ? SizedBox(
                width: 200,
                height: 300,
                child: Image.file((File(localFileData['url'])),
                    fit: BoxFit.contain, width: 50, height: 50))
            : localFileData['contentType'] == "VIDEO"
                ? FutureBuilder<dynamic>(
                    future: getThumbnail(localFileData['url']),
                    builder: (context, snapshot) {
                      //try {} catch(Exception){}

                      // print(snapshot);
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.connectionState != ConnectionState.waiting) {
                        print(snapshot.data.toString());
                        if (snapshot.hasData) {
                          return Container(
                            padding: const EdgeInsets.all(1.0),
                            width: 200.0,
                            height: 300.0,
                            child: const Icon(
                              IconData(0xf2b1, fontFamily: 'MaterialIcons'),
                              size: 40,
                              color: Colors.white,
                            ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                image: DecorationImage(
                                    image: MemoryImage(snapshot.data),
                                    fit: BoxFit.cover)),
                          );
                          Container(
                            padding: const EdgeInsets.all(1.0),
                            width: 100.0,
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
                                    image: MemoryImage(Uint8List.fromList(
                                        snapshot.data.cast<int>())),
                                    fit: BoxFit.cover)),
                          );
                        } else if (snapshot.hasError) {
                          ErrorAlert(context, snapshot.hasError.toString());

                          return Container(
                            width: 100.0,
                            height: 100.0,
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
                                        '/drive/docs/6233fae04fb25f668d4bdcda',
                                    fit: BoxFit.cover),
                              ),
                            ),
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    })
                : localFileData['contentType'] == "DOC"
                    ? SizedBox(
                        width: 100,
                        child: Container(
                          height: 100,
                          width: 100,
                          child: Text(
                            localFileData["name"],
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 10,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.amber),
                          ),
                        ),
                      )
                    : Container(),
        Container(
          padding: const EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.bottomLeft,
                child: FloatingActionButton(
                    onPressed: () {},
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      color: Theme.of(context).buttonColor,
                      textColor: Theme.of(context).copyWith().iconTheme.color,
                      child: IconTheme(
                        data: Theme.of(context).copyWith().iconTheme,
                        child: const Icon(
                          IconData(0xe16a, fontFamily: 'MaterialIcons'),
                          size: 8,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      shape: const CircleBorder(),
                    )),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {},
                  child: MaterialButton(
                    onPressed: () async {
                      print("Attachemnt first Clisk");
                      BuildContext? dialogContext1;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          dialogContext1 = context;
                          return WillPopScope(
                              onWillPop: () => Future.value(false),
                              child: Dialog(
                                child: Container(
                                  height: 50,
                                  width: 120,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      SizedBox(
                                        width: 20,
                                      ),
                                      CircularProgressIndicator(),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "Uploading File...",
                                        textScaleFactor: 1.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ));
                        },
                      );
                      Attachment attachment =
                          await uploadSelectedFile(localFileData) ??
                              new Attachment();

                      if (attachment.url != null) {
                        sendmessage(SendMessage(
                          action: actionBy != ""
                              ? "customerReplyChat"
                              : "customerStartChat",
                          actionBy: actionBy != "" ? int.parse(actionBy!) : 0,
                          actionType: 1,
                          attachment: attachment,
                          chatId: chatId!,
                          contentType: attachment.type,
                          eId: int.parse(eId!),
                        ));
                        setState(() {
                          Navigator.pop(dialogContext1!);
                          Navigator.pop(context);
                          attachment = Attachment();
                          //Navigator.of(context).pop(false);
                          attachmentData = "";
                          _scrollToEnd(200);
                          // WidgetsBinding.instance?.removeObserver(this);
                          isLoading = false;
                        });
                      } else {
                        // showDialog(
                        //     context: context,
                        //     builder: (BuildContext context) {
                        //       return Dialog(
                        //         child: Container(
                        //           height: 50,
                        //           width: 120,
                        //           child: Row(
                        //             mainAxisSize: MainAxisSize.min,
                        //             children: const [
                        //               Icon(
                        //                   IconData(0xe8ac,
                        //                       fontFamily: 'MaterialIcons'),
                        //                   color: Colors.red),
                        //               SizedBox(
                        //                 width: 10,
                        //               ),
                        //               Text(
                        //                 "Failed to Read a File",
                        //                 textScaleFactor: 1.0,
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       );

                        //       //ErrorAlert(context, "File Uploading Failed");
                        //     });
                        // Future.delayed(Duration(milliseconds: 500));
                        // Navigator.pop(context1);

                        BuildContext? errorContext;
                        Navigator.pop(dialogContext1!);
                        setState(() {
                          FiledALert();
                        });

                        print("Failed upload");
                        //Navigator.pop(context1);
                        // Navigator.pop(context);
                      }
                    },
                    color: Theme.of(context).buttonColor,
                    textColor: Theme.of(context).copyWith().iconTheme.color,
                    child: const Icon(
                      IconData(0xe571,
                          fontFamily: 'MaterialIcons',
                          matchTextDirection: true),
                      size: 14,
                    ),
                    padding: const EdgeInsets.all(8),
                    shape: const CircleBorder(),
                  ),
                ),
              )
            ],
          ),
        ),
      ]),
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
      child: Align(
        alignment: Alignment.topRight,
        child: Text(urlText!,
            style: const TextStyle(
                decoration: TextDecoration.underline, color: Colors.blue)),
      ),
      onTap: () async {
        if (messages![index].messageContent != "") {
          if (await canLaunch(urlLink!)) launch(urlLink);
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                child: Container(
                  height: 50,
                  width: 120,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Opening a File...",
                        textScaleFactor: 1.0,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          var tempPath = await StoredtoFile(
              messages![index].attachment!.url!.toString(),
              messages![index].attachment!.name.toString().replaceAll(' ', ''));

          String path = tempPath.toString();

          Uri path1 = Uri.parse(path);
          print("path--> $path path2--> $path1");

          OpenFile.open(path1.path);
          Navigator.pop(context);
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
              child: Container(
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
                        APP_URL + '/drive/docs/6233fae04fb25f668d4bdcda',
                        fit: BoxFit.cover),
                  ),
                ),
              )),
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

  Future<Uint8List?> getThumbnail(String videoUrl) async {
    // Image.memory(Uint8List bytes);

    var fileName = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxHeight:
            80, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
        quality: 60,
        maxWidth: 80,
        timeMs: 2000);
    // print(fileName);
    return fileName;
  }

  // _onKeyboardChanged(bool isVisible) {
  //   if (isVisible) {
  //     print("KEYBOARD VISIBLE");
  //   } else {
  //     print("KEYBOARD HIDDEN");
  //   }
  // }

  @override
  Future<void> didChangeMetrics() async {
    //   final value = MediaQuery.of(context).viewInsets.bottom;
    //   if (value > 0) {
    //     if (isKeyboardOpen) {
    //       _onKeyboardChanged(false);
    //     }
    //     isKeyboardOpen = false;
    //   } else {
    //     isKeyboardOpen = true;
    //     _onKeyboardChanged(true);
    //   }
    // }
    attachmentProgress = false;
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

  socketMsgReceive() {
    print("socketMsgReceive isSocketConnection $isSocketConnection");
    var message1;

    // if (!chatPageSocket.hasListener) {
    //   print("chatPageSocket socket is not listener");
    //   chatPageSocket = bSubject;
    // }
    // if (chatPageSocket.isClosed) {
    //   mainSocket.close();
    //   chatPageSocket = bSubject;
    // }
    if (mainSubscription!.isPaused) {
      getSubscribe();
    }

    mainSubscription!.onData((data) {
      message1 = json.decode(data);
      print("ChatPageMessage ${data.toString()}");
      if (message1["action"] == "onOpen") {
        // connected = true;

        print("Connection establised.");
      } else if (message1["action"] == "customerReplyChat") {
        print("Message received Socket");
        var json = SocketResponse.fromJson(message1);
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;

        messages!.addAll(k);
        setState(() {
          WidgetsBinding.instance?.removeObserver(this);
          print(k[0].contentType);
          if (k[0].contentType != "TEXT") {
            _scrollToEnd(0);
          } else {
            _scrollToEnd(0);
          }
          setState(() {
            // _onKeyboardChanged(false);
            WidgetsBinding.instance?.removeObserver(this);
          });
        });
      } else if (message1["action"] == "agentReplyChat") {
        print("Message sent Socket");
        print(message1.toString());
        print(userdata!.name);
        var json = SocketResponse.fromJson(message1);
        if (json.content![0].response!.users![1].name == userdata!.name) {
          List<ChatMessage> k = json.content![0].response!.chat!.messages!;

          messages!.addAll(k);
          //setState(() {});

          setState(() {
            WidgetsBinding.instance?.removeObserver(this);
            if (k[0].contentType != "TEXT")
              _scrollToEnd(0);
            else
              _scrollToEnd(0);
          });
          print("haai");
        }
      } else if (message1["action"] == "customerStartChat") {
        print("Customer Start Chat");
        var json = SocketResponse.fromJson(message1);
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;
        print(message1.toString());
        if (json.content!.elementAt(0).response!.users!.elementAt(0).name ==
            userdata!.name) {
          messages!.addAll(k);
          setState(() {
            WidgetsBinding.instance?.removeObserver(this);
            if (k[0].contentType != "TEXT") {
              _scrollToEnd(0);
            } else {
              _scrollToEnd(0);
            }
          });
        }
      } else if (message1["action"] == "agentPickupChat") {
        var json = SocketResponse.fromJson(message1);
        var chatId = json.content![0].response!.chat!.chatId;
        List<ChatMessage> k = json.content![0].response!.chat!.messages!;
        List<ChatAgent> m = json.content![0].response!.users!;
        actionBy =
            json.content![0].response!.chat!.messages![0].actionBy.toString();
        print(message1.toString());
        // if (json.content!.elementAt(0).response!.users!.elementAt(1).name ==
        //     userdata!.name) {
        messages!.addAll(k);
        chatAgents = m.cast<ChatAgent>();
        setState(() {
          WidgetsBinding.instance?.removeObserver(this);
          if (k[0].contentType != "TEXT") {
            _scrollToEnd(0);
          } else {
            _scrollToEnd(0);
          }
        });

        // }
        print("agentPickupChat");
      } else if (message1["action"] == "agentEndChat") {
        var json = SocketResponse.fromJson(message1);
        var chatId = json.content![0].response!.chat!.chatId;
        List<ChatMessage>? k = json.content![0].response!.chat!.messages!;

        if (chatId == userdata!.chatId) {
          List<ChatAgent> m = json.content![0].response!.users!;
          actionBy =
              json.content![0].response!.chat!.messages![0].actionBy.toString();
          messages!.addAll(k);
          chatAgents = m.cast<ChatAgent>();
          setState(() {
            WidgetsBinding.instance?.removeObserver(this);
            if (k[0].contentType != "TEXT") {
              _scrollToEnd(0);
            } else {
              _scrollToEnd(0);
            }
          });
        }
        print("agentEndCht");
      } else if (message1 == "waitingTransferAccept") {
        print("waitingTransferAccept");
      }
    });
  }

  Widget toast() {
    return Container(child: CircularProgressIndicator());
  }

  uploadSelectedFile(dynamic objFile) async {
    //---Create http package multipart request object
    Attachment tempAttachment = new Attachment();

    print("IsLoading start");
    // setState(() {
    //   isLoading = true;
    //   attachmentProgress = false;
    // });

    var headers = {'authentication-token': authToken!};
    var mimeType = lookupMimeType(objFile['url']);
    var t1 = mimeType.toString().split("/");

    var formData = {
      // 'message': objFile.name.toString(),
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
    try {
      request.files.add(http.MultipartFile.fromBytes(
          'file', await File.fromUri(Uri.parse(objFile['url'])).readAsBytes(),
          filename: objFile['name'], contentType: new MediaType(t1[0], t1[1])));
      print("Reqeust before sent");
      print("${request.url} --> ${request.fields.values} --> ${request.files}");
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      print(respStr.toString());

      print("Reqeust afetr sent");
      print("${request.url} --> ${request.fields.values} --> ${request.files}");

      if (response.statusCode == 200) {
        print("Uploaded! ");
        //print('response.body ' + response.body);
        var temp = json.decode(respStr);
        print(temp["secureUrl"]);
        tempAttachment.url = temp["secureUrl"];
        tempAttachment.name = temp["name"];
        tempAttachment.type = ContentReturnType(temp["contentType"]).toString();
        tempAttachment.contentType = temp["contentType"];
        tempAttachment.isDocument = false;
        tempAttachment.desc = "";
        tempAttachment.id = temp["id"];

        setState(() {
          isLoading = false;
          //attachmentProgress = true;
        });

        print("IsLoading stop");

        return tempAttachment;
      } else {
        // Navigator.pop(context);
        return null;
      }
    } catch (e) {
      return null;
    }

    // ignore: invalid_return_type_for_catch_error
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
