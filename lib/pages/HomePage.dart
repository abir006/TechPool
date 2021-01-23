import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tech_pool/appValidator.dart';
import 'package:tech_pool/main.dart';
import 'package:tech_pool/pages/CalendarEventInfo.dart';
import 'package:tech_pool/pages/ChatPage.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tech_pool/CalendarEvents.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'CanceledLiftInfo.dart';
import 'ChatTalkPage.dart';
import 'DesiredRequestPage.dart';
import 'NotificationInfo.dart';
import 'RejectedLiftInfo.dart';
import 'SetDrivePage.dart';
import 'package:flushbar/flushbar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDay = DateTime.now();
  CalendarController _calendarController;
  Map<DateTime, List> _events;
  List _dailyEvents;
  bool firstLoad = true;
  appValidator appValid;

  @override
  void initState() {
    super.initState();
    chatTalkPage = false;
    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message){
          try{
            if (message["data"]["type"] == "Reminder") {
              Flushbar flush;
              flush = Flushbar(backgroundGradient: LinearGradient(
                  colors: [secondColor,Colors.blueGrey,]),
                icon: Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                ),
                titleText: Text(
                  "Reminder:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      color: Colors.white,
                      fontFamily: "ShadowsIntoLightTwo"),
                ),
                messageText: Text(
                  message["notification"]["body"],
                  style: TextStyle(fontSize: 18.0,
                      color: Colors.white,
                      fontFamily: "ShadowsIntoLightTwo"),
                ),
                flushbarPosition: FlushbarPosition.TOP,
                flushbarStyle: FlushbarStyle.GROUNDED,
                reverseAnimationCurve: Curves.decelerate,
                forwardAnimationCurve: Curves.elasticOut,
                onTap: (Flushbar x) async {
                  flush.dismiss();
                  await hourBeforeNotificationPressed(message);
                },
              )..show(context);
            }
          }catch(e){
            print(e);
          }
          return;
        },
      onLaunch: (Map<String, dynamic> message) async {
        if(lastNotifUsed != message["data"]["google.message_id"]) {
          lastNotifUsed = message["data"]["google.message_id"];
          try {
            if (message["data"]["type"] == "Reminder") {
              await hourBeforeNotificationPressed(message);
            }
            if (message["data"]["type"] == "Chat") {
              await chatNotification(message);
            }
            if (message["data"]["type"] == "liftNotification") {
              await liftNotificationPressedOnResume(message);
            }
          }catch(_){}
        }
        return;
      },
      onResume: (Map<String, dynamic> message) async {
        if(lastNotifUsed != message["data"]["google.message_id"]) {
          lastNotifUsed = message["data"]["google.message_id"];
          try {
            if (message["data"]["type"] == "Reminder") {
              await hourBeforeNotificationPressed(message);
            }
            if (message["data"]["type"] == "Chat") {
              await chatNotification2(message);
            }
            if (message["data"]["type"] == "liftNotification") {
              await liftNotificationPressedOnResume(message);
            }
          }catch(_){}
        }
        return;
      },
    );
    _calendarController = CalendarController();
    _events = {};
    _dailyEvents = [];
    appValid = appValidator();
    appValid.checkConnection(context);
    appValid.checkVersion(context);
  }
  Future chatNotification2(Map<String, dynamic> message) async {
    try {
      QuerySnapshot q2 = await  FirebaseFirestore.instance.collection("ChatFriends").doc(message["data"]["idTo"])
          .collection("UnRead").where('idFrom',isEqualTo:message["data"]["idFrom"]).get();

      FirebaseFirestore.instance.runTransaction((transaction) async {
        q2.docs.forEach((element) {
          transaction.delete(element.reference);
        });
      });

      FirebaseFirestore.instance
          .collection("ChatFriends").doc(message["data"]["idTo"]).collection(
          "Network").doc(message["data"]["idFrom"]).collection(
          message["data"]["idFrom"])
          .get().then((value) {
        FirebaseFirestore.instance.runTransaction((transaction) async {
          value.docs.forEach((element) {
            transaction.delete(element.reference);
          });
          try {
            transaction.update(
              FirebaseFirestore.instance.collection("ChatFriends")
                  .doc(message["data"]["idTo"])
                  .collection("Network")
                  .doc(message["data"]["idFrom"]),
              {
                'read': true
              },
            );
          } catch (e) {}
        });
        if(chatTalkPage ==false) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ChatTalkPage(
                        peerId: message["data"]["idFrom"],
                        peerAvatar: message["data"]["imageFrom"],
                        userId: message["data"]["idTo"],
                      )));
        }else{
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ChatTalkPage(
                        peerId: message["data"]["idFrom"],
                        peerAvatar: message["data"]["imageFrom"],
                        userId: message["data"]["idTo"],
                      )));
        }
      });
    }catch(_){}
  }
  Future chatNotification(Map<String, dynamic> message) async {
    try {
     await  Navigator.of(context).push(new MaterialPageRoute(
          builder: (BuildContext context) {
            return ChatPage(currentUserId: message["data"]["idTo"],photo:message["data"]["imageFrom"],idFrom:message["data"]["idFrom"],fromNotification: true  ,);
          },
      ));
      /*  QuerySnapshot q2 = await FirebaseFirestore.instance
            .collection("ChatFriends").doc(message["data"]["idTo"]).collection(
            "Network").doc(message["data"]["idFrom"]).collection(
            message["data"]["idFrom"])
            .get();

        FirebaseFirestore.instance.runTransaction((transaction) async {
          q2.docs.forEach((element) {
            transaction.delete(element.reference);
          });
          try {
            transaction.update(
              FirebaseFirestore.instance.collection("ChatFriends")
                  .doc(message["data"]["idTo"])
                  .collection("Network")
                  .doc(message["data"]["idFrom"]),
              {
                'read': true
              },
            );
          } catch (e) {}
        });
        return Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ChatTalkPage(
                      peerId: message["data"]["idFrom"],
                      peerAvatar: message["data"]["imageFrom"],
                      userId: message["data"]["idTo"],
                    )));*/
    }catch(_){}
  }

  void ff(Map<String, dynamic> message){
    return;
  }

  Future hourBeforeNotificationPressed(Map<String, dynamic> message) async {
      try {
      var type;
      MyLift docLift = new MyLift(
          "driver", "destAddress", "stopAddress", 5);
      var tempLift = (await firestore.collection("Drives").doc(
          message["data"]["driveId"]).get()).data();
      tempLift.forEach((key, value) {
        if (value != null) {
          docLift.setProperty(key, value);
        }
      });
      docLift.liftId = message["data"]["driveId"];
      if (message["data"]["pagetype"] == "Driver") {
        type = CalendarEventType.Drive;
      } else {
        print(Provider
            .of<UserRepository>(context, listen: false)
            .user
            .email);
        docLift.bigBag = tempLift["PassengersInfo"][Provider
            .of<UserRepository>(context, listen: false)
            .user
            .email]["bigBag"];
        docLift.dist = 0;
        type = CalendarEventType.Lift;
      }
      docLift.passengersInfo = Map<String, Map<String, dynamic>>.from(
          tempLift["PassengersInfo"] ?? {});
      docLift.payments =
          (await firestore.collection("Profiles")
              .doc(docLift.driver)
              .get())
              .data()["allowedPayments"].join(", ");
      await Navigator.of(context).push(new MaterialPageRoute<Null>(
          builder: (BuildContext context) {
            return CalendarEventInfo(lift: docLift, type: type);
          },
          fullscreenDialog: true
      ));
    }catch(_){}
  }


  Future liftNotificationPressedOnResume(Map<String, dynamic> message) async {
    try {
      String currentUserId = Provider
          .of<UserRepository>(context, listen: false)
          .user.email;
      //String driveId = message["data"]["driveId"];
      String notificationId = message["data"]["notificationId"];
      var notificationDoc = await firestore.collection("Notifications")
          .doc(currentUserId)
          .collection("UserNotifications")
          .doc(notificationId).get();
      var elementData = notificationDoc.data();

      String driveId = elementData["driveId"];
      String driverId = elementData["driverId"]; //email
      String startCity = elementData["startCity"];
      String destCity = elementData["destCity"];
      int price = elementData["price"];
      int distance = elementData["distance"];
      DateTime liftTime = elementData["liftTime"].toDate();
      DateTime notificationTime = elementData["notificationTime"].toDate();
      String type = elementData["type"];
      String startAddress = elementData["startAddress"];
      String destAddress = elementData["destAddress"];

      var liftNotification;
      switch (type) {
        case "RequestedLift" :
          {
            String passengerId = elementData["passengerId"];
            String passengerNote = elementData["passengerNote"];
            bool bigBag = elementData["bigBag"];
            int price = elementData["price"];
            liftNotification = LiftNotification.requested(
                notificationId,
                driveId,
                driverId,
                startCity,
                destCity,
                price,
                distance,
                liftTime,
                notificationTime,
                type,
                startAddress,
                destAddress,
                passengerId,
                passengerNote,
                bigBag
            );

            var drive = await firestore.collection("Drives").doc(
                liftNotification.driveId).get();
            MyLift liftToShow = new MyLift(
                "driver", "destAddress", "stopAddress", 5);
            drive.data().forEach((key, value) {
              if (value != null) {
                liftToShow.setProperty(key, value);
              }
            });

            liftToShow.note = liftNotification.passengerNote;
            liftToShow.liftId = liftNotification.driveId;
            liftToShow.dist = liftNotification.distance;

            liftToShow.passengersInfo =
            Map<String, Map<String, dynamic>>.from(
                drive.data()["PassengersInfo"] ?? {});
            liftToShow.payments = (await firestore.collection(
                "Profiles").doc(liftNotification.passengerId).get())
                .data()["allowedPayments"].join(", ");

            // FocusScope.of(context).unfocus();
            // try {
            //   slidableController.activeState.close();
            // }
            // catch (e) {}

            await Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return NotificationInfo(
                      lift: liftToShow,
                      notification: liftNotification,
                      type: NotificationInfoType.Requested);
                },
                fullscreenDialog: true
            ));

            break;

          }
        case "AcceptedLift" :
          {
            liftNotification = LiftNotification(
                notificationId,
                driveId,
                driverId,
                startCity,
                destCity,
                price,
                distance,
                liftTime,
                notificationTime,
                type,
                startAddress,
                destAddress
            );

            var drive = await firestore.collection("Drives").doc(
                liftNotification.driveId).get();
            MyLift liftToShow = new MyLift(
                "driver", "destAddress", "stopAddress", 5);
            drive.data().forEach((key, value) {
              if (value != null) {
                liftToShow.setProperty(key, value);
              }
            });
            liftToShow.liftId = driveId;
            liftToShow.dist = liftNotification.distance;
            liftToShow.passengersInfo =
            Map<String, Map<String, dynamic>>.from(
                drive.data()["PassengersInfo"] ?? {});
            liftToShow.payments = (await firestore.collection(
                "Profiles").doc(liftToShow.driver).get())
                .data()["allowedPayments"].join(", ");

            await Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return NotificationInfo(
                      lift: liftToShow,
                      notification: liftNotification,
                      type: NotificationInfoType.Accepted);
                },
                fullscreenDialog: true
            ));

            break;
          }
        case "DesiredLift" :
          {
            String desiredId = elementData["desiredId"];
            liftNotification = LiftNotification.desired(
              notificationId,
              driveId,
              driverId,
              startCity,
              destCity,
              price,
              distance,
              liftTime,
              notificationTime,
              type,
              startAddress,
              destAddress,
              desiredId,
            );

            var drive = await firestore.collection("Drives").doc(
                liftNotification.driveId).get();
            MyLift liftToShow = new MyLift(
                "driver", "destAddress", "stopAddress", 5);
            drive.data().forEach((key, value) {
              if (value != null) {
                liftToShow.setProperty(key, value);
              }
            });
            liftToShow.liftId = liftNotification.driveId;
            liftToShow.dist = liftNotification.distance;
            liftToShow.passengersInfo =
            Map<String, Map<String, dynamic>>.from(
                drive.data()["PassengersInfo"] ?? {});
            liftToShow.payments = (await firestore.collection(
                "Profiles").doc(liftNotification.driverId).get())
                .data()["allowedPayments"].join(", ");

            //Here push request lift page

            await Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return DesiredRequestPage(lift: liftToShow,
                    notification: liftNotification,
                  );
                },
                fullscreenDialog: true
            ));


            break;
          }

      case "RejectedLift" :
        {
          liftNotification = LiftNotification(
              notificationId,
              driveId,
              driverId,
              startCity,
              destCity,
              price,
              distance,
              liftTime,
              notificationTime,
              type,
              startAddress,
              destAddress);

          await Navigator.of(context).push(new MaterialPageRoute<Null>(
              builder: (BuildContext context) {
                return RejectedLiftInfo(
                  notificationId: liftNotification.notificationId,
                  userId: currentUserId,
                );
              },
              fullscreenDialog: true
          ));

          break;
        }

      //in case a hitchhiker canceled a lift - notify driver
        case "CanceledLift" :
          {
            String passengerId = elementData["passengerId"];
            liftNotification = LiftNotification(
                notificationId,
                driveId,
                driverId,
                startCity,
                destCity,
                price,
                distance,
                liftTime,
                notificationTime,
                type,
                startAddress,
                destAddress,
                passengerId
            );

            await Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return CanceledLiftInfo(
                      notificationId: liftNotification.notificationId,
                      userId: currentUserId,
                      type: liftNotification.type);
                },
                fullscreenDialog: true
            ));

            break;
          }
      //in case a driver canceled a drive- notify hitchhikers
        case "CanceledDrive" :
          {
            liftNotification = LiftNotification(
                notificationId,
                driveId,
                driverId,
                startCity,
                destCity,
                price,
                distance,
                liftTime,
                notificationTime,
                type,
                startAddress,
                destAddress);

            await Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return CanceledLiftInfo(
                      notificationId: liftNotification.notificationId,
                      userId: currentUserId,
                      type: liftNotification.type);
                },
                fullscreenDialog: true
            ));

            break;
          }

      }
    }
    catch(_){

    }
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
    setState(() {
      selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<List<QuerySnapshot>>(
              stream: CombineLatestStream([
              firestore.collection("Drives").where("Passengers", arrayContains: userRep.user?.email).snapshots(),firestore
                    .collection("Drives")
                    .where('Driver', isEqualTo: userRep.user?.email).snapshots(),firestore.collection("Notifications").doc(userRep.user?.email).collection("Pending").snapshots(),
                firestore
                    .collection("Desired")
                    .where('passengerId', isEqualTo: userRep.user?.email).snapshots()],(vals) => [vals[0],vals[1],vals[2],vals[3]]),
              builder: (context, snapshot) {
                _events = {};
                _dailyEvents = [];
                if (snapshot.hasData) {
                  snapshot.data[1].docs.forEach((element) {
                    try {
                      var elementData = element.data();
                      DateTime elementTime = elementData["TimeStamp"].toDate();
                      var drive = Drive(element.id,
                          elementData["StartCity"] +
                              " \u{2192} " +
                              elementData["DestCity"],
                          elementData["NumberSeats"],
                          elementData["Passengers"].length,
                          elementTime);
                      _events[Jiffy(elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] =
                          (_events[Jiffy(elementTime)
                              .startOf(Units.DAY)
                              .add(Duration(hours: 12))] ??
                              []) +
                              [drive];
                      if (elementTime
                          .isAfter(Jiffy(selectedDay).startOf(Units.DAY)) &&
                          elementTime
                              .isBefore(Jiffy(selectedDay).endOf(Units.DAY))) {
                        _dailyEvents.add(drive);
                      }
                    }catch(e){
                    }
                  });
                  snapshot.data[0].docs.forEach((element) {
                    try {
                      var elementData = element.data();
                      DateTime elementTime = elementData["TimeStamp"].toDate();
                      var lift = Lift(element.id,
                          elementData["StartCity"] +
                              " \u{2192} " +
                              elementData["DestCity"],
                          elementData["NumberSeats"],
                          elementData["Passengers"].length,
                          elementTime,elementData["PassengersInfo"][userRep.user.email]["bigBag"]);
                      _events[Jiffy(elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] = (_events[Jiffy(
                          elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] ??
                          []) +
                          [lift];
                      if (elementTime
                          .isAfter(Jiffy(selectedDay).startOf(Units.DAY)) &&
                          elementTime
                              .isBefore(Jiffy(selectedDay).endOf(Units.DAY))) {
                        _dailyEvents.add(lift);
                      }
                    }catch(e){
                    }
                  });
                  snapshot.data[2].docs.forEach((element) {
                    try {
                      var elementData = element.data();
                      DateTime elementTime = elementData["liftTime"].toDate();
                      var lift = PendingLift(elementData["startAddress"],elementData["destAddress"],elementData["driveId"],
                          elementData["startCity"] +
                              " \u{2192} " +
                              elementData["destCity"],
                          elementTime,elementData["distance"],elementData["passengerNote"],elementData["bigBag"]);
                      _events[Jiffy(elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] = (_events[Jiffy(
                          elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] ??
                          []) +
                          [lift];
                      if (elementTime
                          .isAfter(Jiffy(selectedDay).startOf(Units.DAY)) &&
                          elementTime
                              .isBefore(Jiffy(selectedDay).endOf(Units.DAY))) {
                        _dailyEvents.add(lift);
                      }
                    }catch(e){
                    }
                  });
                  snapshot.data[3].docs.forEach((element) {
                    try {
                      var elementData = element.data();
                      DateTime elementTime = elementData["liftTimeStart"].toDate();
                      var lift = DesiredLift(elementData["startCity"] +
                          " \u{2192} " +
                          elementData["destCity"],element.id,elementData["liftTimeStart"].toDate(),elementData["liftTimeEnd"].toDate(),elementData["maxDistance"],
                          elementData["startAddress"],elementData["startCity"],elementData["destAddress"],elementData["destCity"],
                          elementData["bigTrunk"],elementData["backSeatNotFull"]);
                      _events[Jiffy(elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] = (_events[Jiffy(
                          elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] ??
                          []) +
                          [lift];
                      if (elementTime
                          .isAfter(Jiffy(selectedDay).startOf(Units.DAY)) &&
                          elementTime
                              .isBefore(Jiffy(selectedDay).endOf(Units.DAY))) {
                        _dailyEvents.add(lift);
                      }
                    }catch(e){
                      print(e);
                    }
                  });
                  _dailyEvents.sort((a, b) {
                    if (a.dateTime.isAfter(b.dateTime)) {
                      return 1;
                    } else {
                      return -1;
                    }
                  });
                  return _buildPage(context, userRep);
                } else if (snapshot.hasError) {
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.error),
                        Text("Error loading events from cloud")
                      ]);
                } else {
                  return Scaffold(backgroundColor: mainColor,
                  appBar: AppBar(
                  elevation: 0,
                      title: Text(
                      "Home",
                      style: TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                      icon: StreamBuilder(
                          stream: firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").where("read", isEqualTo: "false").snapshots(), // a previously-obtained Future<String> or null
                          builder: (BuildContext context, snapshot) {
                            if (snapshot.hasData) {
                              //QuerySnapshot values = snapshot.data;
                              //builder: (_, snapshot) =>
                              return BadgeIcon(
                                icon: Icon(Icons.notifications, size: 25),
                                badgeCount: snapshot.data.size,
                              );
                            }
                            else{
                              return BadgeIcon(
                                icon: Icon(Icons.notifications, size: 25),
                                badgeCount: 0,
                              );
                            }
                          }
                      ),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotificationsPage()))
                  ),   IconButton(
                      icon: StreamBuilder(
                          stream: firestore.collection("ChatFriends").doc(userRep.user?.email).collection("UnRead").snapshots(), // a previously-obtained Future<String> or null
                          builder: (BuildContext context, snapshot) {
                            if (snapshot.hasData) {
                              //QuerySnapshot values = snapshot.data;
                              //builder: (_, snapshot) =>

                              return BadgeIcon(
                                icon: Icon(Icons.message_outlined, size: 25),
                                badgeCount: snapshot.data.size,
                              );
                            }
                            else{
                              return BadgeIcon(
                                icon: Icon(Icons.message_outlined, size: 25),
                                badgeCount: 0,
                              );
                            }
                          }
                      ),
                      onPressed: () async {
                        QuerySnapshot q2 = await  FirebaseFirestore.instance.collection("ChatFriends").doc(userRep.user.email)
                            .collection("UnRead").get();

                        FirebaseFirestore.instance.runTransaction((transaction) async {
                          q2.docs.forEach((element) {
                            transaction.delete(element.reference);
                          });
                        });
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false,)));}
                  )
                ],
                ),
                drawer: techDrawer(userRep, context, DrawerSections.home),
                body: WillPopScope(
                onWillPop: _onBackPressed,
                child:Container(
                decoration: pageContainerDecoration,
                margin: pageContainerMargin,
                child: Center(child: CircularProgressIndicator()))));
                }
              });
    });
  }

  /// the page content that needs to be showed if snapshot has and transformed correctly.
  Scaffold _buildPage(BuildContext context, UserRepository userRep) {
    return Scaffold(
        floatingActionButton: Wrap(
          spacing: 5,
          direction: Axis.vertical,
          children: [
            FloatingActionButton(
              heroTag: "drive",
              backgroundColor: selectedDay.isBefore(Jiffy(DateTime.now()).startOf(Units.DAY)) ? Colors.grey : mainColor,
              child: Icon(
                Icons.directions_car,
                size: 35,
                color: Colors.white,
              ),
              onPressed: () async {
                if (selectedDay.isBefore(Jiffy(DateTime.now()).startOf(Units.DAY))) {
                  showDialog(context: context,child: AlertDialog(title: Text("Drive error"),content: Text("Cant set a drive for a date that has already passed."),actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Dismiss"))],));
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return SetDrivePage(currentDate: selectedDay);
                      },
                    ),
                  );
                }
              }
            ),
            Transform.rotate(
                angle: 0.8,
                child: FloatingActionButton(
                  heroTag: "lift",
                  backgroundColor: selectedDay.isBefore(Jiffy(DateTime.now()).startOf(Units.DAY)) ? Colors.grey : Colors.black,
                  child: Icon(
                    Icons.thumb_up_rounded,
                    size: 30,
                  ),
                  onPressed: () {
                    if (selectedDay.isBefore(
                        Jiffy(DateTime.now()).startOf(Units.DAY))) {
                      showDialog(context: context,
                          child: AlertDialog(title: Text("Lift error"),
                            content: Text(
                                "Cant search a lift for a date that has already passed."),
                            actions: [TextButton(onPressed: () =>
                                Navigator.pop(context),
                                child: Text("Dismiss"))
                            ],));
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                            return SearchLiftPage(
                              currentdate: selectedDay,
                              popOrNot: false,
                            );
                          },
                        ),
                      );
                    }
                  }
                ))
          ],
        ),
        backgroundColor: mainColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Home",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
                icon: StreamBuilder(
                stream: firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").where("read", isEqualTo: "false").snapshots(), // a previously-obtained Future<String> or null
                builder: (BuildContext context, snapshot) {
                  if (snapshot.hasData) {
                    //QuerySnapshot values = snapshot.data;
                    //builder: (_, snapshot) =>
                    return BadgeIcon(
                      icon: Icon(Icons.notifications, size: 25),
                      badgeCount: snapshot.data.size,
                    );
                  }
                  else{
                    return BadgeIcon(
                      icon: Icon(Icons.notifications, size: 25),
                      badgeCount: 0,
                    );
                  }
                }
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsPage()))
            ),
            IconButton(
                icon: StreamBuilder(
                    stream: firestore.collection("ChatFriends").doc(userRep.user?.email).collection("UnRead").snapshots(), // a previously-obtained Future<String> or null
                    builder: (BuildContext context, snapshot) {
                      if (snapshot.hasData) {
                        //QuerySnapshot values = snapshot.data;
                        //builder: (_, snapshot) =>

                        return BadgeIcon(
                          icon: Icon(Icons.message_outlined, size: 25),
                          badgeCount: snapshot.data.size,
                        );
                      }
                      else{
                        return BadgeIcon(
                          icon: Icon(Icons.notifications, size: 25),
                          badgeCount: 0,
                        );
                      }
                    }
                ),
                onPressed: () async {
                  QuerySnapshot q2 = await  FirebaseFirestore.instance.collection("ChatFriends").doc(userRep.user.email)
                      .collection("UnRead").get();

                  FirebaseFirestore.instance.runTransaction((transaction) async {
                    q2.docs.forEach((element) {
                      transaction.delete(element.reference);
                    });
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false,)));}
            )
          ],
        ),
        drawer: techDrawer(userRep, context, DrawerSections.home),
        body: WillPopScope(
    onWillPop: _onBackPressed,
    child:Container(
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            child: Column(children: [
              TableCalendar(
                  initialSelectedDay: selectedDay,
                  daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: secondColor)),
                  calendarStyle: CalendarStyle(
                      markersColor: secondColor,
                      selectedColor: mainColor,
                      todayColor: mainColor[100]),
                  weekendDays: [5, 6],
                  availableCalendarFormats: {
                    CalendarFormat.month: 'Week',
                    CalendarFormat.week: 'Month'
                  },
                  calendarController: _calendarController,
                  events: _events,
                  onDaySelected: _onDaySelected),
              Divider(indent: 5, endIndent: 5, thickness: 2),
              Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: ListView(children: [...(_dailyEvents.isEmpty? [ListTile(leading: Icon(Icons.calendar_today),title: Text("No events yet"),)] :
                    _dailyEvents.map((event) => transformEvent(event,context)).toList())
              ]),
                  )),
            ]))));
  }

  @override
  void dispose() {
    _calendarController.dispose();
    appValid.listener.cancel();
    appValid.versionListener.cancel();
    super.dispose();
  }

  Future<bool> _onBackPressed() {
    return showDialog(
      context: context,
      builder: (context) =>  AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
        title:  Text('Are you sure?'),
        content:  Text('Do you want to exit an App'),
        actions: <Widget>[
      TextButton(onPressed: () => Navigator.of(context).pop(false),
            child: Text("NO"),
          ),
          SizedBox(height: 16),
          TextButton(onPressed: () => SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop'), child: Text("YES"),
          ),
        ],
      ),
    ) ??
        false;
  }
}
