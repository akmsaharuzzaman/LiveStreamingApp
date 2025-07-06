import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AssetWidgetType { dymond, gold }

class AssetWidget extends StatefulWidget {
  final AssetWidgetType type;
  final double value;

  const AssetWidget({super.key, required this.type, required this.value});

  @override
  State<AssetWidget> createState() => _AssetWidgetState();
}

class _AssetWidgetState extends State<AssetWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          widget.type == AssetWidgetType.dymond
              ? 'assets/icon/dymond_icon.png'
              : 'assets/icon/gold_icon.png',
          height: 25.0,
        ),

        SizedBox(width: 8.0),
        Text(widget.value.toStringAsFixed(0), style: TextStyle(fontSize: 25.0)),
      ],
    );
  }
}
