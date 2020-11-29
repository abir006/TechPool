import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/pages/SignInPage.dart';

class TransparentSignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void _pushSignInPage() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return SignInPage();
          },
        ),
      );
    }

    var size = MediaQuery.of(context).size;

    return Container(
        margin:
            EdgeInsets.only(top: size.height * 0.62, left: size.width * 0.06, right:size.width * 0.06),
        height: size.height * 0.06,
        width: size.width * 0.82,
        child: RaisedButton(color: secondColor,child: Text("Sign In",style: TextStyle(fontSize: 24,color: Colors.white),),
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(6.0)),
            onPressed: () => _pushSignInPage()));
  }
}
