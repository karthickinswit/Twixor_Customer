import 'package:intl/intl.dart';

ContentReturnType(String s) {
  List k = [
    {
      "IMAGE": ["image/jpeg", "image/jpg", "image/png"]
    },
    {
      "VIDEO": ["video/mp4"]
    },
    {
      "AUDIO": [
        "audio/aac",
        "audio/x-m4a",
        "audio/mp3",
        "audio/amr",
        "audio/ogg"
      ]
    },
    {
      "DOC": [
        "application/pdf",
        "application/doc",
        "application/docx",
        "application/ppt",
        "application/pptx",
        "application/xls",
        "application/xlsx",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/vnd.ms-excel",
        "text/csv"
      ]
    }
  ];
  var temp = "";
  k.asMap().forEach((i, value) {
    print("I $i -> ${value.toString()}");
    for (var v in value.values) {
      print("V - ${v.toString()}");
      if (v.contains(s)) {
        // print("RESULT ${k[i].keys}");
        k[i].forEach((key, value) {
          print('key: $key, value: $value');
          temp = key;
        });
        break;
      }
    }
  });
  return temp;
}

String ConvertTime(String time) {
  // print(time);
  // var temp = DateTime.parse(time);
  // print(temp); //DateFormat('d/M/yyyy').parse(time);

  // return DateFormat('dd,  yy s:s').format(temp).toString();

  List months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  var now;
  try {
    now = DateTime.parse(time);
  } catch (Exception) {
    now = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
  }

  now = now.add(new Duration(hours: 5, minutes: 30));
  var formatter = new DateFormat('dd-MM-yyyy');

  var month = now.month.toString().padLeft(2, '0');

  var day = now.day.toString().padLeft(2, '0');
  String formattedTime = DateFormat('h:mm a').format(now);
  String formattedDate = formatter.format(now);
  print(formattedTime);
  print(formattedDate);
  return '${months[now.month - 1]} $day, ${now.year} ' + ' ' + formattedTime;
}
