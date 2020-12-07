import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';

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
  List<Address> stopAddresses;
  LocationsResult(this.fromAddress, this.toAddress,this.stopAddresses);
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

double clacDis(GeoPoint from,Coordinates to){
  return (Geolocator.distanceBetween(from.latitude,from.longitude,to.latitude,to.longitude).abs());
}

class MyLift{
  String destCity;
  String startCity;
  String destAddress;
  String startAddress;
  String note;
  int dist;
  List<String> passengers;
  int numberOfSeats;
  int price;
  DateTime time;
  String driver;
  MyLift(this.driver,this.destCity,this.startCity,this.numberOfSeats);
  GeoPoint  destPoint;
  GeoPoint startPoint;
  bool bigTrunk;
  bool backSeat;
  var stops = new Map();

  void setProperty(String key,var property){
    switch(key) {

      case "Driver": {  this.driver=property; }
      break;

      case "DestCity": {  this.destCity=property; }
      break;

      case "StartCity": {  this.startCity=property; }
      break;

      case "DestAddress": {  this.destAddress=property; }
      break;

      case "StartAddress": {
        this.startAddress=property;
      }
      break;

      case "Note": {
        this.note=property;
      }
      break;

      case "TimeStamp": {  this.time= (property as Timestamp).toDate().add(Duration(days: 0,hours: 2,minutes: 0,microseconds: 0)); }
      break;

      case "NumberSeats": {  this.numberOfSeats = property; }
      break;

      case "Price": {  this.price = property; }
      break;

      case "Passengers": {  passengers=List.from(property); }
      break;

      case "DestPoint": { destPoint = property;}
      break;

      case "StartPoint": { startPoint = property;}
      break;

      case "Stops": {stops = property;}
      break;

      case "BigTrunk": { bigTrunk = property;}
      break;

      case "BackSeatNotFull":{ backSeat = property;}
      break;


      default: { }
      break;
    }}
}

class liftRes{
  DateTime fromTime;
  DateTime toTime;
  int indexDist;
  Address startAddress;
  Address destAddress;
  bool backSeat;
  bool bigTrunk;

  liftRes({@required this.fromTime,@required this.toTime,@required this.indexDist,@required this.startAddress,@required this.destAddress, @required this.backSeat, @required this.bigTrunk});
}

