import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';
import 'package:tech_pool/CalendarEvents.dart';
import 'package:tech_pool/main.dart';
import 'ProfilePage.dart';

class CalendarEventInfo extends StatefulWidget {
  final MyLift lift;
  final CalendarEventType type;
  CalendarEventInfo({Key key, @required this.lift,@required this.type}) : super(key: key);

  @override
  _CalendarEventInfoState createState() => _CalendarEventInfoState();
}

class _CalendarEventInfoState extends State<CalendarEventInfo> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool bigBag= false;
  final _errorSnack = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }
  Future<bool> _cancelRequest(UserRepository userRep) async {
    try{
      return await firestore.runTransaction((transaction) async {
        return transaction.get(firestore.collection("Drives")
            .doc(widget.lift.liftId))
            .then((value) async {
          List<String> tempPassengers = List.from(value.data()["Passengers"]);
          tempPassengers.remove((userRep.user.email));
          value.data()["Passengers"] = tempPassengers;
          Map<String,Map<String, dynamic>> tempPassengersInfo  = Map<String, Map<String, dynamic>>.from(value.data()["PassengersInfo"]);
          tempPassengersInfo.remove(userRep.user.email).remove(userRep.user.email);
          transaction.update((firestore.collection("Drives").doc(widget.lift.liftId)),{"Passengers":tempPassengers,"PassengersInfo":tempPassengersInfo});
          transaction.set(firestore.collection("Notifications").doc(widget.lift.driver).collection("UserNotifications").doc(),
              {
                "destCity": widget.lift.destCity,
                "destAddress": widget.lift.destAddress,
                "startCity": widget.lift.startCity,
                "startAddress": widget.lift.startAddress,
                "distance": (widget.lift.passengersInfo[userRep.user.email]["dist"]),
                "driveId": widget.lift.liftId,
                "driverId": widget.lift.driver,
                "liftTime": widget.lift.time,
                "notificationTime": DateTime.now(),
                "price": widget.lift.price,
                "passengerId": userRep.user.email,
                "type": "CanceledLift",
                "read": "false"
              }
          );
          return true;
        });
      });
    }catch(e){
      return false;
    }
  }

  Future<bool> _cancelPending(UserRepository userRep) async {
    try{
      return await firestore.runTransaction((transaction) async {
        return transaction.get(firestore.collection("Drives")
            .doc(widget.lift.liftId))
            .then((value) async {

          QuerySnapshot q2 = await firestore.collection("Notifications").
          doc(widget.lift.driver).collection("UserNotifications").
          where("driveId",isEqualTo: widget.lift.liftId).where("type",isEqualTo: "RequestedLift").get();

          q2.docs.forEach((element) {
            transaction.delete(element.reference);
          });

          QuerySnapshot q3 = await firestore.collection("Notifications").
          doc(userRep.user.email).collection("Pending").
          where("driveId",isEqualTo: widget.lift.liftId).get();
          q3.docs.forEach((element) {
            transaction.delete(element.reference);
          });

          return true;
        });
      });
    }catch(e){
      return false;
    }
  }


  Future<bool> _cancelDriveQueryAux(UserRepository userRep) async {
    try {
      //delete all requested notifications related to this canceled drive
      QuerySnapshot q2 = await firestore.collection("Notifications").
      doc(userRep.user?.email).collection("UserNotifications").
      where("driveId", isEqualTo: widget.lift.liftId).where(
          "type", isEqualTo: "RequestedLift").get();
      q2.docs.forEach((element) async {
        String currentHitchhikerRequesterId = element["passengerId"];
        firestore.collection("Notifications")
            .doc(currentHitchhikerRequesterId)
            .collection("UserNotifications")
            .add(
            {
              //Insert a rejected notification to all those that requested this lift
              "destCity": element["destCity"],
              "startCity": element["startCity"],
              "distance": element["distance"],
              "driveId": widget.lift.liftId,
              "driverId": widget.lift.driver,
              "liftTime": widget.lift.time,
              "notificationTime": DateTime.now(),
              "price": widget.lift.price,
              "type": "RejectedLift",
              "read": "false"
            }
        );
        element.reference.delete();

        //delete all pending notifications related to this canceled drive
        firestore.collection("Notifications").doc(currentHitchhikerRequesterId).collection("Pending")
            .where("driveId",isEqualTo: widget.lift.liftId).get().then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _cancelDrive(UserRepository userRep) async {
    try{
      return await firestore.runTransaction((transaction) async {

        return transaction.get(firestore.collection("Drives")
            .doc(widget.lift.liftId))
            .then((value) async {
           List<String> tempPassengers = List.from(value.data()["Passengers"]);
           tempPassengers.forEach((element) async {
            String currentPassengerId = element.toString();
            //Insert a canceled notification to all passengers that were supposed to participate in this drive
            transaction.set(firestore.collection("Notifications").doc(currentPassengerId).collection("UserNotifications").doc(),
                {
                  "destCity": widget.lift.destCity,
                  "destAddress": widget.lift.passengersInfo[currentPassengerId]["destAddress"],
                  "startCity": widget.lift.startCity,
                  "startAddress": widget.lift.passengersInfo[currentPassengerId]["startAddress"],
                  "distance": (widget.lift.passengersInfo[currentPassengerId]["dist"]),
                  "driveId": widget.lift.liftId,
                  "driverId": widget.lift.driver,
                  "liftTime": widget.lift.time,
                  "notificationTime": DateTime.now(),
                  "price": widget.lift.price,
                  "passengerId": currentPassengerId,
                  "type": "CanceledDrive",
                  "read": "false"
                }
            );
          });

           //delete drive from database
          transaction.delete(firestore.collection("Drives").doc(widget.lift.liftId));
          return true;
        });
      });
    }catch(e){
      return false;
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

      /// initializes a list with all the info required about a passenger by his name(email).
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
            if(widget.type == CalendarEventType.Drive){
              ret.add(widget.lift.passengersInfo[name]["startAddress"]);
              ret.add(widget.lift.passengersInfo[name]["dist"]/ 1000);
              ret.add(widget.lift.passengersInfo[name]["bigBag"]);
              //ret.add(widget.lift.passengersInfo[name]["backSeatNotFull"]);
              ret.add(widget.lift.passengersInfo[name]["note"]);
              ret.add(widget.lift.passengersInfo[name]["destAddress"]);
            }
            return ret;
          });
        });
        //  return null;
      }
      Widget allInfoText(double dist) {
        return Container(
            child: Row(
              children: [
                Row(children: [Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),Text(dist.toStringAsFixed(1) + "km")]),
                SizedBox(width: MediaQuery.of(context).size.height * 0.01),
              ],
            ));
      }

      Widget _buildTile(MyLift lift) {
        return FutureBuilder<List<dynamic>>(
            future: initNames(lift.driver),
            builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.hasData) {
                return Container(
                  child: Row(
                    children: [
                      InkWell(
                          onTap: () async {
                            await Navigator.of(context)
                                .push(MaterialPageRoute<liftRes>(
                                builder: (BuildContext context) {
                                  return ProfilePage(
                                    email: lift.driver,
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
              Expanded(child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery.of(context).size.height * 0.016,
                              top: MediaQuery.of(context).size.height * 0.016),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              infoText(snapshot.data[1]),
                              //placesText(lift.startAddress),
                              allInfoText(widget.type == CalendarEventType.PendingLift ? widget.lift.dist / 1000 : lift.passengersInfo[userRep.user.email]["dist"] / 1000),
                            ],
                          ))),
                    ],
                  ),
                );
              }else if (snapshot.hasError){
                return Center(child: Text("Error loading info", style: TextStyle(fontSize: 15),),);
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            });
      }

      Widget _buildPassengerTile(String name,bool isLastPassenger) {
        return FutureBuilder<List<dynamic>>(
            future: initNames(name), // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.hasData) {
                return Container(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          InkWell(
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
              Expanded(child: Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.height * 0.016,
                                  top: MediaQuery.of(context).size.height * 0.016),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  infoText(snapshot.data[1]),
                                  ...(widget.type == CalendarEventType.Drive ? ([
                                    allInfoText(snapshot.data[3])]) : [])
                                ],
                              ))),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.013),
                      ...(widget.type == CalendarEventType.Drive ? ([
                        Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                          labelText(text: "Pickup from: "),
                          Expanded(child:  infoText(snapshot.data[2]))
                        ]),
                        Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                          labelText(text: "Drop-off at: "),
                          Expanded(child: infoText(snapshot.data[6]))
                        ]),
                        Row(children: [
                          labelText(text: "Big Bag: "),
                          snapshot.data[4]
                              ? Icon(Icons.check_circle_outline, color: secondColor)
                              : Icon(Icons.cancel_outlined, color: Colors.pink)
                        ]),snapshot.data[5].isEmpty? SizedBox(height: 0,) : Row(children: [
                          labelText(text: "Note: "), Expanded(child: infoText(snapshot.data[5]))
                        ]),!isLastPassenger? Divider(thickness: 1) : SizedBox(height:0)]) : [])],
                  ),
                );
              }else if (snapshot.hasError){
                return Center(child: Text("Error loading passenger info", style: TextStyle(fontSize: 15),),);
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
      List<Widget> _buildRowList() {
        List<Widget> stops = [];
        int i = 1;
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
        int i = 0;
        if(widget.lift.passengers.length > 0) {
          for (; i < widget.lift.passengers.length - 1; i++) {
            passengers.add(
                _buildPassengerTile(widget.lift.passengers[i], false));
          }
          passengers.add(_buildPassengerTile(widget.lift.passengers[i], true));
        }
          return passengers;

      }

      Widget _buildRow(BuildContext context) {
        return Container(
          child: Column(
            // As you expect multiple lines you need a column not a row
            children: _buildRowList(),
          ),
        );
      }


      final searchLift =
      Consumer<UserRepository>(builder: (context, userRep, child) {
        return  widget.lift.time.isBefore(DateTime.now()) ?
        Container(
            padding: EdgeInsets.only(
                left: sizeFrameWidth * 0.2,
                right: sizeFrameWidth * 0.2,
                bottom: defaultSpace * 2),
            height: defaultSpace * 6,
            child: RaisedButton.icon(
                color: Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.black)),
                icon: Icon(Icons.delete, color: Colors.white,),
                label: Text("Cancel ${widget.type == CalendarEventType.Drive
                    ? "Drive"
                    : "Lift"}",
                    style: TextStyle(color: Colors.white, fontSize: 17)),
                onPressed:  () => showDialog(context: context,builder: (_) {
                  return AlertDialog(shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0))),
                    title: Text("The ${widget.type == CalendarEventType.Drive
                        ? "Drive"
                        : "Lift"} has past"),content: Text("You can't cancle a ${widget.type == CalendarEventType.Drive
                          ? "Drive"
                          : "Lift"} that has already passed"),actions: [
                      TextButton(onPressed: () =>
                      Navigator.pop(context),
                  child: Text("Dismiss"))]);})))
            : Container(
            padding: EdgeInsets.only(
                left: sizeFrameWidth * 0.2,
                right: sizeFrameWidth * 0.2,
                bottom: defaultSpace * 2),
            height: defaultSpace * 6,
            child: RaisedButton.icon(
                color: Colors.red[800],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.black)),
                icon: Icon(Icons.delete, color: Colors.white,),
                label: Text("Cancel ${widget.type == CalendarEventType.Drive
                    ? "Drive"
                    : "Lift"}",
                    style: TextStyle(color: Colors.white, fontSize: 17)),
                onPressed:  () async{
                  if(widget.type == CalendarEventType.Lift){
                    showAlertDialog(context, "Cancel Lift", "Are you sure you want to cancel?\nThere is no going back", userRep, "CanceledLift");
                  }
                  else if(widget.type == CalendarEventType.Drive){
                    showAlertDialog(context, "Cancel Drive", "Are you sure you want to cancel?\nThere is no going back", userRep, "CanceledDrive");
                  }else if(widget.type == CalendarEventType.PendingLift){
                    showAlertDialog(context, "Cancel Pending", "Are you sure you want to cancel?\nThere is no going back", userRep, "CanceledPending");
                  }

                  // _errorSnack.currentState.showSnackBar(SnackBar(content: Text("The lift couldn't be deleted, it could have been canceled", style: TextStyle(fontSize: 19,color: Colors.red),)));
                  //await  cancelRequest(userRep);
                }));
      });

      final allInfo = StreamBuilder<DocumentSnapshot>(
          stream:firestore.collection("Drives").doc(widget.lift.liftId).snapshots(), // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
            try {
              if (snapshot.hasData) {
                if (snapshot.data.exists) {
                  snapshot.data.data().forEach((key, value) {
                    if (value != null) {
                      widget.lift.setProperty(key, value);
                    }
                  });
                widget.lift.passengersInfo =
                Map<String, Map<String, dynamic>>.from(
                    snapshot.data.data()["PassengersInfo"] ?? {});
                  if(widget.type == CalendarEventType.PendingLift) {
                    if(widget.lift.passengersInfo.containsKey(userRep.user.email)){
                      return Center(child: Text("You have been accepted to this lift", style: TextStyle(fontSize: 15),),);
                    }
                  }
                return Container(
                    child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.only(
                            left: defaultSpacewidth, right: defaultSpacewidth),
                        children: [
                          SizedBox(height: defaultSpace),
                          ...(widget.type == CalendarEventType.Lift ||
                              widget.type == CalendarEventType.PendingLift ? ([
                            Text("Driver:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            _buildTile(widget.lift),
                            SizedBox(height: defaultSpace),
                          ]) : []),
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
                                labelText(text: "${(widget.type ==
                                    CalendarEventType.Drive)
                                    ? "Starting Point"
                                    : "Pickup from"}: "),
                                Expanded(child: infoText(
                                    widget.type == CalendarEventType.Drive
                                        ? widget.lift.startAddress
                                        : (
                                        (widget.type == CalendarEventType.Lift ?
                                        widget.lift.passengersInfo[userRep.user
                                            .email]["startAddress"] : widget
                                            .lift.pendingStartAddress))))
                              ]),
                          widget.type == CalendarEventType.Drive ? _buildRow(
                              context) : SizedBox(height: 0,),
                          widget.lift.stops.length == 0 ? SizedBox(height: defaultSpace,) : SizedBox(height: 0,),
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                labelText(text: (widget.type ==
                                    CalendarEventType.Drive)
                                    ? "Destination: "
                                    : "Drop-off at: "),
                                Expanded(child: infoText(
                                    widget.type == CalendarEventType.Drive
                                        ? widget.lift.destAddress
                                        : (
                                        (widget.type == CalendarEventType.Lift ?
                                        widget.lift.passengersInfo[userRep.user
                                            .email]["destAddress"] : widget.lift
                                            .pendingDestAddress))))
                              ]),
                          SizedBox(height: defaultSpace),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            labelText(text: "Price: "),
                            Image.asset("assets/images/shekel.png", scale: 0.9),
                            Expanded(
                                child: infoText(widget.lift.price.toString()))
                          ]),
                          SizedBox(height: defaultSpace),
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
                                  ...(widget.type == CalendarEventType.Drive ? [
                                  ] :
                                  [
                                    Row(crossAxisAlignment: CrossAxisAlignment
                                        .start, children: [
                                      labelText(text: "Starting Point: "),
                                      Expanded(child: infoText(
                                          widget.lift.startAddress))
                                    ]),
                                    SizedBox(height: defaultSpace),
                                    _buildRow(context),
                                    Row(crossAxisAlignment: CrossAxisAlignment
                                        .start, children: [
                                      labelText(text: "Destination: "),
                                      Expanded(child: infoText(
                                          widget.lift.destAddress))
                                    ])
                                  ]),
                                  SizedBox(height: defaultSpace),
                                  ...((widget.type == CalendarEventType.Lift || widget.type == CalendarEventType.PendingLift) ? [
                                  Row(children: [
                                    labelText(text: "Big Bag: "),
                                    widget.lift.bigBag
                                        ? Icon(Icons.check_circle_outline,
                                        color: secondColor)
                                        : Icon(Icons.cancel_outlined,
                                        color: Colors.pink)
                                  ]),SizedBox(height: defaultSpace,)] : [SizedBox()]),
                                  Row(children: [
                                    labelText(text: "Big Trunk: "),
                                    widget.lift.bigTrunk
                                        ? Icon(Icons.check_circle_outline,
                                        color: secondColor)
                                        : Icon(Icons.cancel_outlined,
                                        color: Colors.pink)
                                  ]),
                                  SizedBox(height: defaultSpace),
                                  Row(children: [
                                    labelText(text: "Backseat not full?: "),
                                    widget.lift.backSeat
                                        ? Icon(Icons.check_circle_outline,
                                        color: secondColor)
                                        : Icon(Icons.cancel_outlined,
                                        color: Colors.pink)
                                  ]),
                                  // _buildRow(context),
                                  widget.lift.note.isEmpty ? SizedBox(
                                    height: 0,) : SizedBox(
                                      height: defaultSpace),
                                  widget.lift.note.isEmpty ? SizedBox(
                                    height: 0,) : Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start, children: [
                                    labelText(text: "${widget.type ==
                                        CalendarEventType.Drive
                                        ? "My"
                                        : "Drivers"} note: "),
                                    Expanded(child: infoText(widget.lift.note)),
                                  ]),
                                  ...(widget.type == CalendarEventType.Lift ? ([
                                    widget.lift.passengersInfo[userRep.user
                                        .email]["note"].isEmpty ? SizedBox(
                                      height: 0,) : SizedBox(
                                        height: defaultSpace),
                                    widget.lift.passengersInfo[userRep.user
                                        .email]["note"].isEmpty ? SizedBox(
                                      height: 0,) : Row(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start, children: [
                                      labelText(text: "My note: "),
                                      Expanded(child: infoText(
                                          widget.lift.passengersInfo[userRep
                                              .user.email]["note"]))
                                    ])
                                  ]) : []),
                                  ...(widget.type == CalendarEventType.PendingLift ? ([
                                    widget.lift.pendingNote.isEmpty ? SizedBox(
                                      height: 0,) : SizedBox(
                                        height: defaultSpace),
                                    widget.lift.pendingNote.isEmpty ? SizedBox(
                                      height: 0,) : Row(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start, children: [
                                      labelText(text: "My note: "),
                                      Expanded(child: infoText(
                                          widget.lift.pendingNote))
                                    ])
                                  ]) : []),
                                  SizedBox(height: defaultSpace),
                                  Row(crossAxisAlignment: CrossAxisAlignment
                                      .start, children: [
                                    labelText(text: "Payment methods: "),
                                    Expanded(child: infoText(
                                        widget.lift.payments.isEmpty
                                            ? "Please contact the driver"
                                            : widget.lift.payments))
                                  ]),
                                ],
                              )),
                          Divider(
                            thickness: 3,
                          ),
                          Container(
                              alignment: Alignment.bottomLeft,
                              color: Colors.white,
                              child: ConfigurableExpansionTile(
                                header: Container(
                                    alignment: Alignment.bottomLeft,
                                    child: Text(
                                        "Passengers ${widget.lift.passengers
                                            .length}/${widget.lift
                                            .numberOfSeats}",
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
              }else{
                  return Center(child: Text("${widget.type == CalendarEventType.Drive? "Drive" : "Lift"} canceled", style: TextStyle(fontSize: 15),),);
                }
            }else{
                if(snapshot.hasError){
                  return Center(child: Text("Error loading passenger info", style: TextStyle(fontSize: 15),),);
                }else{
                  return Center(child: CircularProgressIndicator(),);
                }
              }}catch(e) {
              return Center(child: Text(
                "Error loadinginfo", style: TextStyle(fontSize: 15),),);
            }
          });

      return Scaffold(
        key: _errorSnack,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "${widget.type == CalendarEventType.Drive ? "Drive" : "Lift"} Info",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Container(
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
            child: Column(
              children: [Expanded(child: allInfo),searchLift],
            )),
        backgroundColor: mainColor,
      );
    });
  }

  showAlertDialog(BuildContext context,String title,String info,UserRepository usrRep, String cancelType) {
    Widget okButton = FlatButton(
      textColor: mainColor,
      child: Text("Yes"),
      onPressed: () async {
        bool retval = false;
        if(cancelType == "CanceledLift") {
          retval = await _cancelRequest(usrRep);
        }
        else{
          if(cancelType == "CanceledPending"){
            retval = await _cancelPending(usrRep);
          }else {
            retval = await _cancelDrive(usrRep);
            if(retval){
              retval = await _cancelDriveQueryAux(usrRep);
            }
          }
        }
        Navigator.pop(context);
        if(retval){
          Navigator.pop(context);
        }
        else{
          //Navigator.pop(context);
          showErrorDialog(context, "Error", "An error occured.\nPlease try again.", usrRep);
        }
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
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


/*
 Widget _buildTiles() {
    return ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          return _buildTile(null);
        });
  }

  void _openInfoDialog() {
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return null;
        },
        fullscreenDialog: true));
  }

 */