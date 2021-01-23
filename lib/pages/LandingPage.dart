import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/main.dart';
import 'package:tech_pool/widgets/WelcomeSignUpButton.dart';
import 'package:tech_pool/widgets/WelcomeSignInButton.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final welcomePage = Scaffold(body: Container(color: mainColor,height: size.height, width: size.width, child: Stack(alignment: Alignment.center,children: [Image.asset("assets/images/TechPoolWelcomeBackground.png"), TransparentSignInButton(), TransparentSignUnButton()],)));

    return Consumer<UserRepository>(builder: (context, userRep, child)
    {
      return welcomePage;
    });
  }
}

