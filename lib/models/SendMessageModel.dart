import 'Attachmentmodel.dart';

class SendMessage {
  String? action;
  int? actionBy;
  int? actionType;
  Attachment? attachment;
  String? chatId;
  String? contentType;
  int? eId;
  String? message;
  List<String>? actiondIds;

  SendMessage(
      {this.action,
      this.actionBy,
      this.actionType,
      this.attachment,
      this.chatId,
      this.contentType,
      this.eId,
      this.message,
      this.actiondIds});

  SendMessage.fromJson(Map<String, dynamic> json) {
    action = json['action'] ?? "";
    actionBy = json['actionBy'] ?? "";
    actionType = json['actionType'] ?? "";
    attachment = json['attachment'] != null
        ? Attachment.fromJson(json['attachment'])
        : null;
    chatId = json['chatId'] ?? "";
    contentType = json['contentType'] ?? "";
    eId = json['eId'] ?? "";
    message = json['message'] ?? "";
    actiondIds = json['actionIds'] ?? [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['action'] = action;
    data['actionBy'] = actionBy;
    data['actionType'] = actionType;
    if (attachment != null) {
      data['attachment'] = attachment!.toJson();
    }
    data['chatId'] = chatId;
    data['contentType'] = contentType;
    data['eId'] = eId;
    data['message'] = message;
    data["actiondIds"] = actiondIds;
    return data;
  }
}
