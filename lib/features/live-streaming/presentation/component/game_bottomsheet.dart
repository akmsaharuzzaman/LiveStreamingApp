import 'package:flutter/material.dart';

void showMoreOptions(BuildContext context) {
  print("More options pressed");
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(padding: EdgeInsets.all(16));
    },
  );
}
