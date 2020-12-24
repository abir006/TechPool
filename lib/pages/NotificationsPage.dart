import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import '../appValidator.dart';
import 'ProfilePage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'NotificationInfo.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDay = DateTime.now();
  List<LiftNotification> _notifications;
  appValidator appValid;

  @override
  void initState() {
    super.initState();
    _notifications = [];
    appValid = appValidator();
    appValid.checkConnection(context);
    appValid.checkVersion(context);
  }

  @override
  Widget build(BuildContext context) {
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<List<QuerySnapshot>>(
          stream: CombineLatestStream([
            firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").snapshots()],
              //firestore.collection("Notifications").doc("testing@campus.technion.ac.il").collection("UserNotifications").snapshots()],
                  (values) => [values[0]]),
          builder: (context, snapshot) {
            _notifications = [];
              if (snapshot.hasData) {
              snapshot.data[0].docs.forEach((element) {
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

                var notification;
                switch(type) {
                  case "RequestedLift" :
                    {
                      String passengerId = elementData["passengerId"];
                      String passengerNote = elementData["passengerNote"];
                      bool bigBag = elementData["bigBag"];
                      int price = elementData["price"];
                      // int NumberSeats = elementData["NumberSeats"];
                      // int numberOfPassengers = ;
                      notification = LiftNotification.requested(
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
                          bigBag
                      );
                      break;
                    }
                  case "RejectedLift" :
                    {
                      notification = LiftNotification(
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
                      break;
                    }

                  case "AcceptedLift" :
                    {
                      notification = LiftNotification(
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
                      break;
                    }
                    //in case a hitchhiker canceled a lift - notify driver
                  case "CanceledLift" :
                    {
                      String passengerId = elementData["passengerId"];
                      notification = LiftNotification(
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
                      break;
                    }
                //in case a driver canceled a drive- notify hitchhikers
                  case "CanceledDrive" :
                    {
                      notification = LiftNotification(
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
                      break;
                    }
                }
                _notifications.add(notification);
              });
              _notifications.sort((a, b) {
                if (a.notificationTime.isAfter(b.notificationTime)) {
                  return 1;
                } else {
                  return -1;
                }
              });
              if(_notifications.length == 0){
                double defaultSpacewidth = MediaQuery.of(context).size.width * 0.016;

                return Scaffold(
                  backgroundColor: mainColor,
                  appBar: AppBar(
                    elevation: 0,
                    title: Text(
                      "Notifications",
                      style: TextStyle(color: Colors.white),
                    ),
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
                          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                          Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.update, size: 30),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                            Text("No notifications",style: TextStyle(fontSize: 30, color: Colors.black))
                          ]),
                          Spacer()
                        ],
                      ),

                  ));
              }
              return _buildPage(context, userRep);
            } else if (snapshot.hasError) {
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.error),
                    Text("Error on loading notifications from the database. Please try again.")
                  ]);
            } else {
                return _buildPage(context, userRep);
            }
          });
    });
  }

  Scaffold _buildPage(BuildContext context, UserRepository userRep) {
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    return Scaffold(
        backgroundColor: mainColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Notifications",
            style: TextStyle(color: Colors.white),
          ),
        ),
        drawer: techDrawer(userRep, context, DrawerSections.notifications),
      body:Container(
          padding: const EdgeInsets.only(bottom: 6.0, top: 7.0),
          decoration: pageContainerDecoration,
          margin: pageContainerMargin,
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          child: Column(
            children: [Expanded(child:ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(left: defaultSpacewidth*0.4, right: defaultSpacewidth*0.4, bottom: defaultSpacewidth*0.4,top:defaultSpacewidth*0.4 ),
              itemCount: _notifications.length,
              //separatorBuilder: (BuildContext context, int index) => Divider(thickness: 1,),
              itemBuilder: (BuildContext context, int index) {
                final notification = _notifications[index];

                Widget tileToDisplay;
                if(_notifications[index].type == "AcceptedLift") {
                  tileToDisplay = _buildAcceptedTile(_notifications[index]);
                }
                else if(_notifications[index].type == "RejectedLift") {
                  tileToDisplay = _buildRejectedTile(_notifications[index]);
                }
                else if(_notifications[index].type == "RequestedLift") {
                  tileToDisplay = _buildRequestedTile(_notifications[index]);
                  return tileToDisplay;
                }
                else if(_notifications[index].type == "CanceledLift" || _notifications[index].type == "CanceledDrive") {
                  tileToDisplay = _buildCanceledTile(_notifications[index]);
                }
                /*else {
                  tileToDisplay = null;
                }*/

                return Dismissible(
                  // Each Dismissible must contain a Key. Keys allow Flutter to
                  // uniquely identify widgets.
                  key: UniqueKey(),
                  //Key(notification.toString()),
                  //Key(notification.notificationTime.toString()),
                  // Provide a function that tells the app
                  // what to do after an item has been swiped away.
                  onDismissed: (direction) async {
                    //Here will come the query to delete notification from db.
                    await firestore.collection("Notifications").
                    doc(userRep.user?.email).collection("UserNotifications").
                    doc(_notifications[index].notificationId).delete();
                    setState(() {
                    // Remove the item from the data source.
                    _notifications.removeAt(index);
                    });

                    // Then show a snackbar.
                    Scaffold.of(context)
                        .showSnackBar(SnackBar(content: Text(/*$notification*/"Notification Deleted", style: TextStyle(fontSize: 20))));
                  },
                  // Show a red background as the item is swiped away.
                  background: //Container(color: mainColor),

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
                      color: mainColor,
                      boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2.0,
                          spreadRadius: 0.0, offset: Offset(2.0, 2.0))
                      ],
                      border: Border.all(color: secondColor, width: 0.65),
                      borderRadius: BorderRadius.circular(12.0),),
                    child:
                    Row(
                      children: [
                        Container(
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
                          child: Icon(Icons.delete, size: 30, color: Colors.white)
                          /*decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal,
                              child:

                            )*/
                        ),
                        Spacer(), // I just added one line
                        Container(
                            margin: EdgeInsets.only(
                                /*left: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.016, */
                                top: MediaQuery
                                .of(context)
                                .size
                                .height * 0.004),
                            width: MediaQuery
                                .of(context)
                                .size
                                .width * 0.016 * 12,
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.016 * 4,
                            child: Icon(Icons.delete, size: 30, color: Colors.white)
                          /*decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal,
                              child:

                            )*/
                        ),
                      ],
                    ),
                  ),



                  child: tileToDisplay,
                );

                //return _buildTile(_notifications[index]);
                if(_notifications[index].type == "AcceptedLift") {
                  return _buildAcceptedTile(_notifications[index]);
                }
                else if(_notifications[index].type == "RejectedLift") {
                  return _buildRejectedTile(_notifications[index]);
                }
                else if(_notifications[index].type == "RequestedLift") {
                  return _buildRequestedTile(_notifications[index]);
                }
                else {
                  return null;
                }
              },
            ))],
          )),
        /*body: Container(
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            child: Column(children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.013),
            //Divider(indent: 5, endIndent: 5, thickness: 2),
              Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child:

                    /*ListView(children: [
                      ..._notifications.map((notification) => notificationSwitcher(notification, context)).toList()
                    ]
                    ),*/
                    ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(left: defaultSpacewidth*0.4, right: defaultSpacewidth*0.4, bottom: defaultSpacewidth*0.4,top:defaultSpacewidth*0.4 ),
                      itemCount: _notifications.length,
                      separatorBuilder: (BuildContext context, int index) => Divider(thickness: 4,),
                      itemBuilder: (BuildContext context, int index) {
                        return _buildTile(_notifications[index]);
                      },
                    )


                  )),
            ])
        )*/
    );
  }

  @override
  void dispose() {
    super.dispose();
    appValid.listener.cancel();
    appValid.versionListener.cancel();
  }


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

  Widget _buildAcceptedTile(LiftNotification liftNotification) {
    return FutureBuilder<List<String>>(
        future: initNames(liftNotification.driverId),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
            return Container(
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
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2.0,
                    spreadRadius: 0.0, offset: Offset(2.0, 2.0))
                ],
                border: Border.all(color: secondColor, width: 0.65),
                borderRadius: BorderRadius.circular(12.0),),
              child:
              Row(
                children: [
                  Flexible(flex: 3,
                    child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                              MaterialPageRoute<liftRes>(
                                  builder: (BuildContext context) {
                                    return ProfilePage(
                                      email: liftNotification.driverId, fromProfile: false,);
                                  },
                                  fullscreenDialog: true
                              ));
                          setState(() {

                          });
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
                                  image: NetworkImage(snapshot.data[0])),

                            ))),
                  ),
                  Flexible(
                    flex: 8,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            infoText(snapshot.data[1]),
                            placesText(liftNotification.startCity, liftNotification.destCity),
                            allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                          ],
                        )),
                  ),
                  Flexible(flex:3,
                    child: InkWell(
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.016*16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Transform.rotate(angle: 0.8,
                                child: Icon(Icons.thumb_up_rounded, size: 30, color: Colors.green)),
                            Text("Accepted", style: TextStyle(fontSize: 15, color: Colors.green),
                            )
                          ],
                        ),
                      ),

                      //AcceptedInfoPage
                      onTap:  () async {
                        var drive = await firestore.collection("Drives").doc(
                            liftNotification.driveId).get();
                        MyLift liftToShow = new MyLift(
                            "driver", "destAddress", "stopAddress", 5);
                        drive.data().forEach((key, value) {
                          if (value != null) {
                            liftToShow.setProperty(key, value);
                          }
                        });
                        //liftToShow.note = liftNotification.; //No need in accepted? will put driver note instead
                        liftToShow.liftId = liftNotification.driveId;
                        //liftToShow.stops = [];
                        //else {
                        liftToShow.dist = liftNotification.distance;
                        //}
                        liftToShow.passengersInfo =
                        Map<String, Map<String, dynamic>>.from(
                            drive.data()["PassengersInfo"] ?? {});
                        liftToShow.payments = (await firestore.collection(
                            "Profiles").doc(liftNotification.driverId).get())
                            .data()["allowedPayments"].join(", ");
                        Navigator.of(context).push(new MaterialPageRoute<Null>(
                            builder: (BuildContext context) {
                              return NotificationInfo(
                                  lift: liftToShow,
                                  notification: liftNotification,
                                  type: NotificationInfoType.Accepted);
                            },
                            fullscreenDialog: true
                        ));
                      },
                        /*Navigator.of(context).push(new MaterialPageRoute<Null>(
                            builder: (BuildContext context) {
                              return LiftInfoPage(lift: lift, resLift: liftRes(
                                fromTime: widget.fromTime,
                                toTime: widget.toTime,
                                indexDist: 2,
                                startAddress: widget.startAddress,
                                destAddress: widget.destAddress,
                                bigTrunk: widget.bigTrunk,
                                backSeat: widget.backSeat,));
                            },
                            fullscreenDialog: true
                        )*/
                    ),
                  ),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.002),
                ],
              ),
            );
          }else {
            return Container();
            // return Center(
            //   child: CircularProgressIndicator(),
            // );
          }
        });
  }

  Widget _buildCanceledTile(LiftNotification liftNotification) {
    return FutureBuilder<List<String>>(
      //case "CanceledLift" : in case a hitchhiker canceled a lift - notify driver
      //case "CanceledDrive" : in case a driver canceled a drive- notify hitchhikers
        future: initNames(liftNotification.type == "CanceledLift" ? liftNotification.passengerId : liftNotification.driverId),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
            return Container(
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
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2.0,
                    spreadRadius: 0.0, offset: Offset(2.0, 2.0))
                ],
                border: Border.all(color: secondColor, width: 0.65),
                borderRadius: BorderRadius.circular(12.0),),
              child:
              Row(
                children: [
                  //flexs: 6,17,8
                  Flexible(flex: 3,
                    child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                              MaterialPageRoute<liftRes>(
                                  builder: (BuildContext context) {
                                    return ProfilePage(
                                      email: liftNotification.type == "CanceledLift" ? liftNotification.passengerId : liftNotification.driverId, fromProfile: false,);
                                  },
                                  fullscreenDialog: true
                              ));
                          setState(() {

                          });
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
                                  image: NetworkImage(snapshot.data[0])),

                            ))),
                  ),
                  Flexible(flex: 8,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            liftNotification.type == "CanceledLift" ? infoText(snapshot.data[1]) : infoTextHitchhiker(snapshot.data[1]),
                            placesText(liftNotification.startCity, liftNotification.destCity),
                            allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                          ],
                        )),
                  ),
                  //Spacer(),
                  Flexible(flex: 3,
                    child: InkWell(
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.016*16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel_outlined, size: 30, color: Colors.red),
                            Text("Canceled", style: TextStyle(fontSize: 15, color: Colors.red),
                            )
                          ],
                        ),
                      ),
                      onTap: () {

                      },
                    ),
                  ),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.002),
                ],
              ),
            );
          }else {
            return Container();
            // return Center(
            //   child: CircularProgressIndicator(),
            // );
          }
        });
  }


  Widget _buildRejectedTile(LiftNotification liftNotification) {
    return FutureBuilder<List<String>>(
        future: initNames(liftNotification.driverId),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
            return Container(
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
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2.0,
                    spreadRadius: 0.0, offset: Offset(2.0, 2.0))
                ],
                border: Border.all(color: secondColor, width: 0.65),
                borderRadius: BorderRadius.circular(12.0),),
              child:
              Row(
                children: [
                  Flexible( flex: 3,
                    child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                              MaterialPageRoute<liftRes>(
                                  builder: (BuildContext context) {
                                    return ProfilePage(
                                      email: liftNotification.driverId, fromProfile: false,);
                                  },
                                  fullscreenDialog: true
                              ));
                          setState(() {

                          });
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
                                  image: NetworkImage(snapshot.data[0])),

                            ))),
                  ),
                  Flexible( flex: 8,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            infoText(snapshot.data[1]),
                            placesText(liftNotification.startCity, liftNotification.destCity),
                            allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                          ],
                        )),
                  ),
                  Flexible( flex: 3,
                    child: InkWell(
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.016*16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Transform.rotate(angle: 0.8,
                                child: Icon(Icons.thumb_up_rounded, size: 30, color: Colors.red)),
                            Text("Rejected", style: TextStyle(fontSize: 15, color: Colors.red),
                            )
                          ],
                        ),
                      ),
                      onTap: () {

                      },
                    ),
                  ),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.003),
                ],
              ),
            );
          }else {
            return Container();
            // return Center(
            //   child: CircularProgressIndicator(),
            // );
          }
        });
  }

  Widget _buildRequestedTile(LiftNotification liftNotification) {
    return FutureBuilder<List<String>>(
        future: initNames(liftNotification.passengerId),
        //future: initNames("ofir.asulin@campus.technion.ac.il"),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
            return Container(
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
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2.0,
                    spreadRadius: 0.0, offset: Offset(2.0, 2.0))
                ],
                border: Border.all(color: secondColor, width: 0.65),
                borderRadius: BorderRadius.circular(12.0),),
              child:
              Row(
                children: [
                  Flexible( flex: 3,
                    child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                              MaterialPageRoute<liftRes>(
                                  builder: (BuildContext context) {
                                    return ProfilePage(
                                      email: liftNotification.passengerId, fromProfile: false,);
                                  },
                                  fullscreenDialog: true
                              ));
                          setState(() {

                          });
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
                                  image: NetworkImage(snapshot.data[0])),

                            ))),
                  ),
                  Flexible( flex: 9,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            infoTextHitchhiker(snapshot.data[1]),
                            placesText(liftNotification.startCity, liftNotification.destCity),
                            allInfoText(liftNotification.liftTime, liftNotification.distance ~/ 1000),
                          ],
                        )),
                  ),
                  Flexible( flex: 3,
                    child: InkWell(
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.016*16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.more_horiz, size: 30, color: Colors.orange),
                            /*Transform.rotate(angle: 0.8,
                                child: Icon(Icons.thumb_up_rounded, size: 30, color: Colors.orange)),*/
                            Text("Respond", style: TextStyle(fontSize: 15, color: Colors.orange),
                            )
                          ],
                        ),
                      ),
                      /*onTap: () {
                        Navigator.of(context).push(new MaterialPageRoute<Null>(
                            builder: (BuildContext context) {
                              return LiftInfoPage(lift: lift, resLift: liftRes(
                                fromTime: widget.fromTime,
                                toTime: widget.toTime,
                                indexDist: 2,
                                startAddress: widget.startAddress,
                                destAddress: widget.destAddress,
                                bigTrunk: widget.bigTrunk,
                                backSeat: widget.backSeat,));
                            },
                            fullscreenDialog: true
                        )
                      },*/

                      //RequestedInfoPage
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

                          Navigator.of(context).push(new MaterialPageRoute<Null>(
                              builder: (BuildContext context) {
                                return NotificationInfo(
                                    lift: liftToShow, notification: liftNotification, type: NotificationInfoType.Requested);
                              },
                              fullscreenDialog: true
                          ));
                        },
                    ),
                  ),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.02),
                ],
              ),
            );
          }else {
            return Container();
            // return Center(
            //   child: CircularProgressIndicator(),
            // );
          }
        });
  }

  Widget allInfoText(DateTime time,int dist){
    return Container(
        child:Row(
          children: [
            Icon(Icons.timer),
            Text(DateFormat('dd/MM kk:mm').format(time), style: TextStyle(fontSize: 13.5)),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
            SizedBox(width: MediaQuery.of(context).size.width * 0.005),
            Text(dist.toStringAsFixed(1)+"km", style: TextStyle(fontSize: 13.5)),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            //Icon(Icons.person),
            //Text(taken.toString()+"/"+avaliable.toString()),
            //SizedBox(width: MediaQuery.of(context).size.height * 0.01),
            // Container(child:Image.asset("assets/images/shekel.png",scale: 0.9)),
            // SizedBox(width: MediaQuery.of(context).size.height * 0.003),
            // Text(price.toString()),
          ],
        ));
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


//import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart';

/*void main() {
  runApp(MyApp());
}

// MyApp is a StatefulWidget. This allows updating the state of the
// widget when an item is removed.
class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  MyAppState createState() {
    return MyAppState();
  }
}*/

/*class MyAppState extends State<MyApp> {
  final items = List<String>.generate(20, (i) => "Item ${i + 1}");

  @override
  Widget build(BuildContext context) {
    final title = 'Dismissing Items';

    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Dismissible(
              // Each Dismissible must contain a Key. Keys allow Flutter to
              // uniquely identify widgets.
              key: Key(item),
              // Provide a function that tells the app
              // what to do after an item has been swiped away.
              onDismissed: (direction) {
                // Remove the item from the data source.
                setState(() {
                  items.removeAt(index);
                });

                // Then show a snackbar.
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("$item dismissed")));
              },
              // Show a red background as the item is swiped away.
              background: Container(color: Colors.red),
              child: ListTile(title: Text('$item')),
            );
          },
        ),
      ),
    );
  }
}*/