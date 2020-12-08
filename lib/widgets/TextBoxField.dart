import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../Utils.dart';

Widget textBoxField({AutovalidateMode validateMode = AutovalidateMode.disabled,@required Size size,@required String hintText,@required TextEditingController textFieldController,bool obscureText = false,Function validator,InputBorder inputBorder=InputBorder.none}) {
  return Container(decoration: BoxDecoration(
      color: Colors.white, borderRadius: containerBorderRadius),
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      width: size.width * 0.7,
      child: TextFormField(autovalidateMode: validateMode,validator: validator,obscureText: obscureText,controller: textFieldController,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
              border: inputBorder, hintText: hintText)));
}

Function validateNotEmpty(String missingString){
  return ((value) {if (value.isEmpty) {return 'Please enter $missingString';}return null;});
}



Widget textBoxFieldDisable({@required Size size,@required String hintText,@required TextEditingController textFieldController,bool obscureText = false,Function validator,String nameLabel}) {
  return Container(decoration: BoxDecoration(
      color: Colors.transparent, borderRadius: containerBorderRadius),
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      width: size.width * 0.7,
      child: TextFormField(autovalidateMode: AutovalidateMode.onUserInteraction,validator: validator,obscureText: obscureText,controller: textFieldController,
          textAlign: TextAlign.left,
          style: TextStyle(
              fontSize: 17, color: Colors.black.withOpacity(0.6)),
          readOnly: true,
          decoration: InputDecoration(
                labelText: nameLabel,
                labelStyle: TextStyle(fontSize: 17),
              border: InputBorder.none, hintText: hintText)));
}

Widget textBoxFieldDisableCentered({@required Size size,@required String hintText,@required TextEditingController textFieldController,bool obscureText = false,Function validator,String nameLabel}) {
  return Container(decoration: BoxDecoration(
      color: Colors.transparent
      //, borderRadius: containerBorderRadius)
      ),
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
      width: size.width * 0.7,
      height: size.height * 0.05,
      child: TextFormField(autovalidateMode: AutovalidateMode.onUserInteraction,validator: validator,obscureText: obscureText,controller: textFieldController,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 17, color: Colors.black.withOpacity(0.6)),
          readOnly: true,
          decoration: InputDecoration(
              labelText: nameLabel,
              labelStyle: TextStyle(fontSize: 17),
              border: InputBorder.none, hintText: hintText)));
}


Widget labelText({@required String text}){
 return Container(
    child: Text(
      text,
      style:
      TextStyle( fontSize: 17, color: Colors.black.withOpacity(0.6)),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}
Widget infoText({@required String text}){
  return Container(
    child: Text(
      text,
      style:
      TextStyle( fontSize: 17,),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}

