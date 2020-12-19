import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'ProfilePage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDay = DateTime.now();
  List _notifications;

  Widget infoText(String info) {
    return  Container(
        width: MediaQuery.of(context).size.height * 0.016*20,
        child: Text("Driver: " + info,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }

  @override
  void initState() {
    super.initState();
    _notifications = [];
  }

  @override
  Widget build(BuildContext context) {
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;

    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<List<QuerySnapshot>>(
          stream: CombineLatestStream([
          firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").snapshots()],
                  (values) => [values[0]]),
          builder: (context, snapshot) {
            _notifications = [];
            if (snapshot.hasData) {
              snapshot.data[0].docs.forEach((element) {
                var elementData = element.data();
                String type = elementData["type"];
                String driveId = elementData["driveId"];
                String driverFullName = elementData["driverFullName"];
                String driverId = elementData["driverId"];//email
                String startCity = elementData["startCity"];
                String destCity = elementData["destCity"];
                int price = elementData["price"];
                int distance = elementData["distance"];
                DateTime liftTime = elementData["liftTime"].toDate();
                DateTime notificationTime = elementData["notificationTime"].toDate();
                var notification;
                switch(type) {
                  case "AcceptedLift" : {
                    notification = AcceptedLiftNotification(driveId, driverId,
                        driverFullName, startCity, destCity, price, distance,
                        liftTime, notificationTime);
                    /*send type?*/
                  }
                  break;

                  /*case "RejectedLift" : {
                    notification = RejectedLiftNotification();
                  }
                  break;

                  //default: {
                  case "RequestedLift" : {
                    notification = RequestedLiftNotification();
                  }
                  break;*/
                }
                _notifications.add(notification);
              });
              _notifications.sort((a, b) {
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
        drawer: techDrawer(userRep, context, DrawerSections.home),
      body:Container(
          decoration: pageContainerDecoration,
          margin: pageContainerMargin,
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          child: Column(
            children: [Expanded(child:ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.only(left: defaultSpacewidth*0.4, right: defaultSpacewidth*0.4, bottom: defaultSpacewidth*0.4,top:defaultSpacewidth*0.4 ),
              itemCount: _notifications.length,
              separatorBuilder: (BuildContext context, int index) => Divider(thickness: 4,),
              itemBuilder: (BuildContext context, int index) {
                return _buildTile(_notifications[index]);
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

  Widget notificationSwitcher(dynamic notification,BuildContext context){
    if (notification is AcceptedLiftNotification) {
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

  @override
  void dispose() {
    super.dispose();
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

  Widget _buildTile(AcceptedLiftNotification acceptedLiftNotification) {
    return FutureBuilder<List<String>>(
        future: initNames(acceptedLiftNotification.driverId),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2.0,
                    spreadRadius: 0.0, offset: Offset(2.0, 2.0))
                ],
                border: Border.all(color: secondColor, width: 0.8),
                borderRadius: BorderRadius.circular(12.0),),
              child:
              Row(
                children: [
                  InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                            MaterialPageRoute<liftRes>(
                                builder: (BuildContext context) {
                                  return ProfilePage(
                                    email: acceptedLiftNotification.driverId, fromProfile: false,);
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
                            color: Colors.teal,
                            image: DecorationImage(//fit: BoxFit.fill,
                                image: NetworkImage(snapshot.data[0])),

                          ))),
                  Container(
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
                          placesText(acceptedLiftNotification.startCity, acceptedLiftNotification.destCity),
                          allInfoText(acceptedLiftNotification.liftTime, acceptedLiftNotification.distance ~/ 1000, acceptedLiftNotification.price),
                        ],
                      )),
                  //Spacer(),
                  InkWell(
                    child: Container(
                      width: MediaQuery
              .of(context)
              .size
              .width * 0.2,
                      margin: EdgeInsets.only(
                          right: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.rotate(angle: 0.8,
                              child: Icon(Icons.thumb_up_rounded, size: 30, color: Colors.green)),
                          Text("Acceptedddd", style: TextStyle(fontSize: 14, color: Colors.green),
                          )
                        ],
                      ),
                    ),
                    onTap: () {
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
                      ));*/
                    },
                  ),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .height * 0.016,)

                ],
              ),
            );
          }else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
  Widget allInfoText(DateTime time,int dist, int price){
    return Container(
        child:Row(
          children: [
            Icon(Icons.timer),
            Text(DateFormat('kk:mm').format(time)),
            SizedBox(width: MediaQuery.of(context).size.height * 0.01),
            Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
            SizedBox(width: MediaQuery.of(context).size.height * 0.005),
            Text(dist.toString()+"km"),
            SizedBox(width: MediaQuery.of(context).size.height * 0.01),
            //Icon(Icons.person),
            //Text(taken.toString()+"/"+avaliable.toString()),
            //SizedBox(width: MediaQuery.of(context).size.height * 0.01),
            Container(child:Image.asset("assets/images/shekel.png",scale: 0.9)),
            SizedBox(width: MediaQuery.of(context).size.height * 0.003),
            Text(price.toString()),
          ],
        ));
  }

  Widget placesText(String from, String to) {
    return  Container(
        width: MediaQuery.of(context).size.height * 0.016*20,
        child: Text(from + " \u{2192} " + to,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }
}
