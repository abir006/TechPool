import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/Utils.dart';

class CanceledLiftInfo extends StatefulWidget {
  final String notificationId;
  final String userId;
  final String type;
  //final bool fromNotification;

  //final String driverOrPassengerName;

  CanceledLiftInfo({@required this.notificationId, @required this.userId,@required this.type});
  @override
  _CanceledLiftInfoState createState() => _CanceledLiftInfoState();
}

class _CanceledLiftInfoState extends State<CanceledLiftInfo> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;


  //getting the photo and full name of a driver/hitchhiker
  Future<String> initName(String name) {
    String name = "";
      return firestore.collection("Profiles").doc(name).get().then((value) {
        name =  value.data()["firstName"] + " " + value.data()["lastName"] ;
        return name;
      });
    //  return null;
  }

  @override
  Widget build(BuildContext context) {
    double defaultSpace = MediaQuery.of(context).size.height * 0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    var sizeFrameWidth = MediaQuery.of(context).size.width;
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


    // showAlertDialog(BuildContext context,String title,String info) {
    //   Widget okButton = FlatButton(
    //     textColor: mainColor,
    //     child: Text("Yes"),
    //     onPressed: () async {
    //       await firestore.collection("Desired").doc(widget.notificationId).delete();
    //       Navigator.pop(context);
    //     },
    //   );
    //
    //   Widget cancelButton = FlatButton(
    //     child: Text("Cancel"),
    //     textColor: mainColor,
    //     onPressed:  () {
    //       Navigator.pop(context);
    //     },
    //   );
    //
    //   AlertDialog alert = AlertDialog(
    //     shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.all(Radius.circular(20.0))),
    //     title: Text(title),
    //     content: Text(info,style:TextStyle(fontSize: 17)),
    //     actions: [
    //       cancelButton,
    //       okButton,
    //     ],
    //   );
    //
    //   // show the dialog
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return alert;
    //     },
    //   );
    // }

    return StreamBuilder(stream: firestore.collection("Notifications").
    doc(widget.userId).collection("UserNotifications").
    doc(widget.notificationId).snapshots(),
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            if (snapshot.data.exists) {
              final notification = snapshot.data;
              //final nameId = widget.type == "CanceledLift" ? notification["driverId"] : notification["passengerId"];
              //final name = await initName(nameId);
              return Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  title: Text( widget.type == "CanceledLift" ? "Canceled Lift Info" : "Canceled Drive Info",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                body: Container(
                    decoration: pageContainerDecoration,
                    margin: pageContainerMargin,
                    child: Column(
                      children: [Expanded(child: Container(
                          child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.only(
                                  left: defaultSpacewidth,
                                  right: defaultSpacewidth),
                              children: [SizedBox(height: defaultSpace),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    labelText(text: "Date and time: "),
                                    Expanded(
                                        child: infoText(
                                            DateFormat('dd/MM , kk:mm').format(
                                                notification["liftTime"]
                                                    .toDate())
                                        )
                                    )
                                  ],
                                ),
                                SizedBox(height: defaultSpace),
                                Row(crossAxisAlignment: CrossAxisAlignment
                                    .start,
                                    children: [
                                      labelText(text: "Pickup from: "),
                                      Expanded(child: infoText(
                                          notification["startAddress"]))
                                    ]),
                                SizedBox(height: defaultSpace),
                                Row(crossAxisAlignment: CrossAxisAlignment
                                    .start,
                                    children: [
                                      labelText(text: "Drop-off at: "),
                                      Expanded(child: infoText(
                                          notification["destAddress"]))
                                    ]),
                                // SizedBox(height: defaultSpace),
                                // Row(crossAxisAlignment: CrossAxisAlignment
                                //     .start,
                                //     children: [
                                //       labelText(text: widget.type == "CanceledLift" ? "Hitchhiker:" : "Driver"),
                                //       Expanded(child: infoText(
                                //           (notification["maxDistance"] / 1000)
                                //               .toStringAsFixed(1) + "km"))
                                //     ]),
                                // SizedBox(height: defaultSpace),
                                // Divider(
                                //   thickness: 3,
                                // ),
                                // Container(
                                //     alignment: Alignment.bottomLeft,
                                //     color: Colors.white,
                                //     child: ConfigurableExpansionTile(
                                //       header: Container(
                                //           alignment: Alignment.bottomLeft,
                                //           child: Text("Additional info",
                                //               style: TextStyle(
                                //                   fontWeight: FontWeight.bold,
                                //                   fontSize: 17))),
                                //       animatedWidgetFollowingHeader: const Icon(
                                //         Icons.expand_more,
                                //         color: const Color(0xFF707070),
                                //       ),
                                //       //tilePadding: EdgeInsets.symmetric(horizontal: 0),
                                //       // backgroundColor: Colors.white,
                                //       // trailing: Icon(Icons.arrow_drop_down,color: Colors.black,),
                                //       //title: Text("Passenger info"),
                                //       children: [
                                //         Row(children: [
                                //           labelText(text: "Big Trunk: "),
                                //           notification["bigTrunk"]
                                //               ? Icon(Icons.check_circle_outline,
                                //               color: secondColor)
                                //               : Icon(Icons.cancel_outlined,
                                //               color: Colors.pink)
                                //         ]),
                                //         SizedBox(height: defaultSpace),
                                //         Row(children: [
                                //           labelText(
                                //               text: "Backseat not full?: "),
                                //           notification["backSeatNotFull"]
                                //               ? Icon(Icons.check_circle_outline,
                                //               color: secondColor)
                                //               : Icon(Icons.cancel_outlined,
                                //               color: Colors.pink)
                                //         ]),
                                //       ],
                                //     )),
                                // Divider(
                                //   thickness: 3,
                                // ),
                              ]))),
                        // Container(
                        //   padding: EdgeInsets.only(
                        //       left: sizeFrameWidth * 0.2,
                        //       right: sizeFrameWidth * 0.2,
                        //       bottom: defaultSpace * 2),
                        //   height: defaultSpace * 6,
                        //   child: RaisedButton.icon(
                        //       color: Colors.red[800],
                        //       shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(18),
                        //           side: BorderSide(color: Colors.black)),
                        //       icon: Icon(Icons.delete, color: Colors.white,),
                        //       label: Text("Cancel Desired",
                        //           style: TextStyle(
                        //               color: Colors.white, fontSize: 17)),
                        //       onPressed: () async {
                        //         showAlertDialog(context, "Cancel Desired",
                        //             "Are you sure you want to cancel?\nThere is no going back");
                        //       }))
                      ],
                    )),
                backgroundColor: mainColor,
              );
            }else {
              return Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  title: Text(
                    widget.type == "CanceledLift" ? "Canceled Lift Info" : "Canceled Drive Info",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                body: Container(
                    decoration: pageContainerDecoration,
                    margin: pageContainerMargin,
                    child: Center(child: Text(widget.type == "CanceledLift" ? "Canceled Lift" : "Canceled Drive" + " Notification Deleted"),)),
                backgroundColor: mainColor,
              );
            }
          }else if(snapshot.hasError){
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.error),
                  Text("Error loading canceled lift info")
                ]);
          }else{
            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                title: Text(
                  widget.type == "CanceledLift" ? "Canceled Lift Info" : "Canceled Drive Info",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: Container(
                  decoration: pageContainerDecoration,
                  margin: pageContainerMargin,
                  child: Center(child: CircularProgressIndicator(),)),
              backgroundColor: mainColor,
            );
          }
        }
    );
  }
}



Widget labelText({@required String text}){
  return Container(
    child: Text(
      text,
      style:
      TextStyle( fontSize: 17, color: Colors.black.withOpacity(0.6)),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}