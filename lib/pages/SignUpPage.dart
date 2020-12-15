import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';

import 'HomePage.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  FirebaseFirestore db = FirebaseFirestore.instance;
  Animation<double> animation;
  AnimationController controller;
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();
  bool _checkedValue = false;
  TextEditingController _firstName;
  TextEditingController _lastName;
  TextEditingController _email;
  TextEditingController _password;
  TextEditingController _passwordValidate;
  bool _pressed;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: Duration(milliseconds: 150),
        vsync: this //
    );
    animation = new Tween(begin: 0.0, end: 2.0).animate(controller);
    controller.repeat(reverse: true);

    _firstName = TextEditingController(text: "");
    _lastName = TextEditingController(text: "");
    _email = TextEditingController(text: "");
    _password = TextEditingController(text: "");
    _passwordValidate = TextEditingController(text: "");
    _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext ctx, Widget child) {

    return Consumer<UserRepository>(builder: (context, userRep, child) {

      /// this function is being called inside a while to wait until the user
      /// has verified email.
      /// returns true if email verified to stop the loop, false otherwise.
      Future<bool> checkEmailVerified() async{
        return Future.delayed(Duration(seconds: 2)).then((_) async {
        userRep.user = userRep.auth.currentUser;
        if(userRep.user != null) {
          await userRep.user.reload();
          if (userRep.user.emailVerified) {
            return true;
          }
        }
        return false;
        });
      }




      return Scaffold(
        backgroundColor: mainColor,
        key: _key,
        appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white,), onPressed: () async {  await userRep.auth.signOut(); Navigator.of(context).pop();},),
            title: Text(
          "Sign Up",
          style: TextStyle(color: Colors.white),
        )),
        body: Form(
            key: _formKey,
            child: Stack(alignment: Alignment.topCenter,children :[Container(decoration: BoxDecoration(image: DecorationImage(image: Image.asset("assets/images/AuthPageBackground.png",height: size.height,width: size.width,).image)),
      //color: mainColor,
      height: size.height,
      width: size.width),Positioned(top:animation.value,left: size.width*0.38,child: Image(alignment: Alignment.center,height: 100,width: 100,image: Image.asset("assets/images/TechPoolCar.png").image)),Container(
      //decoration: BoxDecoration(image: DecorationImage(image: Image.asset("assets/images/background.png",height: size.height,width: size.width,).image)),
      //color: mainColor,
      height: size.height,
      width: size.width,
      child: Wrap(
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    children: [
                      textBoxField(
                          size: size,
                          hintText: "First name",
                          textFieldController: _firstName,
                          validator: validateNotEmpty("first name")),
                      textBoxField(
                          size: size,
                          hintText: "Last name",
                          textFieldController: _lastName,
                          validator: validateNotEmpty("last name")),
                      textBoxField(
                          size: size,
                          hintText: "Email",
                          textFieldController: _email,
                          validator: (value) {if (value.isEmpty) {return 'Please enter email';} else if(!value.toLowerCase().endsWith("@campus.technion.ac.il") && !value.toLowerCase().endsWith("@technion.ac.il") ) { return 'Must use technion email';} return null;}),
                      textBoxField(
                          size: size,
                          hintText: "Password",
                          textFieldController: _password,
                          obscureText: true,
                          validator: (value) {if (value.isEmpty) {return 'Please enter password';} else if(value.length < 6) {return 'Must enter atleast 6 characters';} return null;}),
                      textBoxField(
                          size: size,
                          hintText: "Validate password",
                          textFieldController: _passwordValidate,
                          obscureText: true,
                          validator: (value) {
                            if (value != _password.text) {
                              return 'Passwords must match';
                            }
                            return null;
                          }),
                      Container(
                        width: size.width * 0.70,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width: size.width * 0.05,
                                  child: Checkbox(
                                      checkColor: Colors.white,
                                      activeColor: secondColor,
                                      value: _checkedValue,
                                      onChanged: (newValue) {
                                        setState(() {
                                          _checkedValue = newValue;
                                        });
                                      })),
                              Text("Remember Me",
                                  style: TextStyle(color: Colors.white)),
                            ]),
                      ),
                      !_pressed ? Container(
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          width: size.width * 0.7,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [TextButton(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () async {
                              if (_formKey.currentState.validate()) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _pressed = true;
                                });
                                try{
                                  await (userRep.auth.createUserWithEmailAndPassword(email: _email.text, password: _password.text).then((user) async {
                                    await db.collection("Profiles").doc(_email.text).set(
                                        {"firstName" : _firstName.text, "lastName" : _lastName.text});
                                  await user.user.updateProfile(displayName: _firstName.text+" "+_lastName.text);
                                  await user.user.sendEmailVerification();
                                  userRep.user = user.user;
                                  userRep.profilePicture = null;
                                  while(!await checkEmailVerified()) {

                                  }
                                  setState(() {
                                    controller.stop();
                                    animation = new Tween(begin: 0.0, end: size.height).animate(controller);
                                    controller.duration = Duration(seconds: 1, milliseconds: 1000);
                                    controller.forward(from: 0.0);
                                  });
                                  await Future.delayed(Duration(seconds: 1, milliseconds: 1000));
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => HomePage()));
                                  }));
                                }catch(e) {
                                  if (_formKey?.currentState != null) {
                                    setState(() {
                                      _pressed = false;
                                    });
                                    _key.currentState.showSnackBar(SnackBar(
                                        content: Text(e.message,
                                          style: TextStyle(fontSize: 20,color: Colors.red),)));
                                  }
                                }
                              }
                            },
                          ),Icon(Icons.account_circle,color: Colors.white)])) : Container(width: size.width*0.7,child: Wrap(direction: Axis.horizontal,children: [Text("A verification email sent to: \n${_email.text}, \nplease verify.", style: TextStyle(backgroundColor: secondColor, color: Colors.white, fontSize: 20),), Center(child: CircularProgressIndicator(),)]))
                    ]))])));});
  });}


  @override
  void dispose() {
    controller.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _passwordValidate.dispose();
    super.dispose();
  }
}
