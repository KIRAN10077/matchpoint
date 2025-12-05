import 'package:flutter/material.dart';

showMySnackBar({
  required BuildContext context,
  required String message,
  Color? color         //optional banako

}){
  ScaffoldMessenger.of(context,
              ).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: Duration(seconds: 3),
                  backgroundColor: color ?? Colors.green,
                  behavior: SnackBarBehavior.floating,
  ),
  );
}