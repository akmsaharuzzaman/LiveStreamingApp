import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final Function(String?)? onSaved;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final String? labelText;
  final Widget? suffixIcon;
  final bool? obsecureText;
  final int? maxLines;
  final int? maxLength;
  const CustomTextField(
      {super.key,
      required this.controller,
      this.contentPadding,
      this.hintText,
      this.keyboardType,
      this.onChanged,
      this.onSaved,
      this.prefixIcon,
      this.style,
      this.textInputAction,
      this.inputFormatters,
      this.readOnly = false,
      this.textAlign = TextAlign.start,
      this.textCapitalization = TextCapitalization.none,
      this.validator,
      this.labelText,
      this.suffixIcon,
      this.obsecureText = false,
      this.maxLines = 1,
      this.maxLength});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        textCapitalization: textCapitalization,
        style: style,
        controller: controller,
        obscureText: obsecureText!,
        onSaved: onSaved,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        cursorColor: Theme.of(context).primaryColor,
        readOnly: readOnly,
        textAlign: textAlign,
        validator: validator,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        maxLength: maxLength,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          fillColor: Colors.grey.shade200,
          filled: true,
          hintText: hintText,
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.sp),
            borderSide: BorderSide(width: 1.w, color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.sp),
            borderSide: BorderSide(width: 1.w, color: Colors.grey.shade200),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.sp),
            borderSide: BorderSide(width: 1.w, color: Colors.red),
          ),
        ));
  }
}
