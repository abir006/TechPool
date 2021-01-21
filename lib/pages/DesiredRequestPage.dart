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
import 'ProfilePage.dart';

enum _errorsRequest {repetRequest,generalError,isOK}

class DesiredRequestPage extends StatefulWidget {
  MyLift lift = new MyLift("driver", "destAddress", "stopAddress", 5);
  //liftRes resLift =new liftRes();
  final LiftNotification notification;
  //final String desiredId;

  DesiredRequestPage({Key key, @required this.lift,@required this.notification}) : super(key: key);

  @override
  _DesiredRequestPageState createState() => _DesiredRequestPageState();
}

class _DesiredRequestPageState extends State<DesiredRequestPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController myNoteController;
  bool bigBag= false;
  @override
  void initState() {
    super.initState();
    myNoteController = TextEditingController();
    widget.lift.payments="";
  }

  Future<_errorsRequest> addRequest(UserRepository userRep) async {
    try{
      QuerySnapshot q = await firestore.collection("Notifications").doc(widget.lift.driver).collection("UserNotifications").where("driveId",isEqualTo:widget.lift.liftId ).where("passengerId",isEqualTo:userRep.user.email ).where( "type", isEqualTo: "RequestedLift",).get();
      if(q.docs.isNotEmpty){
        return _errorsRequest.repetRequest;
      }
    }catch(e){
      return  _errorsRequest.generalError;
    }
    try{
      return  await firestore.runTransaction((transaction) async {
        return transaction.get(firestore.collection("Drives")
            .doc(widget.lift.liftId))
            .then((value) async {
          bool retValueT = ((List.from(value.data()["Passengers"])).length < (value.data()["NumberSeats"] as int));
          if(!retValueT){
            return _errorsRequest.generalError;
          }
          transaction.set(firestore.collection("Notifications").doc(widget.lift.driver).collection("UserNotifications").doc(),
              {
                "startCity": widget.notification.startCity,
                "destCity": widget.notification.destCity,
                "destAddress": widget.notification.destAddress,
                "startAddress": widget.notification.startAddress,
                "distance": widget.lift.dist,
                "driveId": widget.lift.liftId,
                "driverId": widget.lift.driver,
                "liftTime": widget.lift.time,
                "notificationTime": DateTime.now(),
                "price": widget.lift.price,
                "passengerId": userRep.user.email,
                "passengerNote": myNoteController.text,
                "bigBag":bigBag,
                "type": "RequestedLift",
                "read": "false",
                "desiredId": widget.notification.desiredId,
              }
          );
          transaction.set(firestore.collection("Notifications").doc(userRep.user.email).collection("Pending").doc(),
              {
                "startCity": widget.notification.startCity,
                "destCity": widget.notification.destCity,
                "destAddress": widget.notification.destAddress,
                "startAddress": widget.notification.startAddress,
                "distance": widget.lift.dist,
                "driveId": widget.lift.liftId,
                "driverId": widget.lift.driver,
                "liftTime": widget.lift.time,
                "timeStamp": DateTime.now(),
                "price": widget.lift.price,
                "passengerId": userRep.user.email,
                "passengerNote": myNoteController.text,
                "bigBag":bigBag,
              }
          );
          return  _errorsRequest.isOK;
        });
      });
    }catch(e){
      return  _errorsRequest.generalError;
    }
  }

  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpace = MediaQuery.of(context).size.height * 0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    List<Widget> _buildRowList() {
      List<Widget> stops = [];
      int i = 1;
      widget.lift.stops.forEach((key) {
        stops.add(SizedBox(height: defaultSpace));
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

    /// return the passengers List tiles
    List<Widget> _buildPassengersList() {
      List<Widget> passengers = [];
      for (int i = 0; i < widget.lift.passengers.length; i++) {
        passengers.add(_buildPassengerTile(widget.lift.passengers[i]));
      }
      return passengers;
    }

    ///return the route of the driver
    Widget _buildRow(BuildContext context) {
      return Container(
        child: Column(
          // As you expect multiple lines you need a column not a row
          children: _buildRowList(),
        ),
      );
    }
    ///return the addition information on the driver
    Widget additionInfo() {
      return FutureBuilder<DocumentSnapshot>(
          future:  firestore.collection("Profiles").doc(widget.lift.driver).get(), // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasData) {
              widget.lift.payments =snapshot.data.data()["allowedPayments"].join(", ");
              widget.lift.payments =  widget.lift.payments.isEmpty?"Contact driver": widget.lift.payments;
              return Container(
                  alignment: Alignment.bottomLeft,
                  color: Colors.white,
                  child: ConfigurableExpansionTile(
                    header: Container(
                        alignment: Alignment.bottomLeft,
                        child: Text("Additional info",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17))),
                    animatedWidgetFollowingHeader: const Icon(
                      Icons.expand_more,
                      color: const Color(0xFF707070),
                    ),
                    children: [
                      Row(children: [
                        labelText(text: "Big Trunk: "),
                        widget.lift.bigTrunk
                            ? Icon(Icons.check_circle_outline, color: secondColor)
                            : Icon(Icons.cancel_outlined, color: Colors.pink)
                      ]),
                      SizedBox(height: defaultSpace),
                      Row(children: [
                        labelText(text: "Backseat not full?: "),
                        widget.lift.backSeat
                            ? Icon(Icons.check_circle_outline, color: secondColor)
                            : Icon(Icons.cancel_outlined, color: Colors.pink)
                      ]),
                      widget.lift.note.isEmpty?SizedBox(height: 0,) : SizedBox(height: defaultSpace),
                      widget.lift.note.isEmpty? SizedBox(height: 0,) : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelText(text: "Drivers note: "),
                            Expanded(child: infoText(widget.lift.note))
                          ]),
                      widget.lift.payments.isEmpty?SizedBox(height: 0,) : SizedBox(height: defaultSpace),
                      Row(children: [
                        labelText(text: "Payment methods: "),
                        Expanded(child: infoText(widget.lift.payments))
                      ]),
                    ],
                  ));
            } else {
              if(snapshot.hasError){
                return Center(child: Text("Error loading info", style: TextStyle(fontSize: 20),),);
              } else{
                return Center(
                  child: CircularProgressIndicator(),);
              }
            }
          });}

    ///The button of request lift
    final searchLift =
    Consumer<UserRepository>(builder: (context, userRep, _) {
      return StreamBuilder<DocumentSnapshot>(
          stream:firestore.collection("Drives").doc(widget.lift.liftId).snapshots(), // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
            if(snapshot.hasData && snapshot.data.exists) {
              return Container(
                  padding: EdgeInsets.only(
                      top: defaultSpace*2,
                      left: sizeFrameWidth * 0.2,
                      right: sizeFrameWidth * 0.2,
                      bottom: defaultSpace * 2),
                  //height: defaultSpace * 6,
                  child: RaisedButton.icon(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Colors.black)),
                      icon: Transform.rotate(
                          angle: 0.8,
                          child: Icon(Icons.thumb_up_rounded, color: Colors.white)),
                      label: Text("Request Lift  ",
                          style: TextStyle(color: Colors.white, fontSize: 17)),
                      onPressed: () async {
                        _errorsRequest checkVal = await addRequest(userRep);
                        if (checkVal == _errorsRequest.isOK) {
                          showAlertDialog(context, "The request has been sent", "Press ok to return to notifications");
                        } else {
                          if (checkVal == _errorsRequest.generalError) {
                            showAlertDialog(context, "The lift is not available",
                                "Press ok to return to notifications");
                          }
                          else {
                            showAlertDialog(context,"You already requested this lift","Press ok to return to notifications");
                          }
                        }
                      }));}
            else{
              return Container();
            }});
    });

    final allInfo = StreamBuilder<DocumentSnapshot>(
        stream:firestore.collection("Drives").doc(widget.lift.liftId).snapshots(), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
          if(snapshot.hasData) {
            if (snapshot.data.exists) {
              snapshot.data.data().forEach((key, value) {
                if (value != null) {
                  widget.lift.setProperty(key, value);
                }
              });
              if (widget.lift.numberOfSeats <= widget.lift.passengers.length) {
                return Center(child: Text(
                  "Lift not available", style: TextStyle(fontSize: 30),),);
              }
              return Container(
                  child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                          left: defaultSpacewidth, right: defaultSpacewidth),
                      children: [
                        SizedBox(height: defaultSpace),
                        Text("Driver:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        _buildTile(widget.lift),
                        //   Divider(
                        //     thickness: 3,
                        //   ),
                        SizedBox(height: defaultSpace),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelText(text: "Date and time: "),
                            Expanded(
                                child: infoText(
                                    DateFormat('dd/MM - kk:mm').format(widget.lift
                                        .time)))
                          ],
                        ),
                        SizedBox(height: defaultSpace),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              labelText(text: "Starting point: "),
                              Expanded(child: infoText(widget.lift.startAddress))
                            ]),
                        // SizedBox(height: defaultSpace),
                        _buildRow(context),
                        widget.lift.stops.length == 0 ? SizedBox(height: defaultSpace) : SizedBox(height: 0),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              labelText(text: "Destination: "),
                              Expanded(child: infoText(widget.lift.destAddress))
                            ]),
                        SizedBox(height: defaultSpace),
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //labelText(text: "Passengers: "),
                              //Expanded(child:infoText(widget.lift.passengers.length.toString()+"/"+widget.lift.numberOfSeats.toString())),
                            ]),
                        //   SizedBox(height: defaultSpace),
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              labelText(text: "Price: "),
                              Image.asset("assets/images/shekel.png", scale: 0.9),
                              infoText(widget.lift.price.toString()),
                            ]),
                        Divider(
                          thickness: 3,
                        ),
                        additionInfo(),
                        Divider(
                          thickness: 3,
                        ),
                        Container(
                            alignment: Alignment.bottomLeft,
                            color: Colors.white,
                            child: ConfigurableExpansionTile(
                              header: Row(
                                  children: [Container(
                                      alignment: Alignment.bottomLeft,
                                      child: Text("Passengers info " , style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 17))),
                                    Icon(Icons.person),
                                    Container(
                                        alignment: Alignment.bottomLeft,
                                        child: Text(
                                            widget.lift.passengers.length.toString() +
                                                "/" + widget.lift.numberOfSeats.toString(),
                                            style: TextStyle(fontWeight: FontWeight.bold,
                                                fontSize: 17))),
                                  ]),
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
                        Text("My requests:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: defaultSpace),
                        Container(
                          child: Column(
                              children: [
                                generalInfoBoxTextField(
                                    controllerText: myNoteController,
                                    enabled: true,
                                    maxLines: null,
                                    nameLabel: "To driver:",
                                    maxLenth: 150),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Big Bag:",
                                      style:
                                      TextStyle( fontSize: 17, color: Colors.black.withOpacity(0.6)),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    Container(alignment: Alignment.topLeft,
                                        child: Theme(data: ThemeData(
                                            unselectedWidgetColor: secondColor),
                                            child: SizedBox(
                                              height: defaultSpace,
                                              //width: defaultSpacewidth,
                                              child: Checkbox(value: bigBag,
                                                  onChanged: (bool value) {
                                                    setState(() {
                                                      bigBag = value;
                                                    });
                                                  }),
                                            ))),
                                  ],)
                              ]),
                        ),
                        SizedBox(height: defaultSpace * 2),
                      ]));
            }
            else {
              return Center(child: Text(
                "Lift not available", style: TextStyle(fontSize: 30),),);
            }
          }
          else{
            if(snapshot.hasError){
              return Center(child: Text("Lift not available", style: TextStyle(fontSize: 30),),);
            }else{
              return Center(child: CircularProgressIndicator(),);
            }
          }
        });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Lift Info",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
          decoration: pageContainerDecoration,
          margin: pageContainerMargin,
          child: Column(
            children: [Expanded(child: allInfo) , searchLift,],
          )),
      backgroundColor: mainColor,
    );
  }


  ///Initialize the first,last name and the picture of requested email/name
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
      }).catchError((e) {
        return Future.error(e);
      });
    }).catchError((e) {
      return Future.error(e);
    });
    //  return null;
  }

  Widget _buildPassengerTile(String name) {
    return FutureBuilder<List<String>>(
        future: initNames(name), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
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
                                email: name,
                                fromProfile: false,
                              );
                            },
                            fullscreenDialog: true));
                        setState(() {});
                      },
                      //child: Hero(
                      //    tag: 'dash',
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
                        ],
                      ))),
                ],
              ),
            );
          } else {
            if(snapshot.hasError){
              return Center(child: Text("Error loading info", style: TextStyle(fontSize: 15),),);
            } else{
              return Center(
                child: CircularProgressIndicator(),);
            }
          }
        });
  }

  /// returns the driver tile
  Widget _buildTile(MyLift lift) {
    return FutureBuilder<List<String>>(
        future: initNames(lift.driver),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if(snapshot.hasError){
            return Center(child: Text("Error loading info", style: TextStyle(fontSize: 15),),);
          }else{
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
                        // child: Hero(
                        //    tag: 'dash',
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
                    Expanded(
                      child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery.of(context).size.height * 0.016,
                              top: MediaQuery.of(context).size.height * 0.016),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              infoText(snapshot.data[1]),
                              //placesText(lift.startAddress),
                              allInfoText(lift.dist / 1000),
                              //SizedBox(height:MediaQuery.of(context).size.height * 0.016 ,)
                            ],
                          )),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),);
            }
          }
        });
  }

  Widget allInfoText(double dist) {
    return Container(
        child: Row(
          children: [
            Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
            SizedBox(width: MediaQuery.of(context).size.height * 0.01),
            Text(dist.toStringAsFixed(1) + "km"),
          ],
        ));
  }

  Widget infoText(String info) {
    return Container(
        width: MediaQuery.of(context).size.height * 0.016 * 20,
        child: Text(
          info,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
          //overflow: TextOverflow.ellipsis,
          maxLines: null,
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
    myNoteController.dispose();
    super.dispose();
  }
}

