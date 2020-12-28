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
  final defaultPic = Image.asset("assets/images/profile.png");
  Image _profilePicture;
  User _user;

  set user(User value) {
    _user = value;
    notifyListeners();
  }

  set profilePicture(Image pic){
    _profilePicture = pic;
    notifyListeners();
  }

  void changeDisplayName(String name) async{
    await _user.updateProfile(displayName: name);
    _user = auth.currentUser;
    notifyListeners();
  }

  User get user => _user;

  Image get profilePicture => _profilePicture ?? defaultPic;
}

class LocationsResult{
  Address fromAddress;
  Address toAddress;
  List<Address> stopAddresses;
  int numberOfStops;
  LocationsResult(this.fromAddress, this.toAddress,this.stopAddresses,this.numberOfStops);
}

double clacDis(GeoPoint from,Coordinates to){
  return (Geolocator.distanceBetween(from.latitude,from.longitude,to.latitude,to.longitude).abs());
}
enum NotificationInfoType {Accepted, Requested}

// a class for a notification about a lift, that contains relevant data that
// is needed in order to maintain and show a notification tile and info page
class LiftNotification {
  String notificationId;
  String driveId;
  String driverId;//email
  String startCity;
  String destCity;
  int distance;
  int price;
  DateTime liftTime;
  DateTime notificationTime;
  String type;
  String startAddress;
  String destAddress;
  // int numberOfSeats;
  // int numberOfPassengers;
  String passengerId;
  String passengerNote;
  bool bigBag;

  LiftNotification(this.notificationId, this.driveId, this.driverId, this.startCity, this.destCity,
  this.price, this.distance, this.liftTime, this.notificationTime,
  this.type, this.startAddress, this.destAddress, [this.passengerId, this.passengerNote, this.bigBag]);//optional
  LiftNotification.requested(this.notificationId, this.driveId, this.driverId, this.startCity, this.destCity,
      this.price, this.distance, this.liftTime, this.notificationTime,
      this.type, this.startAddress, this.destAddress, this.passengerId, this.passengerNote, this.bigBag);
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
  String imageUrl;
  String driverName;
  String liftId;
  Map<String,Map<String, dynamic>> passengersInfo;
  String payments;
  String pendingStartAddress;
  String pendingDestAddress;
  String pendingNote;
  var stops = new List<dynamic>();

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

      case "TimeStamp": {  this.time= (property as Timestamp).toDate().add(Duration(days: 0,hours: 0,minutes: 0,microseconds: 0)); }
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

var userInfoKey = ["email","firstName","lastName","hobbies","faculty","aboutSelf","allowedPayments","phoneNumber",];
enum userInfoKeyEnum{
  email,
  firstName,
  lastName,
  hobbies,
  faculty,
  aboutSelf,
  allowedPayments,
  phoneNumber,

}

class UserInfo{
  Map<String,dynamic> keyToValueMap = { };
  UserInfo();
  void setProperty(String key,var property){
    keyToValueMap[key] = property;
  }

  void setPropertyEnum(userInfoKeyEnum key,var property){
    keyToValueMap[userInfoKey[key.index]] = property;
  }
  dynamic getPropertyEnum(userInfoKeyEnum key){
    return keyToValueMap[userInfoKey[key.index]];
  }
}


/// the decoration for the container inside the page body for main pages.
final pageContainerDecoration = BoxDecoration(color: Colors.white,borderRadius: BorderRadius.all(Radius.circular(20.0)),
  boxShadow: [BoxShadow(color: Colors.black,blurRadius: 4.0,
      spreadRadius: 0.0,offset: Offset(0.0, 1.0))],);
/// the margin for the container inside the page body for main pages.
final pageContainerMargin = EdgeInsets.fromLTRB(10, 4, 10, 10);

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class BadgeIcon extends StatelessWidget {
  BadgeIcon(
      {this.icon,
        this.badgeCount = 0,
        this.showIfZero = false,
        this.badgeColor = Colors.red,
        TextStyle badgeTextStyle})
      : this.badgeTextStyle = badgeTextStyle ??
      TextStyle(
        color: Colors.white,
        fontSize: 8,
      );
  final Widget icon;
  final int badgeCount;
  final bool showIfZero;
  final Color badgeColor;
  final TextStyle badgeTextStyle;

  @override
  Widget build(BuildContext context) {
    return new Stack(children: <Widget>[
      icon,
      if (badgeCount > 0 || showIfZero) badge(badgeCount),
    ]);
  }

  Widget badge(int count) => Positioned(
    right: 0,
    top: 0,
    child: new Container(
      padding: EdgeInsets.all(1),
      decoration: new BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(7.5),
      ),
      constraints: BoxConstraints(
        minWidth: 15,
        minHeight: 15,
      ),
      child: Text(
        count.toString(),
        style: new TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}