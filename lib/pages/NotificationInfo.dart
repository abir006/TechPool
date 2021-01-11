import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tech_pool/Utils.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';

import 'ChatPage.dart';
import 'ProfilePage.dart';

class NotificationInfo extends StatefulWidget {
  final MyLift lift;
  final LiftNotification notification;
  final NotificationInfoType type;
  NotificationInfo({Key key, @required this.lift,@required this.notification,@required this.type}) : super(key: key);
  @override
  _NotificationInfoState createState() => _NotificationInfoState();
}

class _NotificationInfoState extends State<NotificationInfo> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _errorSnack = GlobalKey<ScaffoldState>();
  bool checkButtons = true;
  @override
  void initState() {
    super.initState();
  }

  //Rejecting a request for a lift
  Future<bool> _rejectRequest(UserRepository userRep) async {
    try{
      return await firestore.runTransaction((transaction) async {
        //firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").doc(widget.notification.notificationId).delete();
        //transaction.set(firestore.collection("Notifications").doc("testing@campus.technion.ac.il").collection("UserNotifications2").doc(),

        //Inserting a rejected notification to the passenger
        transaction.set(firestore.collection("Notifications").doc(widget.notification.passengerId).collection("UserNotifications").doc(),
            {
              "startCity": widget.notification.startCity,
              "destCity": widget.notification.destCity,
              "distance": widget.notification.distance,
              "driveId": widget.notification.driveId,
              "driverId": widget.notification.driverId,
              "liftTime": widget.notification.liftTime,
              "notificationTime": DateTime.now(),
              "price": widget.notification.price,
              "type": "RejectedLift",
              "read": "false"
              //"destAddress": widget.lift.destAddress,
              //"startAddress": widget.lift.startAddress,
              //"passengerId": userRep.user.email,
            }
        );

        //Deleting the relevant pending of the passenger
        QuerySnapshot q = await firestore.collection("Notifications").
        doc(widget.notification.passengerId).collection("Pending").
        where("driveId",isEqualTo: widget.lift.liftId).get();
        q.docs.forEach((element) {
          transaction.delete(element.reference);
        });

        //Deleting the request notification from the driver notifications
        transaction.delete(firestore.collection("Notifications").
        doc(userRep.user?.email).collection("UserNotifications").
        doc(widget.notification.notificationId));
        return true;
      });
      //});
    }catch(e){
      return false;
    }
  }

  //Accepting a request for a lift
  Future<bool> _acceptRequest(UserRepository userRep) async {
    try{
      return await firestore.runTransaction((transaction) async {
        return transaction.get(firestore.collection("Drives")
            .doc(widget.notification.driveId))
            .then((value) async {
          List<String> tempPassengers = List.from(value.data()["Passengers"]);
          tempPassengers.add((widget.notification.passengerId));
          value.data()["Passengers"] = tempPassengers;
          Map<String,Map<String, dynamic>> tempPassengersInfo  = Map<String, Map<String, dynamic>>.from(value.data()["PassengersInfo"]);
          Map<String,Map<String, dynamic>> passengerInfoToAdd =
          { widget.notification.passengerId :
          {
            "bigBag": widget.notification.bigBag,
            "destAddress": widget.notification.destAddress,
            "startAddress": widget.notification.startAddress,
            "dist": widget.notification.distance,
            "note": widget.notification.passengerNote,
          }
          };
          tempPassengersInfo.addAll(passengerInfoToAdd);/*.remove(userRep.user.email);*/
          //Inserting the relevant passenger to the passengers in the drive
          transaction.update((firestore.collection("Drives").doc(widget.notification.driveId)),{"Passengers":tempPassengers,"PassengersInfo":tempPassengersInfo});

          //Inserting an accepted notification to the passenger
          transaction.set(firestore.collection("Notifications").doc(widget.notification.passengerId).collection("UserNotifications").doc(),
              //transaction.set(firestore.collection("Notifications").doc("testing").collection("UserNotifications").doc(),
              {
                "destAddress": widget.notification.destAddress,
                "startAddress": widget.notification.startAddress,
                "startCity": widget.notification.startCity,
                "destCity": widget.notification.destCity,
                "distance": widget.notification.distance,
                "driveId": widget.notification.driveId,
                "driverId": userRep.user.email,
                "liftTime": widget.notification.liftTime,
                "notificationTime": DateTime.now(),
                "price": widget.notification.price,
                "type": "AcceptedLift",
                "read": "false"
                //"passengerId": widget.notification.passengerId,
              }
          );
          //userRep.user?.email
          //"testing@campus.technion.ac.il"

          // transaction.delete(firestore.collection("Notifications").
          // doc(widget.notification.passengerId).collection("Pending").
          // where("driveId",isEqualTo: widget.notification.driveId).get());

          //Deleting the relevant pending of the passenger
          QuerySnapshot q = await firestore.collection("Notifications").
          doc(widget.notification.passengerId).collection("Pending").
          where("driveId",isEqualTo: widget.notification.driveId).get();
          q.docs.forEach((element) {
            transaction.delete(element.reference);
          });

          //Deleting the request notification from the driver notifications
          transaction.delete(firestore.collection("Notifications").
          doc(userRep.user?.email).collection("UserNotifications").
          doc(widget.notification.notificationId));

          return true;
        });
      });
      //});
    }catch(e){
      return  false;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<UserRepository>(builder: (context, userRep, child) {

      Widget infoText(String info) {
        return Container(
            width: MediaQuery.of(context).size.height * 0.016 * 20,
            child: Text(
              info,
              style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ));
      }

      Widget placesText(String from) {
        return Container(
            width: MediaQuery.of(context).size.height * 0.016 * 20,
            child: Text(
              from,
              style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ));
      }


      //Getting the passengers info from the database
      Future<List<dynamic>> initNames(String name) {
        List<dynamic> ret = [];
        return FirebaseStorage.instance
            .ref('uploads')
            .child(name)
            .getDownloadURL()
            .then((value) {
          ret.add(value);
          return firestore.collection("Profiles").doc(name).get().then((value) {
            ret.add(value.data()["firstName"] + " " + value.data()["lastName"]);
            if(widget.type == NotificationInfoType.Requested){
              ret.add(widget.lift.passengersInfo[name]["startAddress"]);//2
              ret.add(widget.lift.passengersInfo[name]["dist"]/ 1000);//3
              ret.add(widget.lift.passengersInfo[name]["bigBag"]);//4
              ret.add(widget.lift.passengersInfo[name]["note"]);//5
              ret.add(widget.lift.passengersInfo[name]["destAddress"]);//6
            }
            return ret;
          });
        });
        //  return null;
      }

      //Getting a passenger or driver picture and full name from the database
      Future<List<dynamic>> initName(String name) {
        List<dynamic> ret = [];
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
      }


      Widget _buildTile(MyLift lift, String type) {
        return FutureBuilder<List<dynamic>>(
            future: initName(type == "Accepted" ? widget.lift.driver : widget.notification.passengerId),
            builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.hasData) {
                return Container(
                  child: Row(
                    children: [
                      Flexible( flex: 3,
                        child: InkWell(
                            onTap: () async {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute<liftRes>(
                                  builder: (BuildContext context) {
                                    return ProfilePage(
                                      email: type == "Accepted" ? widget.lift.driver : widget.notification.passengerId,
                                      fromProfile: false,
                                    );
                                  },
                                  fullscreenDialog: true));
                              setState(() {});
                            },
                            child: Container(
                                margin: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height * 0.016,
                                    top: MediaQuery.of(context).size.height * 0.016),
                                width: MediaQuery.of(context).size.height * 0.016 * 4,
                                height:
                                MediaQuery.of(context).size.height * 0.016 * 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondColor,
                                  //Colors.teal,
                                  image: DecorationImage(
                                      fit: BoxFit.fill,
                                      image: NetworkImage(snapshot.data[0])),
                                ))),
                      ),
                      Flexible( flex: 4,
                        child: Container(
                            margin: EdgeInsets.only(
                                left: MediaQuery.of(context).size.height * 0.016,
                                top: MediaQuery.of(context).size.height * 0.016),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                infoText(snapshot.data[1]),
                                //placesText(lift.startAddress),
                                //allInfoText(widget.type == NotificationInfoType.Requested ? widget.lift.dist / 1000 : lift.passengersInfo[userRep.user.email]["dist"] / 1000),
                              ],
                            )),
                      ),
                      Spacer(),
                      SizedBox(
                        width: MediaQuery.of(context).size.height * 0.016,
                      )
                    ],
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            });
      }

      Widget _buildPassengerTile(String name) {
        return FutureBuilder<List<dynamic>>(
            future: initNames(name), // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.hasData) {
                return Container(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible( flex: 3,
                            child: InkWell(
                                onTap: () async {
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute<liftRes>(
                                      builder: (BuildContext context) {
                                        return ProfilePage(
                                          email: name,
                                          fromProfile: false,
                                        );
                                      },
                                      fullscreenDialog: true));
                                  setState(() {});
                                },
                                child: Container(
                                    margin: EdgeInsets.only(
                                        left: MediaQuery.of(context).size.height * 0.016,
                                        top: MediaQuery.of(context).size.height * 0.016),
                                    width: MediaQuery.of(context).size.height * 0.016 * 4,
                                    height:
                                    MediaQuery.of(context).size.height * 0.016 * 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: secondColor,
                                      image: DecorationImage(
                                          fit: BoxFit.fill,
                                          image: NetworkImage(snapshot.data[0])),
                                    ))),
                          ),
                          Flexible( flex: 3,
                            child: Container(
                                margin: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height * 0.016,
                                    top: MediaQuery.of(context).size.height * 0.016),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    infoText(snapshot.data[1]),
                                    /*...(widget.type == NotificationInfoType.Accepted ? ([placesText(snapshot.data[2]),
                                      allInfoText(snapshot.data[3])]) : [])*/
                                  ],
                                )),
                          ),
                          Spacer(),
                          SizedBox(
                            width: MediaQuery.of(context).size.height * 0.016,
                          )
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.004,
                      ),
                      ...(widget.type == NotificationInfoType.Requested ? ([Row(children: [
                      ]),Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                        labelText(text: "Pick Up: "),
                        Expanded(child: infoText(snapshot.data[2]))
                      ]), Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                        labelText(text: "Drop Off: "),
                        Expanded(child: infoText(snapshot.data[6]))
                      ]),widget.type == NotificationInfoType.Requested ? Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                        labelText(text: "Note: "), Expanded(child: infoText(snapshot.data[5]))
                      ]) : Container(),     Row(children: [labelText(text: "Big Bag: "),
                        snapshot.data[4]
                            ? Icon(Icons.check_circle_outline, color: secondColor)
                            : Icon(Icons.cancel_outlined, color: Colors.pink)]),Divider(thickness: 1)]) : [])],
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            });
      }

      var sizeFrameWidth = MediaQuery.of(context).size.width;
      double defaultSpace = MediaQuery.of(context).size.height * 0.013;
      double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
      List<Widget> _buildStopRowList() {
        List<Widget> stops = [];
        int i = 1;

        //building the stops map of text labels
        widget.lift.stops.forEach((key) {
          (key as Map).forEach((key, value) {
            if(key=="stopAddress")
              stops.add(Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labelText(text: "Stop-" + i.toString() + " "),
                  Expanded(child: infoText(value.toString()))
                ],
              ));
          });
          stops.add(SizedBox(height: defaultSpace));
          i++;
        });
        return stops;
      }

      List<Widget> _buildPassengersList() {
        List<Widget> passengers = [];
        for (int i = 0; i < widget.lift.passengers.length; i++) {
          passengers.add(_buildPassengerTile(widget.lift.passengers[i]));
        }
        return passengers;
      }

      Widget _buildStopRows(BuildContext context) {
        return Container(
          child: Column(
            children: _buildStopRowList(),
          ),
        );
      }


      final passengers = Container(
          alignment: Alignment.bottomLeft,
          color: Colors.white,
          //building the passengers info ConfigurableExpansionTile
          child: ConfigurableExpansionTile(
            header: Container(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Icon(Icons.person),
                    Text("Passengers "+widget.lift.passengersInfo.length.toString()+"/"+widget.lift.numberOfSeats.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  ],
                )),
            animatedWidgetFollowingHeader: const Icon(
              Icons.expand_more,
              color: const Color(0xFF707070),
            ),
            children: [
              ..._buildPassengersList(),
            ],
          ));

      //accept and reject buttons
      final AcceptOrReject =

      Consumer<UserRepository>(builder: (context, userRep, child) {
       return StreamBuilder<DocumentSnapshot>(
           stream:firestore
               .collection("Notifications")
               .doc(userRep.user.email).collection("UserNotifications").doc(widget.notification.notificationId).snapshots(), // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
    if(snapshot.hasData && snapshot.data.exists) {
      return Container(
          padding: EdgeInsets.only(
              left: sizeFrameWidth * 0.14,
              right: sizeFrameWidth * 0.12,
              bottom: defaultSpace * 2),
          height: defaultSpace * 6,
          child: Row(
            children: [
              Flexible(flex: 4,
                child: RaisedButton.icon(
                    color: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.black)),
                    icon: Icon(Icons.check, color: Colors.white,),
                    label: Text("Accept",
                        style: TextStyle(color: Colors.white, fontSize: 17)),
                    onPressed: () async {
                      if (widget.lift.passengersInfo.length ==
                          widget.lift.numberOfSeats) {
                        //_errorSnack.currentState.showSnackBar(SnackBar(content: Text("This drive is already full. Please press on Reject", style: TextStyle(fontSize: 19,color: Colors.red),)));
                        showErrorDialog(context, "No space left",
                            "This drive is already full.\nPlease press on Reject.",
                            userRep);
                      } else {
                        bool returnValue = await _acceptRequest(userRep);
                        if (returnValue == true) {
                          Navigator.pop(context);
                        }
                      }
                      /*if(widget.type == NotificationInfoType.Accepted){
                          showAlertDialog(context, "Cancel Lift", "Are you sure you want to cancel?\nThere is no going back", userRep);
                        }*/
                      // _errorSnack.currentState.showSnackBar(SnackBar(content: Text("The lift couldn't be deleted, it could have been canceled", style: TextStyle(fontSize: 19,color: Colors.red),)));
                      //await  cancelRequest(userRep);
                    }),
              ),
              SizedBox(width: 1.5 * defaultSpacewidth),
              Flexible(flex: 4,
                child: RaisedButton.icon(
                    color: Colors.red[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.black)),
                    icon: Icon(Icons.close, color: Colors.white,),
                    label: Text("Reject",
                        style: TextStyle(color: Colors.white, fontSize: 17)),
                    onPressed: () async {
                      bool returnValue = await _rejectRequest(userRep);
                      if (returnValue == true) {
                        Navigator.pop(context);
                      }
                    }),
              )
            ],
          ));
    }else{
      return Container();
    }
     });
    });

      final allInfo =
          StreamBuilder<List<DocumentSnapshot>>(
          stream: CombineLatestStream([firestore.collection("Drives").doc(widget.lift.liftId).snapshots(),
          firestore
          .collection("Notifications")
          .doc(userRep.user.email).collection("UserNotifications").doc(widget.notification.notificationId).snapshots()],(vals) => [vals[0],vals[1]]),  // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot){
            if(snapshot.hasData) {
              if (snapshot.data[0].exists && snapshot.data[1].exists) {
                snapshot.data[0].data().forEach((key, value) {
                  if (value != null) {
                    widget.lift.setProperty(key, value);
                  }
                });
                widget.lift.passengersInfo =
                Map<String, Map<String, dynamic>>.from(
                    snapshot.data[0].data()["PassengersInfo"]);
                return Container(
                    child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.only(
                            left: defaultSpacewidth, right: defaultSpacewidth),
                        children: [
                          SizedBox(height: defaultSpace),
                          /*Text("${widget.type == NotificationInfoType.Accepted ? "Lift" : "Drive"} Info",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),*/
                          /*Divider(
                  thickness: 3,
                ),*/
                          ...(widget.type == NotificationInfoType.Accepted ? ([
                            Text(
                                "Driver:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            _buildTile(widget.lift, "Accepted"),
                            /*Divider(
                    thickness: 3,
                  )*/
                          ]) : []),

                          ...(widget.type == NotificationInfoType.Requested ? ([
                            Text("Passenger:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            _buildTile(widget.lift, "Requested"),
                            /*Divider(
                    thickness: 3,
                  )*/
                          ]) : []),

                          SizedBox(height: 1.5 * defaultSpace),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              labelText(text: "Date and time: "),
                              Expanded(
                                  child: infoText(
                                      DateFormat('dd/MM - kk:mm').format(
                                          widget.lift.time)))
                            ],
                          ),
                          SizedBox(height: defaultSpace),
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                labelText(text: "Pick Up Point: "),
                                Expanded(child: infoText(
                                    widget.type ==
                                        NotificationInfoType.Requested
                                        ? widget.notification.startAddress
                                        : widget.lift.passengersInfo[userRep
                                        .user
                                        .email]["startAddress"]))
                              ]),
                          SizedBox(height: defaultSpace),
                          /*Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: infoText(widget.type == NotificationInfoType.Requested ? widget.notification.startAddress : widget.lift.passengersInfo[userRep.user.email]["startAddress"]))
                ]),*/

                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                labelText(text: "${widget.type ==
                                    NotificationInfoType.Requested
                                    ? "Drop Off"
                                    : "Drop Off"} Point: "),
                                Expanded(child: infoText(
                                    widget.type ==
                                        NotificationInfoType.Requested
                                        ? widget.notification.destAddress
                                        : widget.lift.passengersInfo[userRep
                                        .user
                                        .email]["destAddress"]))
                              ]),
                          SizedBox(height: defaultSpace),
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                labelText(text: "Starting Point: "),
                                Expanded(
                                    child: infoText(widget.lift.startAddress))
                              ]),
                          SizedBox(height: defaultSpace),
                          _buildStopRows(context),
                          //SizedBox(height: defaultSpace),
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                labelText(text: "Destination: "),
                                Expanded(
                                    child: infoText(widget.lift.destAddress))
                              ]),

                          /*SizedBox(height: defaultSpace/3),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: infoText(widget.type == NotificationInfoType.Requested ? widget.notification.destAddress : widget.lift.passengersInfo[userRep.user.email]["destAddress"]))
                ]),*/

                          SizedBox(height: defaultSpace),
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                labelText(text: "Distance: "),
                                Expanded(child: infoText(
                                    (widget.notification.distance / 1000)
                                        .toStringAsFixed(1) + "km"))
                              ]),

                          widget.type == NotificationInfoType.Accepted
                              ? SizedBox(
                              height: defaultSpace)
                              : Container(),
                          widget.type == NotificationInfoType.Accepted ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                labelText(text: "Price: "),
                                Image.asset(
                                    "assets/images/shekel.png", scale: 0.9),
                                Expanded(child: infoText(
                                    " " + widget.lift.price.toString()))
                              ]) : Container(),

                          Divider(
                            thickness: 3,
                          ),
                          Container(
                              alignment: Alignment.bottomLeft,
                              color: Colors.white,
                              child: ConfigurableExpansionTile(
                                header: Container(
                                    alignment: Alignment.bottomLeft,
                                    child: Text("Additional info",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17))),
                                animatedWidgetFollowingHeader: const Icon(
                                  Icons.expand_more,
                                  color: const Color(0xFF707070),
                                ),
                                //tilePadding: EdgeInsets.symmetric(horizontal: 0),
                                // backgroundColor: Colors.white,
                                // trailing: Icon(Icons.arrow_drop_down,color: Colors.black,),
                                //title: Text("Passenger info"),
                                children: [
                                  Row(children: [
                                    labelText(text: "Big Trunk: "),
                                    widget.lift.bigTrunk
                                        ? Icon(Icons.check_circle_outline,
                                        color: Colors.teal)
                                        : Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.pink),
                                  ]),
                                  SizedBox(height: defaultSpace),
                                  widget.type == NotificationInfoType.Requested
                                      ? Row(children: [
                                    labelText(text: "Big Bag: "),
                                    widget.notification.bigBag
                                        ? Icon(Icons.check_circle_outline,
                                        color: Colors.teal)
                                        : Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.pink)
                                  ])
                                      : Container(),
                                  widget.type == NotificationInfoType.Accepted
                                      ? Row(children: [
                                    labelText(text: "Big Bag: "),
                                    widget.lift.passengersInfo[userRep.user
                                        .email]["bigBag"]
                                        ? Icon(Icons.check_circle_outline,
                                        color: Colors.teal)
                                        : Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.pink)
                                  ])
                                      : Container(),
                                  //Backseat,
                                  widget.type == NotificationInfoType.Accepted
                                      ? SizedBox(height: defaultSpace)
                                      : Container(),
                                  widget.type == NotificationInfoType.Accepted
                                      ? Row(children: [
                                    labelText(text: "Backseat not full?: "),
                                    widget.lift.backSeat
                                        ? Icon(Icons.check_circle_outline,
                                        color: Colors.teal)
                                        : Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.pink)
                                  ])
                                      : Container(),
                                  widget.lift.note != "" ? SizedBox(
                                      height: defaultSpace) : Container(),
                                  widget.lift.note != "" ? Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        labelText(text: "Driver note: "),
                                        Expanded(
                                            child: infoText(widget.lift.note))
                                      ]) : Container(),
                                  ...(widget.type == NotificationInfoType.Requested
                                      ?
                                  [widget.notification.passengerNote != "" ? SizedBox(
                                      height: defaultSpace) : Container(),
                                  widget.notification.passengerNote != "" ? Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        labelText(text: "Passenger note: "),
                                        Expanded(
                                            child: infoText(widget.notification.passengerNote))
                                      ]) : Container()]: [Container()]) ,

                                  /*SizedBox(height: defaultSpace/3),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: infoText(widget.lift.note))
                          ]),*/
                                  ...(widget.type ==
                                      NotificationInfoType.Accepted
                                      ? ([
                                    widget.lift.passengersInfo[userRep.user
                                        .email]["note"] != "" ? SizedBox(
                                        height: defaultSpace) : Container(),
                                    widget.lift.passengersInfo[userRep.user
                                        .email]["note"] != "" ? Row(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start, children: [
                                      labelText(text: "${widget.type ==
                                          NotificationInfoType.Requested
                                          ? "Passenger"
                                          : "My"} note: "),
                                      Expanded(child: infoText(
                                          widget.lift.passengersInfo[userRep
                                              .user
                                              .email]["note"]))
                                    ]) : Container()
                                  ])
                                      : []),
                                  widget.type == NotificationInfoType.Accepted
                                      ? SizedBox(height: defaultSpace)
                                      : Container(),
                                  widget.type == NotificationInfoType.Accepted
                                      ? Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        labelText(
                                            text: "Driver Payment methods: "),
                                        Expanded(
                                            child: infoText(
                                                widget.lift.payments))
                                      ])
                                      : Container(),
                                  SizedBox(height: defaultSpace),
                                ],
                              )
                          ),
                          Divider(
                            thickness: 3,
                          ),
                          Container(
                              alignment: Alignment.bottomLeft,
                              color: Colors.white,
                              child: ConfigurableExpansionTile(
                                header: Container(
                                    alignment: Alignment.bottomLeft,
                                    child: Row(
                                      children: [
                                        Icon(Icons.person),
                                        Text("Passengers " +
                                            widget.lift.passengersInfo.length
                                                .toString() + "/" +
                                            widget.lift.numberOfSeats
                                                .toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17)),
                                      ],
                                    )),
                                animatedWidgetFollowingHeader: const Icon(
                                  Icons.expand_more,
                                  color: const Color(0xFF707070),
                                ),
                                //tilePadding: EdgeInsets.symmetric(horizontal: 0),
                                // backgroundColor: Colors.white,
                                // trailing: Icon(Icons.arrow_drop_down,color: Colors.black,),
                                //title: Text("Passenger info"),
                                children: [
                                  ..._buildPassengersList(),
                                ],
                              )),
                          Divider(
                            thickness: 3,
                          ),
                          SizedBox(height: defaultSpace),
                          Container(
                          ),
                        ]));
              }
          else {
              checkButtons = false;
            return Center(child: Text(
              "Notification unavailable", style: TextStyle(fontSize: 30),),);
          }
          }
          else{
            if(snapshot.hasError){
              return Center(child: Text("Notification unavailable", style: TextStyle(fontSize: 30),),);
            }else{
              return Center(child: CircularProgressIndicator(),);
            }
          }
          });

      return Scaffold(
        key: _errorSnack,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "${widget.type == NotificationInfoType.Accepted ? "Accepted Drive" : "Requested Lift"} Info",
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
                        builder: (context) => ChatPage(currentUserId: userRep.user.email)));}
          )
          ],
        ),
        body: Container(
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
            child: Column(
              children: [Expanded(child: allInfo),widget.type == NotificationInfoType.Requested && checkButtons ? AcceptOrReject : Container()],
            )),
        backgroundColor: mainColor,
      );
    });
  }

  showAlertDialog(BuildContext context,String title,String info,UserRepository usrRep) {
    Widget okButton = FlatButton(
      textColor: mainColor,
      child: Text("Yes"),
      onPressed: () async {
        //bool retval =await _cancelRequest(usrRep);
        //Navigator.pop(context);
        //Navigator.pop(context);
        //bool retval =await _cancelRequest(usrRep);
        //Navigator.pop(context);
        //Navigator.pop(context);

      },
    );

    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      textColor: mainColor,
      onPressed:  () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(info,style:TextStyle(fontSize: 17)),
      actions: [
        cancelButton,
        okButton,
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

  showErrorDialog(BuildContext context,String title,String info,UserRepository usrRep) {

    Widget okButton = FlatButton(
        textColor: mainColor,
        child: Text("OK"),
        onPressed: () {
          Navigator.pop(context);
        }
    );

    // Widget cancelButton = FlatButton(
    //   child: Text("Cancel"),
    //   textColor: mainColor,
    //   onPressed:  () {
    //     Navigator.pop(context);
    //   },
    // );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(info,style:TextStyle(fontSize: 17)),
      actions: [
        //cancelButton,
        okButton,
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

  void dispose() {
    super.dispose();
  }

}
