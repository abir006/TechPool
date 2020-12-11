import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';

import 'ForgotPasswordPage.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();
  bool _checkedValue = false;
  TextEditingController _email;
  TextEditingController _password;
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


    _email = TextEditingController(text: "");
    _password = TextEditingController(text: "");
    _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext ctx, Widget child) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return Scaffold(
        backgroundColor: mainColor,
      key: _key,
        appBar: AppBar(
            title: Text(
          "Sign In",
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
                          hintText: "Email",
                          textFieldController: _email,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter email';
                            } else if (!value
                                    .toLowerCase()
                                    .endsWith("@campus.technion.ac.il") &&
                                !value
                                    .toLowerCase()
                                    .endsWith("@technion.ac.il")) {
                              return 'Must use technion email';
                            }
                            return null;
                          }),
                      textBoxField(
                          size: size,
                          hintText: "Password",
                          textFieldController: _password,
                          obscureText: true,
                          validator: (value) {if (value.isEmpty) {return 'Please enter password';} else if(value.length < 6) {return 'Must enter atleast 6 characters';} return null;}),
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
                              Spacer(),
                              TextButton(
                                  onPressed: () {
                                    //showDialog(context: context, child:resetDialog);
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (BuildContext context) {
                                          return ForgotPasswordPage();
                                        },
                                      ),
                                    );},
                                  child: Text("Forgot password",
                                      style: TextStyle(
                                        color: Colors.white,
                                      )))
                            ]),
                      ),
                      !_pressed ? TextButton(
                          child: Container(decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                              BorderRadius.all(Radius.circular(8))),
                        width: size.width * 0.7,
                            height: size.height*0.06,

                            child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [Text(
                              "Sign In",
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),Icon(Icons.login,color: Colors.white,)])),
                            onPressed: () async {
                              if (_formKey.currentState.validate()) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _pressed = true;
                                });
                                try{
                                  await (userRep.auth.signInWithEmailAndPassword(email: _email.text, password: _password.text).then((user) async {
                                    if(user.user.emailVerified) {
                                      userRep.user = user.user;
                                      setState(() {
                                        controller.stop();
                                        animation = new Tween(begin: 0.0, end: size.height).animate(controller);
                                        controller.duration = Duration(seconds: 1, milliseconds: 1000);
                                        controller.forward(from: 0.0);
                                      });
                                      await Future.delayed(Duration(seconds: 1, milliseconds: 1000));
                                      Navigator.of(context).pop();
                                    } else {
                                      _key.currentState.showSnackBar(SnackBar(content: Text("Please verify email", style: TextStyle(fontSize: 20, color: Colors.red),)));
                                      await userRep.auth.signOut().then((value) => userRep.user = null);
                                      setState(() {
                                        _pressed = false;
                                      });
                                    }
                                  }));
                                }catch(e){
                                  _key.currentState.showSnackBar(SnackBar(content: Text(e.message, style: TextStyle(fontSize: 20,color: Colors.red),)));
                                  setState(() {
                                    _pressed = false;
                                  });
                                }
                              }
                            },
                          ) : Center(child: CircularProgressIndicator())
                    ]))])));});
          });}

  @override
  void dispose() {
    controller.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
