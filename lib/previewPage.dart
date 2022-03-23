import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:twixor_customer/API/apidata-service.dart';
import 'package:twixor_customer/helper_files/Websocket.dart';
import 'package:twixor_customer/helper_files/utilities_files.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
import 'package:twixor_customer/models/SendMessageModel.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:twixor_customer/helper_files/utilities_files.dart';

class FileReaderPage extends StatefulWidget {
  final localFileData;

  FileReaderPage({Key? key, Key = Key, required this.localFileData})
      : super(key: key);

  @override
  _FileReaderPageState createState() => _FileReaderPageState();
}

class _FileReaderPageState extends State<FileReaderPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          widget.localFileData['contentType'] == "IMAGE"
              ? SizedBox(
                  width: 200,
                  height: 300,
                  child: Image.file((File(widget.localFileData['url'])),
                      fit: BoxFit.contain, width: 50, height: 50))
              : widget.localFileData['contentType'] == "VIDEO"
                  ? Container()
                  : Container(),
          widget.localFileData['contentType'] == "DOC"
              ? SizedBox(
                  width: 100,
                  child: Text(
                    widget.localFileData["name"],
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, color: Colors.amber),
                  ),
                )
              : Container(
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
                              textColor:
                                  Theme.of(context).copyWith().iconTheme.color,
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
                              if (attachmentProgress) {
                                print("Attachemnt second Clisk");
                                Attachment attachment =
                                    await uploadSelectedFile(
                                        widget.localFileData);

                                if (attachment != null) {
                                  sendmessage(SendMessage(
                                      action: "customerReplyChat",
                                      actionBy: 3,
                                      actionType: 1,
                                      attachment: attachment,
                                      chatId: userChatId,
                                      contentType: attachment.type,
                                      eId: int.parse(
                                        userEid,
                                      )));
                                  setState(() {
                                    attachment = Attachment();
                                    Navigator.of(context).pop(false);

                                    // _scrollToEnd(200);
                                    // WidgetsBinding.instance?.removeObserver(this);
                                  });
                                }
                              } else {
                                ErrorAlert(context, "File is uploading");
                              }
                            },
                            color: Theme.of(context).buttonColor,
                            textColor:
                                Theme.of(context).copyWith().iconTheme.color,
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
                )
        ],
      ),
    );
  }

  uploadSelectedFile(dynamic objFile) async {
    //---Create http package multipart request object
    Attachment tempAttachment = new Attachment();
    ErrorAlert(context, "File is uploading");

    print("IsLoading start");
    setState(() {
      attachmentProgress = false;
    });

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
    request.files.add(http.MultipartFile.fromBytes(
        'file', await File.fromUri(Uri.parse(objFile['url'])).readAsBytes(),
        filename: objFile['name'], contentType: new MediaType(t1[0], t1[1])));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    print(respStr.toString());

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
        attachmentProgress = true;
      });
      print("IsLoading stop");
      return tempAttachment;
    }

    // ignore: invalid_return_type_for_catch_error
  }
}
