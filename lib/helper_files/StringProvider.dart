import 'package:flutter/material.dart';

class StringProvider extends ChangeNotifier {
  // create a common file for data
  String _str = 'hello';

  String get str => _str;

  void setString(String st) {
    _str = st;
    notifyListeners();
  }
}
