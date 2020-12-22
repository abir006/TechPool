import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tech_pool/pages/CalendarEventInfo.dart';
import 'package:tech_pool/pages/HomePage.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';
import 'package:tech_pool/pages/ProfilePage.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/widgets/WelcomeSignInButton.dart';
import 'package:tech_pool/widgets/WelcomeSignUpButton.dart';

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

/// A container class for Drive event.
class Drive{
  String driveId;
  String info;
  int numberOfSeats;
  int numberOfPassengers;
  DateTime dateTime;
  Drive(this.driveId,this.info,this.numberOfSeats,this.numberOfPassengers,this.dateTime);
}

/// A container class for Lift event.
class Lift{
  String driveId;
  String info;
  int numberOfSeats;
  int numberOfPassengers;
  DateTime dateTime;
  Lift(this.driveId,this.info,this.numberOfSeats,this.numberOfPassengers,this.dateTime);
}

/*
/// A container class for DesiredLift event.
class DesiredLift{
  String info;
  DesiredLift(this.info);
}

/// A container class for DesiredDrive event.
class DesiredDrive{
  String info;
  DesiredDrive(this.info);
}*/

class LocationsResult{
  Address fromAddress;
  Address toAddress;
  List<Address> stopAddresses;
  int numberOfStops;
  LocationsResult(this.fromAddress, this.toAddress,this.stopAddresses,this.numberOfStops);
}

enum CalendarEventType { Drive, Lift }
/// A util function for the calendar, returns the desired event container to
/// display under the calendar, according to the type of event received.
Widget transformEvent(dynamic event, BuildContext context){
  if (event is Drive) {
    return calendarListTile(event, Icon(Icons.directions_car,size: 30, color: mainColor),context,CalendarEventType.Drive);
  } else if (event is Lift) {
    return calendarListTile(event, Transform.rotate(angle: 0.8,child: Icon(Icons.thumb_up_rounded,size: 30, color: mainColor)),context,CalendarEventType.Lift);
  }
  else{
    return Container();
  }
}

Container calendarListTile(dynamic event,Widget leadingWidget,BuildContext context,CalendarEventType eventType) {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black,blurRadius: 2.0,
        spreadRadius: 0.0,offset: Offset(2.0, 2.0))],
      border: Border.all(color: Colors.green, width: 0.8),
      borderRadius: BorderRadius.circular(12.0),
    ),
    margin:
    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: ListTile(leading: leadingWidget,
      title: Text(event?.info),
      onTap: () async {
        var drive = await firestore.collection("Drives").doc(event.driveId).get();
        MyLift docLift = new MyLift("driver", "destAddress", "stopAddress", 5);
        drive.data().forEach((key, value) {
          if(value!=null) {
            docLift.setProperty(key,value);
          }
        });
        docLift.liftId = event.driveId;
        if(eventType == CalendarEventType.Lift) {
          docLift.stops = [];
        }
        else{
          docLift.dist = 0;
        }
        docLift.passengersInfo = Map<String, Map<String, dynamic>>.from(drive.data()["PassengersInfo"]?? {}) ;
        docLift.payments = (await firestore.collection("Profiles").doc(docLift.driver).get()).data()["allowedPayments"].join(", ");
        Navigator.of(context).push(new MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return CalendarEventInfo(lift: docLift,type: eventType);
            },
            fullscreenDialog: true
        ));
      },
    subtitle: Row(mainAxisAlignment: MainAxisAlignment.start,children: [Text("${(DateFormat.Hm().format(event.dateTime)).toString()}"),Spacer(),Icon(Icons.person,color: Colors.black,),Text(": ${event.numberOfPassengers} / ${event.numberOfSeats}",style: TextStyle(color: Colors.black),)],),
    trailing: Icon(Icons.chevron_right_sharp,color: Colors.black,size:30,)),
  );
}

double clacDis(GeoPoint from,Coordinates to){
  return (Geolocator.distanceBetween(from.latitude,from.longitude,to.latitude,to.longitude).abs());
}


class LiftNotification {
  String driveId;
  String driverId;//email
  //String driverFullName; this.driverFullName,
  String startCity;
  String destCity;
  int price;
  int distance;
  DateTime liftTime;
  DateTime notificationTime;
  String type;
  String passengerId;
  //String pictureUrl;
  // int numberOfSeats;
  // int numberOfPassengers;
  LiftNotification(this.driveId, this.driverId, this.startCity, this.destCity,
      this.price, this.distance, this.liftTime, this.notificationTime,
      this.type, [this.passengerId]);//optional
  LiftNotification.requested(this.driveId, this.driverId, this.startCity, this.destCity,
      this.price, this.distance, this.liftTime, this.notificationTime,
      this.type, this.passengerId);
}

/*class RejectedLiftNotification {
  String driveId;
  String driverFullName;
  String driverId;//email
  String startCity;
  String destCity;
  int price;
  DateTime timeStamp;
  int distance;
  RejectedLiftNotification(this.driveId, this.driverFullName, this.driverId,
      this.startCity, this.destCity, this.price, this.timeStamp, this.distance);
}

class RequestedLiftNotification {
  String driveId;
  String driverFullName;
  String driverId;//email
  String startCity;
  String destCity;
  int price;
  DateTime timeStamp;
  int distance;
  RequestedLiftNotification(this.driveId, this.driverFullName, this.driverId,
      this.startCity, this.destCity, this.price, this.timeStamp, this.distance);
}*/

Container acceptedLiftNotificationListTile(dynamic notification, Widget leadingWidget, Widget trailingWidget, BuildContext context) {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black,blurRadius: 2.0,
          spreadRadius: 0.0,offset: Offset(2.0, 2.0))],
      border: Border.all(color: Colors.green, width: 0.8),
      borderRadius: BorderRadius.circular(12.0),
    ),
    margin:
    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: ListTile(leading: leadingWidget,
        title: Text(notification?.info),
        onTap: () async {
          var drive = await firestore.collection("Drives").doc(notification.driveId).get();
          MyLift docLift = new MyLift("driver", "destAddress", "stopAddress", 5);
          drive.data().forEach((key, value) {
            if(value!=null) {
              docLift.setProperty(key,value);
            }
          });
          docLift.dist = 0;
          /*Navigator.of(context).push(new MaterialPageRoute<Null>(
              builder: (BuildContext context) {
                return LiftInfoPage(lift: docLift);
              },
              fullscreenDialog: true
          ));*/
        },
        subtitle: Row(mainAxisAlignment: MainAxisAlignment.start,children: [Text("${(DateFormat.Hm().format(notification.dateTime)).toString()}"),Spacer(),Icon(Icons.person,color: Colors.black,),Text(": ${notification.numberOfPassengers} / ${notification.numberOfSeats}",style: TextStyle(color: Colors.black),)],),
        trailing: Icon(Icons.chevron_right_sharp,color: Colors.black,size:30,)),
  );
}

Container notificationListTile(dynamic notification, Widget leadingWidget, Widget trailingWidget, BuildContext context) {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black,blurRadius: 2.0,
          spreadRadius: 0.0,offset: Offset(2.0, 2.0))],
      border: Border.all(color: Colors.green, width: 0.8),
      borderRadius: BorderRadius.circular(12.0),
    ),
    margin:
    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: ListTile(leading: leadingWidget,
        title: Text(notification?.info),
        onTap: () async {
          var drive = await firestore.collection("Drives").doc(notification.driveId).get();
          MyLift docLift = new MyLift("driver", "destAddress", "stopAddress", 5);
          drive.data().forEach((key, value) {
            if(value!=null) {
              docLift.setProperty(key,value);
            }
          });
          docLift.dist = 0;
          /*Navigator.of(context).push(new MaterialPageRoute<Null>(
              builder: (BuildContext context) {
                return LiftInfoPage(lift: docLift);
              },
              fullscreenDialog: true
          ));*/
        },
        subtitle: Row(mainAxisAlignment: MainAxisAlignment.start,children: [Text("${(DateFormat.Hm().format(notification.dateTime)).toString()}"),Spacer(),Icon(Icons.person,color: Colors.black,),Text(": ${notification.numberOfPassengers} / ${notification.numberOfSeats}",style: TextStyle(color: Colors.black),)],),
        trailing: Icon(Icons.chevron_right_sharp,color: Colors.black,size:30,)),
  );
}


Widget notificationSwitcher2(dynamic notification,BuildContext context){
  if (notification is LiftNotification) {
    return acceptedLiftNotificationListTile(notification, Icon(Icons.directions_car,size: 30, color: mainColor), Transform.rotate(angle: 0.8,
        child: Icon(Icons.thumb_up_rounded, size: 30, color: Colors.green)), context);
  } /*else if (notification is RejectedLiftNotification) {
    return notificationListTile(notification, Transform.rotate(angle: 0.8,
        child: Icon(Icons.thumb_up_rounded, size: 30, color: mainColor)),
        Icon(Icons.directions_car, size: 30, color: mainColor), context);
  } else if (notification is RequestedLiftNotification) {
    return notificationListTile(notification, Transform.rotate(angle: 0.8,
        child: Icon(Icons.thumb_up_rounded, size: 30, color: mainColor)),
        Icon(Icons.directions_car, size: 30, color: mainColor), context);
  }*/
  else{
    return null;
  }
}



enum NotificationInfoType { Accepted, Requested }


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

/// enum to specify from which page the drawer is called
enum DrawerSections { home, profile, notifications, favorites, chats, settings }

/// returns a Drawer, with the user information from userRep, and highlithing
/// and not rebuilding the current section (page).
SafeArea techDrawer(UserRepository userRep, BuildContext context,
    DrawerSections currentSection) {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  return SafeArea(child: ClipRRect(
      borderRadius: BorderRadius.only(topRight: Radius.circular(20.0),bottomRight:Radius.circular(20.0)),child: Container(width: MediaQuery.of(context).size.width*0.7,
        child: Scaffold(key: _key,
          body: Drawer(
          child: ListView(children: [
            /*  UserAccountsDrawerHeader(
                accountName: Text("Hello, ${userRep.user.displayName}.",style: TextStyle(color: Colors.white,fontSize: 18),),
                accountEmail: Container(height: 20,child: Row(crossAxisAlignment: CrossAxisAlignment.end,mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
              Text(userRep.user.email,style: TextStyle(color: Colors.white,fontSize: 14)),
             IconButton(icon: Icon(Icons.logout,color: Colors.white,size: 25,),onPressed: () => {},)]))
     ,currentAccountPicture: CircleAvatar(backgroundColor: secondColor,))*/
          Container(
            color: mainColor,
            height: 180,
            child: Padding(
              padding: const EdgeInsets.only(top: 50, left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: secondColor,
                    radius: 40,
                    backgroundImage: userRep.profilePicture.image,
                  ),
                  Spacer(),
                  Row(mainAxisSize: MainAxisSize.max,mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(flex: 5,child: Text("Hello, ${userRep.user?.displayName}.",
                        style: TextStyle(color: Colors.white, fontSize: 20))),
                    Flexible(flex: 1,child: IconButton(
                      icon: Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 25,
                      ),
                      onPressed: () async => await (userRep.auth
                          .signOut()
                          .then((_) {
                        final EncryptedSharedPreferences encryptedSharedPreferences = EncryptedSharedPreferences();
                            encryptedSharedPreferences.clear();
                             Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) {
                                      var size = MediaQuery.of(context).size;
                                      return Scaffold(body: Container(height: size.height, width: size.width,color: mainColor,
  child: Stack(alignment: Alignment.center,children: [Image.asset("assets/images/TechPoolWelcomeBackground.png"), TransparentSignInButton(), TransparentSignUnButton()],)));}));
                      })),
                    ))
                  ])
                ],
              ),
            ),
          ),
          drawerListTile("Home",Icons.home_rounded,DrawerSections.home,currentSection, context, userRep,_key),
          drawerListTile("Profile",Icons.person,DrawerSections.profile,currentSection, context, userRep,_key),
          drawerListTile("Notifications",Icons.notifications,DrawerSections.notifications,currentSection, context, userRep,_key),
          drawerListTile("Favorite Locations",Icons.favorite,DrawerSections.favorites,currentSection, context, userRep,_key),
          drawerListTile("Chats",Icons.chat,DrawerSections.chats,currentSection, context, userRep,_key),
          drawerListTile("Settings",Icons.settings,DrawerSections.settings,currentSection, context, userRep,_key)
        ])),
      ))));
}

/// creates a listTile for the drawer, with the relevant pageName,icon,tileSection for the tile.
/// and the currentSection of the drawer.

ListTile drawerListTile(String pageName,IconData icon,DrawerSections tileSection,DrawerSections currentSection, BuildContext context, UserRepository userRep,GlobalKey<ScaffoldState> key) {
  return ListTile(
    selected: currentSection == tileSection,
    leading: Icon(
      icon,
      color: mainColor,
      size: 30,
    ),
    title: Text(
      pageName,
      style: TextStyle(fontSize: 12),
    ),
    onTap: () {
      if (currentSection == tileSection) {
        Navigator.of(context).pop();
      } else {
        switch(tileSection) {
          case DrawerSections.home:
            {
              Navigator.pop(context);
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomePage()));
              break;
            }
          case DrawerSections.profile: {
            Navigator.pop(context);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(email: userRep.user?.email,fromProfile: true)));
            break;
          }
          case DrawerSections.notifications: {
            Navigator.pop(context);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => NotificationsPage()));
            break;
          }
          case DrawerSections.favorites:{
            //Navigator.of(context).pop();
            key.currentState.showSnackBar(SnackBar(content: Text("This feature is not yet implemented", style: TextStyle(fontSize: 20),)));
            break;
          }
          case DrawerSections.chats: {
            //Navigator.of(context).pop();
            key.currentState.showSnackBar(SnackBar(content: Text("This feature is not yet implemented", style: TextStyle(fontSize: 20),)));
            break;
          }
          case DrawerSections.settings: {
            //Navigator.of(context).pop();
            key.currentState.showSnackBar(SnackBar(content: Text("This feature is not yet implemented", style: TextStyle(fontSize: 20,),)));
            break;
          }
        }
      }
    },
  );
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


/// the decoration for the container inside the page body.
final pageContainerDecoration = BoxDecoration(color: Colors.white,borderRadius: BorderRadius.all(Radius.circular(20.0)),
  boxShadow: [BoxShadow(color: Colors.black,blurRadius: 4.0,
      spreadRadius: 0.0,offset: Offset(0.0, 1.0))],);
/// the margin for the container inside the page body.
final pageContainerMargin = EdgeInsets.fromLTRB(10, 4, 10, 10);

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}