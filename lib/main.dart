import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
        return ChangeNotifierProvider(create: (context) => UserRepository(), child:MaterialApp(
          title: 'TechPool',
          theme: ThemeData(
            primaryColor: mainColor,
            primaryIconTheme: IconThemeData(color: Colors.white),
            unselectedWidgetColor: Colors.white,
          ),
          home: LandingPage(),
    )
        );
  }
}
