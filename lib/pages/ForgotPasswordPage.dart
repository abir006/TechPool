import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';


class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();
  TextEditingController _email;
  bool _pressed;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: "");
    _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return Scaffold(
          key: _key,
          appBar: AppBar(
              title: Text(
            "Password Reset",
            style: TextStyle(color: Colors.white),
          )),
          body: Form(
              key: _formKey,
              child: Container(
                  color: mainColor,
                  height: size.height,
                  width: size.width,
                  child: Wrap(
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    children: [
                      Text(
                        "We will send a link to your mail, \n"
                        "Please click on that link to reset your password",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      textBoxField(
                          size: size,
                          hintText: "Email",
                          textFieldController: _email,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter email';
                              ///validating email ends with technion domain.
                            } else if (!value
                                    .toLowerCase()
                                    .endsWith("technion.ac.il")) {
                              return 'Must use technion email';
                            }

                            return null;
                          }),
                      !_pressed
                          ? Container(
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              width: size.width * 0.7,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      child: Text(
                                        "Send Email",
                                        style: TextStyle(color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                      onPressed: () async {
                                        if (_formKey.currentState.validate()) {
                                          try {
                                            await userRep.auth
                                                .sendPasswordResetEmail(
                                                    email: _email.text);
                                            setState(() {
                                              _pressed = true;
                                            });
                                          } catch (e) {
                                            _key.currentState
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                              e.message,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.red),
                                            )));
                                            setState(() {
                                              _pressed = false;
                                            });
                                          }
                                        }
                                      },
                                    ),
                                    Icon(
                                      Icons.outgoing_mail,
                                      color: Colors.white,
                                    )
                                  ]))
                          : Container(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                  Text("Email was sent",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white))
                                ]))
                    ],
                  ))));
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }
}
