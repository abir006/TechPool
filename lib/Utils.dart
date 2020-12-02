import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Apps default settings
MaterialColor mainColor =  Colors.cyan;
Color secondColor = Color(0xff308ea1);
BorderRadius containerBorderRadius = BorderRadius.all(Radius.circular(8));

double fontTextsSize = 17;
double lablesTextsSize = 19;
///user repository for the app, should be supplied at the very top of the widget tree
///will manage the User state, info and Authentication.
///[auth] is the entry point for firebase Authentication.
///[user] is the current user using the app.
class UserRepository extends ChangeNotifier {
  final auth = FirebaseAuth.instance;
  User _user;

  set user(User value) {
    _user = value;
    notifyListeners();
  }

  User get user => _user;
}

/// A container class for Drive event.
class Drive{
  String info;
  Drive(this.info);

}

/// A container class for Lift event.
class Lift{
  String info;
  Lift(this.info);
}

/// A container class for DesiredLift event.
class DesiredLift{
  String info;
  DesiredLift(this.info);
}

/// A container class for DesiredDrive event.
class DesiredDrive{
  String info;
  DesiredDrive(this.info);
}

/// A util function for the calendar, returns the desired event container to
/// display under the calendar, according to the type of event received.
Container transformEvent(dynamic event){
  if (event is Drive) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin:
      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(leading: Icon(Icons.directions_car,size: 30, color: mainColor,),
        title: Text(event?.info),
        onTap: () => print('$event tapped!'),
      ),
    );
  } else if (event is Lift) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin:
      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(leading: Transform.rotate(angle: 0.8,child: Icon(Icons.thumb_up_rounded,size: 30, color: mainColor,)),
        title: Text(event?.info),
        onTap: () => print('$event tapped!'),
      ),
    );
  } else if (event is DesiredLift) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin:
      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(leading: Transform.rotate(angle: 0.8,child: Icon(Icons.thumb_up_rounded,size: 30, color: mainColor,)),
        title: Text(event?.info),
        onTap: () => print('$event tapped!'),
      ),
    );
  }
  else{
    return null;
  }
}

class MyLift{
  String destAddress;
  String stopAddress;
  String note;
  int numberOfSeats;
  DateTime time;
  String driver;
  MyLift(this.driver,this.destAddress,this.stopAddress,this.numberOfSeats);
}

