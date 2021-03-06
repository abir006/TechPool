import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/appValidator.dart';
import 'package:tech_pool/pages/CanceledLiftInfo.dart';
import 'package:tech_pool/pages/HomePage.dart';
import 'ChatPage.dart';
import 'ProfilePage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'NotificationInfo.dart';
import 'DesiredRequestPage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tech_pool/main.dart';

import 'RejectedLiftInfo.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _key = GlobalKey<ScaffoldState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  //DateTime selectedDay = DateTime.now();
  List<LiftNotification> _notifications;
  appValidator appValid;
  SlidableController slidableController;
  List<String> net = [];
  Map<String,DocumentSnapshot> mapi = new   Map<String,DocumentSnapshot>();

  void handleSlideAnimationChanged(Animation<double> slideAnimation) {
    // setState(() {
    //
    // });
  }

  void handleSlideIsOpenChanged(bool isOpen) {
    //if(isOpen==true) {
    setState(() {
      try{
      slidableController.activeState.open();}
      catch(e){}
    });

    //  }
  }

  @override
  void initState() {
    super.initState();
    _notifications = [];
    appValid = appValidator();
    appValid.checkConnection(context);
    appValid.checkVersion(context);
    slidableController = SlidableController(
      onSlideAnimationChanged: handleSlideAnimationChanged,
      onSlideIsOpenChanged: handleSlideIsOpenChanged,
    );
  }


  Future<bool> _markAsRead(UserRepository userRep) async {
    try {
      //mark all loaded notifications as readed
      QuerySnapshot q2 = await firestore.collection("Notifications").
      doc(userRep.user?.email).collection("UserNotifications").get();
      q2.docs.forEach((element) async {
        element.reference.update({'read': 'true'});
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteNotification(notificationId, userRep, _key) async {
    //Here will come the query to delete notification from db.
    await firestore.collection("Notifications").
    doc(userRep.user?.email).collection("UserNotifications").
    doc(notificationId).delete().then((value)
    {
      _key.currentState.showSnackBar(SnackBar(content: Text(/*$notification*/"Notification Deleted", style: TextStyle(fontSize: 20))));
      // return value;
    }
    );
  }

  // Future<void> deleteNotification(index, userRep, _key) async {
  //   //Here will come the query to delete notification from db.
  //   await firestore.collection("Notifications").
  //   doc(userRep.user?.email).collection("UserNotifications").
  //   doc(_notifications[index].notificationId).delete().then((value)
  //   {
  //     _key.currentState.showSnackBar(SnackBar(content: Text(/*$notification*/"Notification Deleted", style: TextStyle(fontSize: 20))));
  //     return value;
  //   }
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    //double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return GestureDetector(
        // onTap:() {
        // //   Slidable
        // //       .of(context)
        // //       ?.renderingMode == SlidableRenderingMode.none
        // //       ? Slidable.of(context)?.open()
        // //       : Slidable.of(context)?.close();
        // // },
        //   FocusScope.of(context).requestFocus(new FocusNode());
        //   try{
        //     slidableController.activeState.close();}
        //   catch(e){}},
        child: Stack(
            children: <Widget>[
              Container(
            child: StreamBuilder<List<QuerySnapshot>>(
                stream: CombineLatestStream([ firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").snapshots(),
                  FirebaseFirestore.instance
                      .collection('Profiles')
                      .snapshots(),
                ],(vals) => [vals[0],vals[1]]),
                //return StreamBuilder<List<QuerySnapshot>>(
                //firestore.collection("Notifications").doc("testing@campus.technion.ac.il").collection("UserNotifications").snapshots()],
                //(values) => [values[0]]),
                // stream: CombineLatestStream([
                //   firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").snapshots()],
                //     //firestore.collection("Notifications").doc("testing@campus.technion.ac.il").collection("UserNotifications").snapshots()],
                //         (values) => [values[0]]),
                builder: (context, snapshot) {
                  _notifications = [];
                  if (snapshot.hasData) {
                    snapshot.data[1].docs.forEach((element) {
                      if(element!=null) {
                        mapi[element.id] = element;
                      }
                    });
                    snapshot.data[0].docs.forEach((element) {
                      //snapshot.data[0].docs.forEach((element) {
                      String notificationId = element.id;
                      var elementData = element.data();
                      String driveId = elementData["driveId"];
                      String driverId = elementData["driverId"];//email
                      String startCity = elementData["startCity"];
                      String destCity = elementData["destCity"];
                      int price = elementData["price"];
                      int distance = elementData["distance"];
                      DateTime liftTime = elementData["liftTime"].toDate();
                      DateTime notificationTime = elementData["notificationTime"].toDate();
                      String type = elementData["type"];
                      String startAddress = elementData["startAddress"];
                      String destAddress = elementData["destAddress"];
                      String pasPic = "mapi";
                      String driPic = mapi[driverId].data()["pic"];
                      String pasName = "";
                      String driName = mapi[driverId]["firstName"]+" "+mapi[driverId]["lastName"] ;


                      var notification;
                      switch(type) {
                        case "RequestedLift" :
                          {
                            String passengerId = elementData["passengerId"];
                            String passengerNote = elementData["passengerNote"];
                            bool bigBag = elementData["bigBag"];
                            int price = elementData["price"];
                            String pasPic = mapi[elementData["passengerId"]]?.data()["pic"];
                            String driPic = mapi[driverId].data()["pic"];
                            String pasName = mapi[elementData["passengerId"]]["firstName"]+" "+mapi[elementData["passengerId"]]["lastName"] ;
                            String driName = mapi[driverId]["firstName"]+" "+mapi[driverId]["lastName"] ;
                            // int NumberSeats = elementData["NumberSeats"];
                            // int numberOfPassengers = ;
                            notification = LiftNotification.requested2(
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
                                // NumberSeats,
                                // numberOfPassengers,
                                passengerId,
                                passengerNote,
                                bigBag,
                              pasPic,
                              driPic,
                                pasName,
                                driName,

                            );
                            break;
                          }
                        case "RejectedLift" :
                          {
                            notification = LiftNotification.a(
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
                                pasPic,
                                driPic,
                              pasName,
                              driName,

                            );
                            break;
                          }

                        case "AcceptedLift" :
                          {
                            notification = LiftNotification.a(
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
                              pasPic,
                              driPic,
                              pasName,
                              driName,
                            );
                            break;
                          }
                        case "DesiredLift" :
                          {
                            String desiredId = elementData["desiredId"];
                            notification = LiftNotification.desired2(
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
                              pasPic,
                              driPic,
                              pasName,
                              driName,
                            );
                            break;
                          }
                      //in case a hitchhiker canceled a lift - notify driver
                        case "CanceledLift" :
                          {
                            String passengerId = elementData["passengerId"];
                            String pasPic = mapi[elementData["passengerId"]]?.data()["pic"];
                            String driPic = mapi[driverId].data()["pic"];
                            String pasName = mapi[elementData["passengerId"]]["firstName"]+" "+mapi[elementData["passengerId"]]["lastName"] ;
                            String driName = mapi[driverId]["firstName"]+" "+mapi[driverId]["lastName"] ;
                            notification = LiftNotification.a(
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
                              pasPic,
                              driPic,
                              pasName,
                              driName,
                            );
                            break;
                          }
                      //in case a driver canceled a drive- notify hitchhikers
                        case "CanceledDrive" :
                          {
                            notification = LiftNotification.a(
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
                              pasPic,
                              driPic,
                              pasName,
                              driName,);
                            break;
                          }
                      }
                      _notifications.add(notification);
                    });
                    _markAsRead(userRep);
                    //sorting the notifications to show by time of arrival
                    _notifications.sort((a, b) {
                      if (a.notificationTime.isAfter(b.notificationTime)) {
                        return -1;
                      } else {
                        return 1;
                      }
                    });

                    if(_notifications.length == 0){
                      //double defaultSpacewidth = MediaQuery.of(context).size.width * 0.016;

                      return Scaffold(
                          key: _key,
                          backgroundColor: mainColor,
                        appBar: AppBar(
                          elevation: 0,
                          title: Text(
                            "Notifications",
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
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
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false,)));}
                            )
                          ],
                        ),
                        drawer: techDrawer(userRep, context, DrawerSections.notifications),
                        body: Container(
                        decoration: pageContainerDecoration,
                        margin: pageContainerMargin,
                        //padding: EdgeInsets.only(bottom: 6.0,top: 7.0, left: defaultSpacewidth, right: defaultSpacewidth*4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            //Spacer(),
                            //SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                            Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.update, size: 30),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              Text("No notifications",style: TextStyle(fontSize: 30, color: Colors.black))
                            ]),
                            //Spacer()
                          ],
                        ),

                        ));
                    }
                    else {
                      return _buildPage(context, userRep);
                    }
                  } else if (snapshot.hasError) {
                    return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.error),
                          Text("Error on loading notifications from the database. Please try again.")
                        ]);
                  }
                  else {
                      //return _buildPage(context, userRep);
                    //return Container();
                    return Scaffold(
                        key: _key,
                        backgroundColor: mainColor,
                        appBar: AppBar(
                          elevation: 0,
                          title: Text(
                            "Notifications",
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
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
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false)));}
                            )
                          ],
                        ),
                        drawer: techDrawer(userRep, context, DrawerSections.notifications),
                        body: Container(
                          decoration: pageContainerDecoration,
                          margin: pageContainerMargin,
                          //padding: EdgeInsets.only(bottom: 6.0,top: 7.0, left: defaultSpacewidth, right: defaultSpacewidth*4),
                          child: Center(child: Container())
                    ));
                  }
                }),
          )
            ],
        ),
      );
    });
  }

  Scaffold _buildPage(BuildContext context, UserRepository userRep) {
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    return Scaffold(
      key: _key,
      backgroundColor: mainColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Notifications",
            style: TextStyle(color: Colors.white),
          ),
          actions: [IconButton(
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
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false)));}
          )
          ],
        ),
        drawer: techDrawer(userRep, context, DrawerSections.notifications),
      body:Container(
            padding: const EdgeInsets.only(bottom: 6.0, top: 7.0),
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
            child: Column(
              children: [Expanded(
                  child:ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(left: defaultSpacewidth*0.4, right: defaultSpacewidth*0.4, bottom: defaultSpacewidth*0.4,top:defaultSpacewidth*0.4 ),
                itemCount: _notifications.length,
                //separatorBuilder: (BuildContext context, int index) => Divider(thickness: 1,),
                itemBuilder: (BuildContext context, int index) {
                  final notification = _notifications[index];

                  Widget tileToDisplay;
                  if(_notifications[index].type == "AcceptedLift") {
                    tileToDisplay = _buildAcceptedTile(_notifications[index], userRep);
                  }
                  else if(_notifications[index].type == "RejectedLift") {
                    tileToDisplay = _buildRejectedTile(_notifications[index], userRep);
                  }
                  else if(_notifications[index].type == "RequestedLift") {
                    tileToDisplay = _buildRequestedTile(_notifications[index], userRep);
                    //return tileToDisplay;
                  }
                  else if(_notifications[index].type == "DesiredLift") {
                    tileToDisplay = _buildDesiredTile(_notifications[index], userRep);
                    //return tileToDisplay;
                  }
                  else if(_notifications[index].type == "CanceledLift" || _notifications[index].type == "CanceledDrive") {
                    tileToDisplay = _buildCanceledTile(_notifications[index], userRep);
                  }
                  /*else {
                    tileToDisplay = null;
                  }*/
                  // bool condition = true;
                  // if(condition) {
                    //return Container();
                  return tileToDisplay;

                  // return Slidable(
                  //     //key: Key(notification.notificationId),
                  //     enabled: _notifications.contains(notification),
                  //     controller: slidableController,
                  //     actionPane: SlidableScrollActionPane(),
                  //     actionExtentRatio: 0.23,
                  //     closeOnScroll: false,
                  //     actions: <Widget>[
                  //       Container(
                  //         //padding: EdgeInsets.fromLTRB(0, 1, 0, 12,),
                  //   margin: EdgeInsets.only(
                  //       top: MediaQuery
                  //       .of(context)
                  //       .size
                  //       .height * 0.006,
                  // bottom: MediaQuery
                  //     .of(context)
                  //     .size
                  //     .height * 0.006),
                  //         child: FlatButton(
                  //           shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(10.0)),
                  //           child: Center(child:
                  //           Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(Icons.delete_outline, size: 33, color: Colors.white,),
                  //               Text("Delete", style: TextStyle(
                  //                   color: Colors.white, fontSize: 12),)
                  //             ],
                  //           ),),
                  //           height: 100,
                  //           // caption: 'Delete',
                  //           color: Colors.red,
                  //           //  icon: Icons.delete_outline,
                  //           onPressed: () async {
                  //             FirebaseFirestore.instance.runTransaction((
                  //                 transaction) async {
                  //               // QuerySnapshot q2 = await FirebaseFirestore
                  //               //     .instance
                  //               //     .collection("ChatFriends").doc(
                  //               //     userRep.user?.email).collection("Network")
                  //               //     .doc(document.id.toString()).collection(
                  //               //     document.id.toString())
                  //               //     .get();
                  //
                  //               await firestore.collection("Notifications").
                  //               doc(userRep.user?.email).collection("UserNotifications").
                  //               doc(_notifications[index].notificationId).delete()
                  //               //     .then((value) =>
                  //               // {
                  //               //   _key.currentState.showSnackBar(SnackBar(content: Text("Notification Deleted", style: TextStyle(fontSize: 20))))
                  //               //   //return value;
                  //               // }
                  //               //)
                  //               ;
                  //
                  //               // Future.wait(q2.docs.map((element) {
                  //               //   transaction.delete(element.reference);
                  //               //   return Future(() => Null);
                  //               // }));
                  //               // transaction.delete(
                  //               //     firestore.collection("ChatFriends").doc(
                  //               //         userRep.user?.email)
                  //               //         .collection("Network")
                  //               //         .doc(document.id.toString()));
                  //             });
                  //             FocusScope.of(context).requestFocus(
                  //                 new FocusNode());
                  //             try {
                  //               slidableController.activeState.close();
                  //             }
                  //             catch (e) {}
                  //           },
                  //           //  FirebaseFirestore.instance.runTransaction((transaction) async {
                  //           //    transaction.delete(firestore.collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()));
                  //           //  });
                  //         ),
                  //       ),
                  //     ],
                  //     child: Container(
                  //         child: tileToDisplay
                  //     ),
                  //
                  // );




                      // return Dismissible(
                      //   // Each Dismissible must contain a Key. Keys allow Flutter to
                      //   // uniquely identify widgets.
                      //   key: UniqueKey(),
                      //   //Key(notification.toString()),
                      //   //Key(notification.notificationTime.toString()),
                      //   // Provide a function that tells the app
                      //   // what to do after an item has been swiped away.
                      //   onDismissed: (direction) async {
                      //     //Here will come the query to delete notification from db.
                      //     await firestore.collection("Notifications").
                      //     doc(userRep.user?.email).collection("UserNotifications").
                      //     doc(_notifications[index].notificationId).delete().then((value) =>
                      //     {
                      //       _key.currentState.showSnackBar(SnackBar(content: Text("Notification Deleted", style: TextStyle(fontSize: 20))))
                      //       //return value;
                      //     }
                      //     );
                      //
                      //     //await deleteNotification;
                      //
                      //     /*setState(() {
                      //   // Remove the item from the data source.
                      //   _notifications.removeAt(index);
                      //   });*/
                      //
                      //     // Then show a snackbar.
                      //     //Scaffold.of(context)
                      //     //_key.currentState.showSnackBar(SnackBar(content: Text(/*$notification*/"Notification Deleted", style: TextStyle(fontSize: 20))));
                      //   },
                      //   // Show a red background as the item is swiped away.
                      //   background: //Container(color: mainColor),
                      //
                      //   Container(
                      //     margin: EdgeInsets.only(
                      //         top: MediaQuery
                      //             .of(context)
                      //             .size
                      //             .height * 0.006,
                      //         bottom: MediaQuery
                      //             .of(context)
                      //             .size
                      //             .height * 0.006),
                      //     decoration: BoxDecoration(
                      //       color: mainColor,
                      //       boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      //           spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                      //       border: Border.all(color: secondColor, width: 0.65),
                      //       borderRadius: BorderRadius.circular(12.0),),
                      //     child:
                      //     Row(
                      //       children: [
                      //         Container(
                      //             margin: EdgeInsets.only(
                      //                 left: MediaQuery
                      //                     .of(context)
                      //                     .size
                      //                     .height * 0.016, top: MediaQuery
                      //                 .of(context)
                      //                 .size
                      //                 .height * 0.004),
                      //             width: MediaQuery
                      //                 .of(context)
                      //                 .size
                      //                 .height * 0.016 * 4,
                      //             height: MediaQuery
                      //                 .of(context)
                      //                 .size
                      //                 .height * 0.016 * 4,
                      //             child: Icon(Icons.delete, size: 30, color: Colors.white)
                      //           /*decoration: BoxDecoration(
                      //             shape: BoxShape.circle,
                      //             color: Colors.teal,
                      //             child:
                      //
                      //           )*/
                      //         ),
                      //         Spacer(), // I just added one line
                      //         Container(
                      //             margin: EdgeInsets.only(
                      //               /*left: MediaQuery
                      //                   .of(context)
                      //                   .size
                      //                   .height * 0.016, */
                      //                 top: MediaQuery
                      //                     .of(context)
                      //                     .size
                      //                     .height * 0.004),
                      //             width: MediaQuery
                      //                 .of(context)
                      //                 .size
                      //                 .width * 0.016 * 12,
                      //             height: MediaQuery
                      //                 .of(context)
                      //                 .size
                      //                 .height * 0.016 * 4,
                      //             child: Icon(Icons.delete, size: 30, color: Colors.white)
                      //           /*decoration: BoxDecoration(
                      //             shape: BoxShape.circle,
                      //             color: Colors.teal,
                      //             child:
                      //
                      //           )*/
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      //
                      //
                      //
                      //   child: tileToDisplay,
                      // );



                    // //return _buildTile(_notifications[index]);
                    // if(_notifications[index].type == "AcceptedLift") {
                    //   return _buildAcceptedTile(_notifications[index]);
                    // }
                    // else if(_notifications[index].type == "RejectedLift") {
                    //   return _buildRejectedTile(_notifications[index]);
                    // }
                    // else if(_notifications[index].type == "RequestedLift") {
                    //   return _buildRequestedTile(_notifications[index]);
                    // }
                    // else {
                    //   return null;
                    // }
                    //
                },
              ))],
            )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    appValid.listener.cancel();
    appValid.versionListener.cancel();
  }

  //getting the photo and full name of a driver/hitchhiker
  Future<List<String>> initNames(String name) {
    List<String> ret = [];
    return FirebaseStorage.instance
        .ref('uploads')
        .child(name)
        .getDownloadURL()
        .then((value) {
      ret.add(value);
      return firestore.collection("Profiles").doc(name).get().then((value) {
        ret.add(value.data()["firstName"] + " " + value.data()["lastName"]);
        return ret;
      });
    });
    //  return null;
  }

  Widget _buildAcceptedTile(LiftNotification liftNotification, userRep) {
            return InkWell(
              onTap:  () async {
                //Preparing and opening the info page
                try {
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
                  //liftToShow.stops = [];
                  liftToShow.dist = liftNotification.distance;
                  liftToShow.passengersInfo =
                  Map<String, Map<String, dynamic>>.from(
                      drive.data()["PassengersInfo"] ?? {});
                  liftToShow.payments = (await firestore.collection(
                      "Profiles").doc(liftNotification.driverId).get())
                      .data()["allowedPayments"].join(", ");

                  // FocusScope.of(context).unfocus();
                  // try{
                  //   slidableController.activeState.close();}
                  // catch(e){}

                  await Navigator.of(context).push(new MaterialPageRoute<Null>(
                      builder: (BuildContext context) {
                        return NotificationInfo(
                            lift: liftToShow,
                            notification: liftNotification,
                            type: NotificationInfoType.Accepted);
                      },
                      fullscreenDialog: true
                  ));
                }catch(e){
                  showAlertDialog(context, "Lift is not available", "The lift is no longer available.");
                }

              },
              child: Container(
                margin: EdgeInsets.only(
                    top: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006,
                    bottom: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                  border: Border.all(color: secondColor, width: 0.65),
                  borderRadius: BorderRadius.circular(12.0),),
                child:
                Row(
                  children: [
                    Flexible(flex: 3,
                      child: InkWell(
                          onTap: () async {
                            //FocusScope.of(context).unfocus();
                            // try{
                            //   slidableController.activeState.close();}
                            // catch(e){}

                            await Navigator.of(context).push(
                                MaterialPageRoute<liftRes>(
                                    builder: (BuildContext context) {
                                      return ProfilePage(
                                        email: liftNotification.driverId, fromProfile: false,);
                                    },
                                    fullscreenDialog: true
                                ));
                            // setState(() {
                            //
                            // });
                          },
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.016, top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.004),
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondColor,
                                image: DecorationImage(fit: BoxFit.fill,
                                    image: NetworkImage(liftNotification.driverPic)),

                              ))),
                    ),
                    Flexible(
                      flex: 13,
                      child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016,
                              top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.008),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Flexible(flex:8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        infoText(liftNotification.driverName),
                                        placesText(liftNotification.startCity, liftNotification.destCity),
                                        //allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                                      ],
                                    ),
                                  ),
                                  Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(left: 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.thumb_up_rounded, size: 30, color: Colors.green),
                                              Text("Accepted", style: TextStyle(fontSize: 10, color: Colors.green),)
                                            ],
                                          ),
                                        ),
                                        //   SizedBox(width:20),
                                        Container(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                  child: Icon(Icons.delete_outline, size: 30, color: Colors.black54),
                                                  onTap: () async {
                                                    await deleteNotification(liftNotification.notificationId, userRep, _key);
                                                  }

                                              ),
                                              Text("", style: TextStyle(fontSize: 10, color: Colors.blue),)
                                            ],
                                          ),
                                        )]), //here the icon:
                                ],
                              ),
                              allInfoText(liftNotification.liftTime, liftNotification.distance / 1000),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            );
  }

  Widget _buildDesiredTile(LiftNotification liftNotification, userRep) {
            return InkWell(
              onTap: () async {
try {
  //Preparing and opening the info page
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
  //liftToShow.stops = [];
  liftToShow.dist = liftNotification.distance;
  liftToShow.passengersInfo =
  Map<String, Map<String, dynamic>>.from(
      drive.data()["PassengersInfo"] ?? {});
  liftToShow.payments = (await firestore.collection(
      "Profiles").doc(liftNotification.driverId).get())
      .data()["allowedPayments"].join(", ");

  //Here push request lift page

  // FocusScope.of(context).unfocus();
  // try{
  //   slidableController.activeState.close();}
  // catch(e){}

  await Navigator.of(context).push(new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return DesiredRequestPage(lift: liftToShow,
          notification: liftNotification,
        );
      },
      fullscreenDialog: true
  ));
  // setState(() {
  //
  // });
}catch(e){
  showAlertDialog(context, "Lift is not available", "The lift is no longer available.");
}

              },
              child: Container(
                margin: EdgeInsets.only(
                    top: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006,
                    bottom: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                  border: Border.all(color: secondColor, width: 0.65),
                  borderRadius: BorderRadius.circular(12.0),),
                child:
                Row(
                  children: [
                    Flexible(flex: 3,
                      child: InkWell(
                          onTap: () async {
                            //FocusScope.of(context).unfocus();
                            // try{
                            //   slidableController.activeState.close();}
                            // catch(e){}

                            await Navigator.of(context).push(
                                MaterialPageRoute<liftRes>(
                                    builder: (BuildContext context) {
                                      return ProfilePage(
                                        email: liftNotification.driverId, fromProfile: false,);
                                    },
                                    fullscreenDialog: true
                                ));
                            // setState(() {
                            //
                            // });
                          },
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.016, top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.004),
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondColor,
                                image: DecorationImage(fit: BoxFit.fill,
                                    image: NetworkImage(liftNotification.driverPic)),

                              ))),
                    ),
                    Flexible(
                      flex: 13,
                      child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016,
                              top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.008),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Flexible(flex:8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        infoText(liftNotification.driverName),
                                        placesText(liftNotification.startCity, liftNotification.destCity),
                                        //allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                                      ],
                                    ),
                                  ),
                                  Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(left: 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.fact_check_outlined, size: 30, color: Colors.blue),
                                              Text(" Found  ", style: TextStyle(fontSize: 10, color: Colors.blue),)
                                            ],
                                          ),
                                        ),
                                        //   SizedBox(width:20),
                                        Container(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                  child: Icon(Icons.delete_outline, size: 30, color: Colors.black54),
                                                  onTap: () async {
                                                    await deleteNotification(liftNotification.notificationId, userRep, _key);
                                                  }

                                              ),
                                              Text("", style: TextStyle(fontSize: 10, color: Colors.blue),)
                                            ],
                                          ),
                                        ),
                                      ]),

                                ],
                              ),
                              allInfoText(liftNotification.liftTime, liftNotification.distance / 1000),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            );
  }

  Widget _buildCanceledTile(LiftNotification liftNotification, userRep) {
            return InkWell(
              onTap:  () async {
                await Navigator.of(context).push(new MaterialPageRoute<Null>(
                    builder: (BuildContext context) {
                      return CanceledLiftInfo(
                          notificationId: liftNotification.notificationId,
                          userId: userRep.user?.email,
                          type: liftNotification.type);
                    },
                    fullscreenDialog: true
                ));
              },
              child:
              Container(
                margin: EdgeInsets.only(
                    top: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006,
                    bottom: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                  border: Border.all(color: secondColor, width: 0.65),
                  borderRadius: BorderRadius.circular(12.0),),
                child:
                Row(
                  children: [
                    Flexible(flex: 3,
                      child: InkWell(
                          onTap: () async {
                            //FocusScope.of(context).unfocus();
                            // try{
                            //   slidableController.activeState.close();}
                            // catch(e){}

                            await Navigator.of(context).push(
                                MaterialPageRoute<liftRes>(
                                    builder: (BuildContext context) {
                                      return ProfilePage(
                                        email: liftNotification.type == "CanceledLift" ? liftNotification.passengerId : liftNotification.driverId, fromProfile: false,);
                                    },
                                    fullscreenDialog: true
                                ));
                            // setState(() {
                            //
                            // });
                          },
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.016, top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.004),
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondColor,
                                image: DecorationImage(fit: BoxFit.fill,
                                    image: NetworkImage(liftNotification.type == "CanceledLift" ? liftNotification.passengerPic : liftNotification.driverPic)),

                              ))),
                    ),
                    Flexible(flex: 13,
                      child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016,
                              top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.008),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Flexible(flex:8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        liftNotification.type == "CanceledLift" ? infoTextHitchhiker(liftNotification.passengerName) : infoText(liftNotification.driverName) ,
                                        placesText(liftNotification.startCity, liftNotification.destCity),
                                        //allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                                      ],
                                    ),
                                  ),
                                  Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(left: 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.cancel_outlined, size: 30, color: Colors.red),
                                              Text("Canceled", style: TextStyle(fontSize: 10, color: Colors.red),)
                                            ],
                                          ),
                                        ),
                                        //   SizedBox(width:20),
                                        Container(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                  child: Icon(Icons.delete_outline, size: 30, color: Colors.black54),
                                                  onTap: () async {
                                                    await deleteNotification(liftNotification.notificationId, userRep, _key);
                                                  }

                                              ),
                                              Text("", style: TextStyle(fontSize: 10, color: Colors.blue),)
                                            ],
                                          ),
                                        ),
                                      ]),
                                ],

                              ),
                              allInfoText(liftNotification.liftTime, liftNotification.distance / 1000),
                            ],
                          )
                      ),
                    ),
                    //Spacer(),
                  ],
                ),
              ),
            );
  }


  Widget _buildRejectedTile(LiftNotification liftNotification, userRep) {
            return InkWell(
            onTap:  () async {
              await Navigator.of(context).push(new MaterialPageRoute<Null>(
                  builder: (BuildContext context) {
                    return RejectedLiftInfo(
                        notificationId: liftNotification.notificationId,
                        userId: userRep.user?.email,
                        );
                  },
                  fullscreenDialog: true
              ));
            },
              child: Container(
                margin: EdgeInsets.only(
                    top: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006,
                    bottom: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                  border: Border.all(color: secondColor, width: 0.65),
                  borderRadius: BorderRadius.circular(12.0),),
                child:
                Row(
                  children: [
                    Flexible( flex: 3,
                      child: InkWell(
                          onTap: () async {
                            //FocusScope.of(context).unfocus();
                            // try{
                            //   slidableController.activeState.close();}
                            // catch(e){}

                            await Navigator.of(context).push(
                                MaterialPageRoute<liftRes>(
                                    builder: (BuildContext context) {
                                      return ProfilePage(
                                        email: liftNotification.driverId, fromProfile: false,);
                                    },
                                    fullscreenDialog: true
                                ));
                            // setState(() {
                            //
                            // });
                          },
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.016, top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.004),
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondColor,
                                image: DecorationImage(fit: BoxFit.fill,
                                    image: NetworkImage(liftNotification.driverPic)),

                              ))),
                    ),
                    Flexible( flex: 13,
                      child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016,
                              top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.008),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(flex:8,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              infoText(liftNotification.driverName),
                                              placesText(liftNotification.startCity, liftNotification.destCity),
                                              //allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                                            ],
                                          ),
                                        ),
                                        Row(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(left:5),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.thumb_up_rounded, size: 30, color: Colors.red),
                                                    Text("Rejected", style: TextStyle(fontSize: 10, color: Colors.red),)
                                                  ],
                                                ),
                                              ),
                                              //   SizedBox(width:20),
                                              Container(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    InkWell(
                                                        child: Icon(Icons.delete_outline, size: 30, color: Colors.black54),
                                                        onTap: () async {
                                                          await deleteNotification(liftNotification.notificationId, userRep, _key);
                                                        }

                                                    ),
                                                    Text("", style: TextStyle(fontSize: 10, color: Colors.blue),)
                                                  ],
                                                ),
                                              )]),
                                      ],
                                    ),
                                    allInfoText(liftNotification.liftTime, liftNotification.distance / 1000),
                                  ],
                                ),
                              ),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            );
  }

  Widget _buildRequestedTile(LiftNotification liftNotification, userRep) {
            return InkWell(
              onTap: () async {
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
                // try{
                //   slidableController.activeState.close();}
                // catch(e){}

                await Navigator.of(context).push(new MaterialPageRoute<Null>(
                    builder: (BuildContext context) {
                      return NotificationInfo(
                          lift: liftToShow, notification: liftNotification, type: NotificationInfoType.Requested);
                    },
                    fullscreenDialog: true
                ));
              },
              child: Container(
                margin: EdgeInsets.only(
                    top: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006,
                    bottom: MediaQuery
                        .of(context)
                        .size
                        .height * 0.006),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                  border: Border.all(color: secondColor, width: 0.65),
                  borderRadius: BorderRadius.circular(12.0),),
                child:
                Row(
                  children: [
                    Flexible( flex: 3,
                      child: InkWell(
                          onTap: () async {
                            //FocusScope.of(context).unfocus();
                            // try{
                            //   slidableController.activeState.close();}
                            // catch(e){}
                            await Navigator.of(context).push(
                                MaterialPageRoute<liftRes>(
                                    builder: (BuildContext context) {
                                      return ProfilePage(
                                        email: liftNotification.passengerId, fromProfile: false,);
                                    },
                                    fullscreenDialog: true
                                ));
                            // setState(() {
                            //
                            // });
                          },
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.016, top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.004),
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016 * 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondColor,
                                image: DecorationImage(fit: BoxFit.fill,
                                    image: NetworkImage(liftNotification.passengerPic)),

                              ))),
                    ),
                    Flexible( flex: 13,
                      child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016,
                              top: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.008),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Flexible(flex:8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        infoTextHitchhiker(liftNotification.passengerName),
                                        placesText(liftNotification.startCity, liftNotification.destCity),
                                        //allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                                      ],
                                    ),
                                  ),
                                  Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(left: 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.more_horiz, size: 30, color: Colors.orange),
                                              Text(" Respond ", style: TextStyle(fontSize: 10, color: Colors.orange),)
                                            ],
                                          ),
                                        ),
                                        //   SizedBox(width:20),
                                        liftNotification.liftTime.isBefore(DateTime.now()) ? Container(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                  child: Icon(Icons.delete_outline, size: 30, color: Colors.black54),
                                                  onTap: () async {
                                                    await deleteNotification(liftNotification.notificationId, userRep, _key);
                                                  }

                                              ),
                                              Text("", style: TextStyle(fontSize: 10, color: Colors.blue),)
                                            ],
                                          ),
                                        ) :Container(
                                          margin: EdgeInsets.only(right: 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.delete_outline, size: 5, color: Colors.transparent),
                                              Text("", style: TextStyle(fontSize: 10, color: Colors.blue),)
                                            ],
                                          ),
                                        ) ,]),
                                ],
                              ),
                              allInfoText(liftNotification.liftTime, liftNotification.distance / 1000),

                            ],
                          )),
                    ),
                  ],
                ),
              ),
            );
  }

  Widget allInfoText(DateTime time,double dist){
    return Row(
          children: [
            Icon(Icons.date_range),
            //Text(DateFormat('dd/MM kk:mm').format(time), style: TextStyle(fontSize: 13.5)),
            //SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Text(DateFormat('dd/MM').format(time), style: TextStyle(fontSize: 13.5)),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Icon(Icons.timer),
            //SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Text(DateFormat('kk:mm').format(time), style: TextStyle(fontSize: 13.5)),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
            SizedBox(width: MediaQuery.of(context).size.width * 0.005),
            Text(dist.toStringAsFixed(1)+"km", style: TextStyle(fontSize: 13.5)),
           // SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            //Icon(Icons.person),
            //Text(taken.toString()+"/"+avaliable.toString()),
            //SizedBox(width: MediaQuery.of(context).size.height * 0.01),
            // Container(child:Image.asset("assets/images/shekel.png",scale: 0.9)),
            // SizedBox(width: MediaQuery.of(context).size.height * 0.003),
            // Text(price.toString()),
          ],
        );
  }

  Widget placesText(String from, String to) {
    return  Container(
        width: MediaQuery.of(context).size.height * 0.016*17.5,
        child: Text(from + " \u{2192} " + to,
          style: TextStyle(fontSize: 16, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }

  Widget infoText(String info) {
    return  Container(
        width: MediaQuery.of(context).size.height * 0.016*17.5,
        child: Text("Driver: " + info,
          style: TextStyle(fontSize: 16, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }

  Widget infoTextHitchhiker(String info) {
    return  Container(
        width: MediaQuery.of(context).size.height * 0.016*17.5,
        child: Text("Hitchhiker: " + info,
          style: TextStyle(fontSize: 16, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }
}

///alert dialog that pops when the user pesses on request lift
showAlertDialog(BuildContext context,String title,String info) {
  Widget okButton = FlatButton(
    textColor: mainColor,
    child: Text("OK"),
    onPressed: () {
      Navigator.pop(context);
      Navigator.pop(context);
    },
  );

  Widget cancelButton = FlatButton(
    textColor: mainColor,
    child: Text("Dismiss"),
    onPressed: () {
      Navigator.pop(context);
    },
  );
  AlertDialog alert = AlertDialog(
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0))),
    title: Text(title),
    content: Text(info,style:TextStyle(fontSize: 17)),
    actions: [
      cancelButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}