import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';


import 'ProfilePage.dart';

class LiftInfoPage extends StatefulWidget {
  MyLift lift = new MyLift("driver", "destAddress", "stopAddress", 5);
  liftRes resLift =new liftRes();
  LiftInfoPage({Key key, @required this.lift,@required this.resLift}) : super(key: key);

  @override
  _LiftInfoPageState createState() => _LiftInfoPageState();
}

class _LiftInfoPageState extends State<LiftInfoPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController myNoteController;
  bool bigBag= false;
  @override
  void initState() {
    super.initState();
    myNoteController = TextEditingController();
    widget.lift.payments="";
  }

  Future<bool> addRequest(UserRepository userRep) async {
    bool retValue;
    try{
      retValue = await firestore.runTransaction((transaction) async {
         return transaction.get(firestore.collection("Drives")
            .doc(widget.lift.liftId))
            .then((value) async {
           retValue = ((List.from(value.data()["Passengers"])).length < (value.data()["NumberSeats"] as int));
           transaction.set(firestore.collection("Notifications").doc(widget.lift.driver).collection("UserNotifications").doc(),
              {
                "destCity": widget.resLift.destAddress.locality,
                "destAddress": widget.resLift.destAddress.addressLine,
                "startCity": widget.resLift.startAddress.locality,
                "startAddress": widget.resLift.startAddress.addressLine,
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
              }
          );
          return  true&&retValue;
        });
      });
      }catch(e){

       return  false;
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

    Widget _buildRow(BuildContext context) {
      return Container(
        child: Column(
          // As you expect multiple lines you need a column not a row
          children: _buildRowList(),
        ),
      );
    }

    final additionInfo =  FutureBuilder<DocumentSnapshot>(
        future:  firestore.collection("Profiles").doc(widget.lift.driver).get(), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData) {
            widget.lift.payments =snapshot.data.data()["allowedPayments"].join(", ");
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
                  //tilePadding: EdgeInsets.symmetric(horizontal: 0),
                  // backgroundColor: Colors.white,
                  // trailing: Icon(Icons.arrow_drop_down,color: Colors.black,),
                  //title: Text("Passenger info"),
                  children: [
                    Row(children: [
                      labelText(text: "Big Trunk: "),
                      widget.lift.bigTrunk
                          ? Icon(Icons.check_circle_outline, color: Colors.teal)
                          : Icon(Icons.cancel_outlined, color: Colors.pink)
                    ]),
                    SizedBox(height: defaultSpace),
                    Row(children: [
                      labelText(text: "Backseat not full?: "),
                      widget.lift.backSeat
                          ? Icon(Icons.check_circle_outline, color: Colors.teal)
                          : Icon(Icons.cancel_outlined, color: Colors.pink)
                    ]),
                    SizedBox(height: defaultSpace),
                    _buildRow(context),
                    SizedBox(height: defaultSpace),
                    Row(children: [
                      labelText(text: "Drivers note: "),
                      Expanded(child: infoText(widget.lift.note))
                    ]),
                    SizedBox(height: defaultSpace),
                    Row(children: [
                      labelText(text: "Payment methods: "),
                      Expanded(child: infoText(widget.lift.payments))
                    ]),
                  ],
                ));
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
    });

    final passengers = Container(
        alignment: Alignment.bottomLeft,
        color: Colors.white,
        child: ConfigurableExpansionTile(
          header: Container(
              alignment: Alignment.bottomLeft,
              child: Text("Passengers info",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
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
        ));
    final searchLift =
    Consumer<UserRepository>(builder: (context, userRep, _) { return Container(
        padding: EdgeInsets.only(
            left: sizeFrameWidth * 0.2,
            right: sizeFrameWidth * 0.2,
            bottom: defaultSpace * 2),
        height: defaultSpace * 6,
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
              bool checkVal = await addRequest(userRep);
              if (checkVal == false) {
                showAlertDialog(context,"The lift is not available","Press ok to return to results");
              } else {
                showAlertDialog(context,"The request has been sent","Press ok to return to results");
              }
            }));
    });

    final allInfo =
       Container(
          child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                  left: defaultSpacewidth, right: defaultSpacewidth),
              children: [
              SizedBox(height: defaultSpace),
          Text("Driver:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          _buildTile(widget.lift),
          Divider(
            thickness: 3,
          ),
          SizedBox(height: defaultSpace),
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              labelText(text: "Date and time: "),
              Expanded(
                  child: infoText(
                      DateFormat('dd/MM - kk:mm').format(widget.lift.time)))
            ],
          ),
          SizedBox(height: defaultSpace),
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            labelText(text: "Starting Point: "),
            Expanded(child: infoText(widget.lift.startAddress))
          ]),
          SizedBox(height: defaultSpace),
         // _buildRow(context),
              SizedBox(height: defaultSpace),
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            labelText(text: "Destination: "),
            Expanded(child: infoText(widget.lift.destAddress))
          ]),
          SizedBox(height: defaultSpace),
      /*    Row(children: [
            labelText(text: "Big Trunk: "),
            widget.lift.bigTrunk
                ? Icon(Icons.check_circle_outline, color: Colors.teal)
                : Icon(Icons.cancel_outlined, color: Colors.pink)
          ]),
          SizedBox(height: defaultSpace),
          Row(children: [
            labelText(text: "Backseat not full?: "),
            widget.lift.backSeat
                ? Icon(Icons.check_circle_outline, color: Colors.teal)
                : Icon(Icons.cancel_outlined, color: Colors.pink)
          ]),
          SizedBox(height: defaultSpace),
          Row(children: [
            labelText(text: "Drivers note: "),
            Expanded(child: infoText(widget.lift.note))
          ]),
          SizedBox(height: defaultSpace),
        */  Row(
            //mainAxisAlignment: MainAxisAlignment.start,
            //  crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
          labelText(text: "Price: "),
                Image.asset("assets/images/shekel.png",scale: 0.9),
                infoText(widget.lift.price.toString()),
          ]),
          Divider(
            thickness: 3,
          ),
              additionInfo,
              Divider(
                thickness: 3,
              ),
              passengers,
          Divider(
            thickness: 3,
          ),
          SizedBox(height: defaultSpace),
              Container(
               // width:300*defaultSpacewidth,
               // color: Colors.red,
             //   decoration: BoxDecoration(
               //   color: Colors.white,
               //   boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2.0,
              //        spreadRadius: 0.0, offset: Offset(2.0, 2.0))
              //    ],
             //     border: Border.all(color: secondColor, width: 0.8),
             //     borderRadius: BorderRadius.circular(15.0),),
                child: Column(
                children:[generalInfoBoxTextField(controllerText: myNoteController, enabled: true, maxLines: 1,nameLabel: "Request note to driver:",maxLenth: 120),
                    Row(
            //    mainAxisAlignment: MainAxisAlignment.start,
            //    crossAxisAlignment: CrossAxisAlignment.start,
             //   mainAxisSize: MainAxisSize.min,
                  children: [
                 /*   CheckboxListTile(
                      title: Text('Big Bag'),
                      value: bigBag,
                       onChanged: (bool value){setState(() {bigBag = value;});}),*/

                    labelText(text: "Big Bag: "),
                    Container(alignment:Alignment.topLeft,child: Theme(data: ThemeData(unselectedWidgetColor: secondColor), child:Checkbox(value: bigBag,
                      onChanged: (bool value){setState(() {bigBag = value;});}))),
                  ],)]),
              ),
              SizedBox(height: defaultSpace*2),
            ]));

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
            children: [Expanded(child: allInfo), searchLift,],
          )),
      backgroundColor: mainColor,
    );
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
                            color: Colors.teal,
                            image: DecorationImage(
                                fit: BoxFit.fill,
                                image: NetworkImage(snapshot.data[0])),
                          ))),
                  Container(
                      margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.016,
                          top: MediaQuery.of(context).size.height * 0.016),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          infoText(snapshot.data[1]),
                        ],
                      )),
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

  Widget _buildTile(MyLift lift) {
    return FutureBuilder<List<String>>(
        future: initNames(lift.driver),
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
                            color: Colors.teal,
                            image: DecorationImage(
                                fit: BoxFit.fill,
                                image: NetworkImage(snapshot.data[0])),
                          ))),
                  Container(
                      margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.016,
                          top: MediaQuery.of(context).size.height * 0.016),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          infoText(snapshot.data[1]),
                          //placesText(lift.startAddress),
                          allInfoText(lift.dist ~/ 1000),
                          //SizedBox(height:MediaQuery.of(context).size.height * 0.016 ,)
                        ],
                      )),
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

  Widget allInfoText(int dist) {
    return Container(
        child: Row(
      children: [
        Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
        SizedBox(width: MediaQuery.of(context).size.height * 0.01),
        Text(dist.toString() + "km"),
      ],
    ));
  }

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
  showAlertDialog(BuildContext context,String title,String info) {
    Widget okButton = FlatButton(
      textColor: mainColor,
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(info,style:TextStyle(fontSize: 17)),
      actions: [
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