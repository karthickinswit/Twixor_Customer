import 'package:flutter/material.dart';

class CustomError extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomError({
    Key? key,
    required this.errorDetails,
  })  : assert(errorDetails != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        child: Text(
          "Something is not right here...",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        padding: EdgeInsets.all(8.0),
      ),
      color: Colors.red,
      margin: EdgeInsets.zero,
    );
  }
}
