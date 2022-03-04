import 'Attachmentmodel.dart';

class ChatMessage {
  String? messageContent;
  String? messageType;
  bool? isUrl;
  String? contentType;
  String? url;
  String? actionBy;

  String? actionType;
  String? eId;
  String? actedOn;
  Attachment? attachment;
  String? actionId;
  String? status;
  ChatMessage(
      {required this.messageContent,
      required this.messageType,
      required this.isUrl,
      required this.contentType,
      required this.url,
      required this.actionBy,
      required this.attachment,
      required this.actionType,
      required this.eId,
      this.actedOn,
      this.actionId,
      this.status});

  ChatMessage.fromAPItoJson(Map<String, dynamic> json) {
    messageContent = json["message"] != null ? json["message"] as String : "";
    messageType = json["status"] != null
        ? json["status"] == 0
            ? "sender"
            : "receiver"
        : "";
    isUrl = json['isUrl'] == null ? false : true;
    contentType =
        json['contentType'] != null ? json["contentType"] as String : "";
    attachment = (json['attachment'] != null && json['attachment'].length != 0
        ? Attachment.fromJson(json['attachment'])
        : null);
    url = json['url'] ?? "";
    eId = json["eId"] != null ? json['eId'].toString() : "";
    actionType =
        json["actionType"] != null ? json['actionType'].toString() : "";
    actedOn = json["actedOn"] != null ? json['actedOn'].toString() : "";
    actionId = json["actionId"] != null ? json['actionId'].toString() : "";
    status = json["status"] != null ? json['status'].toString() : "";
  }
  ChatMessage.fromLocaltoJson(Map<String, dynamic> json) {
    ///eId = json['eId'] as String;
    messageContent = json["messageContent"] ?? json["message"] ?? "";
    messageType = json["messageType"];
    isUrl = json["isUrl"];
    contentType = json["contentType"];
    attachment = (json['attachment'] != null && json['attachment'].length != 0
        ? Attachment.fromJson(json['attachment'])
        : null);
    url = json["url"];
    actionBy = json["actionBy"].toString();
    eId = json["eId"].toString();
    actionType = json["actionType"].toString();
    actedOn = json["actedOn"].toString();
    actionId = json["actionId"] != null ? json['actionId'].toString() : "";
    status = json["status"] != null ? json['status'].toString() : "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['messageContent'] = messageContent;
    data['messageType'] = messageType;
    data['isUrl'] = isUrl;
    data['contentType'] = contentType;
    data['url'] = url;
    if (attachment != null && attachment!.url != "") {
      data['attachment'] = attachment!.toJson();
    }
    data['eId'] = eId;
    data['actionBy'] = actionBy;
    data["actionType"] = actionType;
    data["actedOn"] = actedOn;
    data["actionId"] = actionId;
    data["status"] = status.toString();
    return data;
  }
}
