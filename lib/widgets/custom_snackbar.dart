import 'package:flutter/material.dart';

/// Shows a custom snackbar with the given message
void showCustomSnackBar({
  required BuildContext context,
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final snackBar = SnackBar(
    content: Text(
      message,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    ),
    backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    action: SnackBarAction(
      label: 'Dismiss',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}