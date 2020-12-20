import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/pages/HomePage.dart';
import 'package:tech_pool/pages/LandingPage.dart';
import 'Utils.dart';
import 'package:intl/date_symbol_data_local.dart';



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
          return MyApp();
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
  final auth = FirebaseAuth.instance;
  final cloudStorage = FirebaseStorage.instance;
  final EncryptedSharedPreferences encryptedSharedPreferences = EncryptedSharedPreferences();
  var email = "";
  var pass = "";

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {return  ChangeNotifierProvider<UserRepository>(
                  create: (context) => UserRepository(), child: MaterialApp(
                title: 'TechPool',
                theme: ThemeData(
                  primaryColor: mainColor,
                  primaryIconTheme: IconThemeData(color: Colors.white),
                  unselectedWidgetColor: Colors.white,
                ),
                home: Builder(builder: (context) {
                  var userRep = Provider.of<UserRepository>(context,listen: false);
                  return FutureBuilder<Object>(
    future: (encryptedSharedPreferences.getString("email").then((value) {
      email=value;print(value);}).then((_) => encryptedSharedPreferences.getString("password")).then((val) {pass=val;print(val);})
        .then((_) => auth.signInWithEmailAndPassword(email: email, password: pass)).then((user) => userRep.user = user.user).then((_) => cloudStorage
        .ref('uploads')
        .child(userRep.user?.email)
        .getDownloadURL()).then((imgUrl) =>  userRep.profilePicture = Image.network(imgUrl)).then((_) => true).catchError((e) {
          return false;
    }
    )),
        builder: (context, snapshot) {
          final size = MediaQuery.of(context).size;
          if (snapshot.hasData) {
            if(!snapshot.data) {
              return LandingPage();
            } else {
              return HomePage();
            }
            } else if(snapshot.hasError) {
              return Center(child: Text(snapshot.error));
          }else{
              return Scaffold(body: Container(color: mainColor,height: size.height, width: size.width, child: Stack(alignment: Alignment.center,children: [Image.asset("assets/images/try.png"), Center(child: CircularProgressIndicator(),)],)));
            }
          }
        ,
                  );},
                )));});
  }
}
