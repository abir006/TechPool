import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../Utils.dart';

Widget textBoxField({@required Size size,@required String hintText,@required TextEditingController textFieldController,bool obscureText = false,Function validator}) {
  return Container(decoration: BoxDecoration(
      color: Colors.white, borderRadius: containerBorderRadius),
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      width: size.width * 0.7,
      child: TextFormField(autovalidateMode: AutovalidateMode.onUserInteraction,validator: validator,obscureText: obscureText,controller: textFieldController,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
              border: InputBorder.none, hintText: hintText)));
}

Function validateNotEmpty(String missingString){
  return ((value) {if (value.isEmpty) {return 'Please enter $missingString';}return null;});
}

