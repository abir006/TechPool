import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';

/// Apps default settings
MaterialColor mainColor =  Colors.cyan;
Color secondColor = Color(0xff308ea1);
BorderRadius containerBorderRadius = BorderRadius.all(Radius.circular(8));
final tomTomKey = "UR1weKNyAuCWxJIB64AUrpiB8TDhdc6N";

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

class LocationsResult{
  Address fromAddress;
  Address toAddress;
  Address stop1Address;
  Address stop2Address;
  Address stop3Address;
  LocationsResult(this.fromAddress, this.toAddress,this.stop1Address,this.stop2Address,this.stop3Address);
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
  String startAddress;
  String note;
  int dist;
  List<String> passengers;
  int numberOfSeats;
  int price;
  DateTime time;
  String driver;
  MyLift(this.driver,this.destAddress,this.startAddress,this.numberOfSeats);

  void setPropertiy(String key,var propery){
    switch(key) {

      case "Driver": {  this.driver=propery; }
      break;

      case "DestAddress": {  this.destAddress=propery; }
      break;

      case "StartAddress": {  this.startAddress=propery; }
      break;

      case "Note": {  this.note=propery; }
      break;

      case "TimeStamp": {  this.time= (propery as Timestamp).toDate(); }
      break;

      case "TimeStamp": {  this.time= (propery as Timestamp).toDate(); }
      break;

      case "NumberSeats": {  this.numberOfSeats = propery; }
      break;

      case "Price": {  this.price = propery; }
      break;

      case "Passengers": {  passengers=List.from(propery); }
      break;

      default: { }
      break;
    }}
}

