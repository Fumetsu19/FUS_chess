import 'package:flutter/material.dart';

void popToRoot(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

void pushFromRoot(BuildContext context, Widget page) {
  popToRoot(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}
