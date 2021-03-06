import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twixor_customer/models/Attachmentmodel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';

class WebViewEx extends StatefulWidget {
  Attachment? attachment;

  WebViewEx(this.attachment, {Key? key}) : super(key: key);
  @override
  WebViewExampleState createState() => WebViewExampleState(attachment!);
}

class WebViewExampleState extends State<WebViewEx> {
  static var httpClient = HttpClient();
  late String url;
  late String name;
  Attachment attachment;
  WebViewExampleState(this.attachment);
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        toolbarOpacity: 1.0,
        leading: IconButton(
          icon: const Icon(
            IconData(0xe094, fontFamily: 'MaterialIcons'),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
      body: webviewwidget(attachment.url.toString()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _downloadFile(attachment.url.toString(), attachment.name.toString());
          // Note You must create respective pages for navigation
          // Navigator.pushNamed(context, route);

          // Add your onPressed code here!
        },
        child: const Icon(IconData(0xe201, fontFamily: 'MaterialIcons')),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget webviewwidget(url) {
    return WebView(
      initialUrl:
          url, //'https://aim.twixor.com/drive/docs/61c2d1345d9c40085df9a86c',//https://aim.twixor.com/drive/docs/61c2d1345d9c40085df9a86c
      onWebViewCreated: (WebViewController webViewController) {
        _controller.complete(webViewController);
      },
      allowsInlineMediaPlayback: true,
      onPageFinished: (String url) {
        print("Page load Finished");
      },
      onProgress: (int p) {
        print("Page load Finished");
        print(p);
      },
    );
  }

  getPermission(String url, String filename) async {
    if (await Permission.storage.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      final folderName = "twixor_customer";
      var bytes = await consolidateHttpClientResponseBytes(response);
      String dir = (await getApplicationDocumentsDirectory()).path;
      final path = Directory('$dir/$folderName');
      print(path.toString());
      File file = File(path.path + '/$filename');
      //print(file);
      //await file.writeAsBytes(bytes);
      if ((await path.exists())) {
        // TODO:
        print("exist");
        print(file.toString());
        await file.writeAsBytes(bytes);
      } else {
        // TODO:
        print("not exist");
        path.create();
        print("exist");
        print(file.toString());
        await file.writeAsBytes(bytes);
      }
    } else {
// You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      print(statuses[Permission.location]);
    }
  }

  void _downloadFile(String url, String filename) async {
    getPermission(url, filename);

    // print(dir);
    // File file = new File('$dir/$filename');
    // print(file);
    // await file.writeAsBytes(bytes);
    // return file;
  }

  void _showToast(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Added to favorite'),
        action: SnackBarAction(
            label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  Future<String> downloadFile(String url, String fileName, String dir) async {
    HttpClient httpClient = HttpClient();
    File file;
    String filePath = '';
    String myUrl = '';

    try {
      myUrl = url + '/' + fileName;
      var request = await httpClient.getUrl(Uri.parse(myUrl));
      var response = await request.close();
      if (response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        filePath = '$dir/$fileName';
        file = File(filePath);
        await file.writeAsBytes(bytes);
      } else {
        filePath = 'Error code: ' + response.statusCode.toString();
      }
    } catch (ex) {
      filePath = 'Can not fetch url';
    }

    return filePath;
  }
}
