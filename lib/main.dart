import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/pages/HomePage.dart';
import 'package:tech_pool/pages/LandingPage.dart';
import 'Utils.dart';
import 'package:intl/date_symbol_data_local.dart';

final versionNumber = 1.0;

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          WidgetsFlutterBinding.ensureInitialized();
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
              .then((_) {
            runApp(new MyApp());
          });
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

void main() {
  initializeDateFormatting().then((_) {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(App());
  });
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final cloudStorage = FirebaseStorage.instance;
  final EncryptedSharedPreferences encryptedSharedPreferences =
      EncryptedSharedPreferences();
  var email = "";
  var pass = "";
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  StreamSubscription<DataConnectionStatus> listener;
  var InternetStatus = "Unknown";
  var contentmessage = "Unknown";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {
      return ChangeNotifierProvider<UserRepository>(
          create: (context) => UserRepository(),
          child: MaterialApp(
              title: 'TechPool',
              theme: ThemeData(
                primaryColor: mainColor,
                primaryIconTheme: IconThemeData(color: Colors.white),
                unselectedWidgetColor: Colors.white,
              ),
              home: FutureBuilder<DocumentSnapshot>(
                ///getting the version number.
                  future: firestore
                      .collection("Version")
                      .doc("VersionControl")
                      .get(),
                  builder: (context, snapshot) {
                    final size = MediaQuery.of(context).size;
                    if (snapshot.hasData) {
                      ///checking if version number is correct.
                      if (snapshot.data["version"] == versionNumber) {
                        return Builder(
                          builder: (context) {
                            var userRep = Provider.of<UserRepository>(context,
                                listen: false);
                            return FutureBuilder<Object>(
                              ///checking if user saved credentials to sign in.
                              future: (encryptedSharedPreferences
                                  .getString("email")
                                  .then((value) {
                                    email = value;
                                  })
                                  .then((_) => encryptedSharedPreferences
                                      .getString("password"))
                                  .then((val) {
                                    pass = val;
                                  })
                                  .then((_) => Future.sync(() {
                                        if (email.isNotEmpty &&
                                            pass.isNotEmpty) {
                                          return userRep.auth
                                              .signInWithEmailAndPassword(
                                                  email: email, password: pass);
                                        } else {
                                          /// if failed to sign in, throw to go to homepage.
                                          throw Exception("bad info");
                                        }
                                      }))
                                  .then((user) => userRep.user = user.user)
                                  .then((_) => cloudStorage
                                      .ref('uploads')
                                      .child(userRep.user?.email)
                                      .getDownloadURL())
                                  .then((imgUrl) => userRep.profilePicture =
                                      Image.network(imgUrl))
                                  .then((_) => true)
                                  .catchError((e) {
                                    return false;
                                  })),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  if (!snapshot.data) {
                                    /// if failed to auto sign in got to landing page.
                                    return LandingPage();
                                  } else {
                                    /// if succeed to auto sign in go to home page.
                                    return HomePage();
                                  }
                                } else if (snapshot.hasError) {
                                  return Center(child: Text(snapshot.error));
                                  /// while trying verifying credentials and version number
                                  /// show the background image and circular progress.
                                } else {
                                  return Scaffold(
                                      body: Container(
                                          color: mainColor,
                                          height: size.height,
                                          width: size.width,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                  "assets/images/try.png"),
                                              Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            ],
                                          )));
                                }
                              },
                            );
                          },
                        );
                      } else {
                        /// if version number is bad, dont allow further progress,
                        /// and tell the user to update the app.
                        return Scaffold(
                            body: Container(
                                color: mainColor,
                                height: size.height,
                                width: size.width,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset("assets/images/try.png"),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom: size.height * 0.2),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Container(
                                              decoration:
                                                  pageContainerDecoration,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                    "Youre app is not updated. \nPlease update your app from the play store.",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black)),
                                              ))
                                        ],
                                      ),
                                    )
                                  ],
                                )));
                      }
                    } else if (snapshot.hasError) {
                      /// if version number is bad, dont allow further progress,
                      /// and tell the user to update the app.
                      return Scaffold(
                          body: Container(
                              color: mainColor,
                              height: size.height,
                              width: size.width,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset("assets/images/try.png"),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        bottom: size.height * 0.2),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Container(
                                            decoration: pageContainerDecoration,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  "Youre app is not update. \nPlease update your app from the play store.",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black)),
                                            ))
                                      ],
                                    ),
                                  )
                                ],
                              )));
                    } else {
                      /// while loading.
                      return Scaffold(
                          body: Container(
                              color: mainColor,
                              height: size.height,
                              width: size.width,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset("assets/images/try.png"),
                                  Center(
                                    child: CircularProgressIndicator(),
                                  )
                                ],
                              )));
                    }
                  })));
    });
  }
}
