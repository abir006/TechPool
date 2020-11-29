import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();
  bool _checkedValue = false;
  TextEditingController _email;
  TextEditingController _password;
  bool _pressed;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: "");
    _password = TextEditingController(text: "");
    _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Consumer<UserRepository>(builder: (context, userRep, child) {return Scaffold(
      key: _key,
        appBar: AppBar(
            title: Text(
          "Sign In",
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
                                  onPressed: () => print("pressed"),
                                  child: Text("Forgot password",
                                      style: TextStyle(
                                        color: Colors.white,
                                      )))
                            ]),
                      ),
                      !_pressed ? Container(
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          width: size.width * 0.7,
                          child: TextButton(
                            child: Text(
                              "Sign In",
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () async {
                              if (_formKey.currentState.validate()) {
                                setState(() {
                                  _pressed = true;
                                });
                                try{
                                  await (userRep.auth.signInWithEmailAndPassword(email: _email.text, password: _password.text).then((user) async {
                                    if(user.user.emailVerified) {
                                      userRep.user = user.user;
                                      Navigator.of(context).pop();
                                    } else {
                                      _key.currentState.showSnackBar(SnackBar(content: Text("Please verify email", style: TextStyle(fontSize: 20),)));
                                      await userRep.auth.signOut().then((value) => userRep.user = null);
                                      setState(() {
                                        _pressed = false;
                                      });
                                    }
                                  }));
                                }catch(e){
                                  setState(() {
                                    _pressed = false;
                                  });
                                  print(e);
                                  print("BAD INFO");
                              }
                              }
                            },
                          ))  : Center(child: CircularProgressIndicator())
                    ]))));});
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
