import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/main.dart';

class DesiredLiftInfo extends StatefulWidget {
  final String docId;

  DesiredLiftInfo({@required this.docId});
  @override
  _DesiredLiftInfoState createState() => _DesiredLiftInfoState();
}

class _DesiredLiftInfoState extends State<DesiredLiftInfo> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    chatTalkPage = false;
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


    showAlertDialog(BuildContext context,String title,String info) {
      Widget okButton = FlatButton(
        textColor: mainColor,
        child: Text("Yes"),
        onPressed: () async {
          await firestore.collection("Desired").doc(widget.docId).delete();
          Navigator.pop(context);
          Navigator.pop(context);
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

    return StreamBuilder(stream: firestore
        .collection("Desired").doc(widget.docId).snapshots(),
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            if (snapshot.data.exists) {
              final lift = snapshot.data;
              return Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  title: Text(
                    "Desired Lift Info",
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
                                                lift["liftTimeStart"]
                                                    .toDate()) + " - " +
                                                DateFormat('kk:mm').format(
                                                    lift["liftTimeEnd"]
                                                        .toDate())))
                                  ],
                                ),
                                SizedBox(height: defaultSpace),
                                Row(crossAxisAlignment: CrossAxisAlignment
                                    .start,
                                    children: [
                                      labelText(text: "Pickup from: "),
                                      Expanded(child: infoText(
                                          lift["startAddress"]))
                                    ]),
                                SizedBox(height: defaultSpace),
                                Row(crossAxisAlignment: CrossAxisAlignment
                                    .start,
                                    children: [
                                      labelText(text: "Drop-off at: "),
                                      Expanded(child: infoText(
                                          lift["destAddress"]))
                                    ]),
                                SizedBox(height: defaultSpace),
                                Row(crossAxisAlignment: CrossAxisAlignment
                                    .start,
                                    children: [
                                      labelText(text: "Max distance: "),
                                      Expanded(child: infoText(
                                          (lift["maxDistance"] / 1000)
                                              .toStringAsFixed(1) + "km"))
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
                                        Row(children: [
                                          labelText(text: "Big Trunk: "),
                                          lift["bigTrunk"]
                                              ? Icon(Icons.check_circle_outline,
                                              color: secondColor)
                                              : Icon(Icons.cancel_outlined,
                                              color: Colors.pink)
                                        ]),
                                        SizedBox(height: defaultSpace),
                                        Row(children: [
                                          labelText(
                                              text: "Backseat not full?: "),
                                          lift["backSeatNotFull"]
                                              ? Icon(Icons.check_circle_outline,
                                              color: secondColor)
                                              : Icon(Icons.cancel_outlined,
                                              color: Colors.pink)
                                        ]),
                                      ],
                                    )),
                                Divider(
                                  thickness: 3,
                                ),
                              ]))), (lift["liftTimeEnd"].toDate()).isBefore(DateTime.now()) ? Container(
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
                              label: Text("Cancel Desired",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 17)),
                              onPressed: () => showDialog(context: context,builder: (_) {
          return AlertDialog(shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Text("The Desired-Lift has past"),content: Text("You can't cancle a Desired-Lift that has already passed"),actions: [
          TextButton(onPressed: () =>
          Navigator.pop(context),
          child: Text("Dismiss"))]);}))) : Container(
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
                              label: Text("Cancel Desired",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 17)),
                              onPressed: () async {
                                showAlertDialog(context, "Cancel Desired",
                                    "Are you sure you want to cancel?\nThere is no going back");
                              }))
                      ],
                    )),
                backgroundColor: mainColor,
              );
            }else {
              return Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  title: Text(
                    "Desired Lift Info",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                body: Container(
                    decoration: pageContainerDecoration,
                    margin: pageContainerMargin,
                    child: Center(child: Text("Desired Lift Deleted"),)),
                backgroundColor: mainColor,
              );
            }
          }else if(snapshot.hasError){
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.error),
                  Text("Error loading desired info")
                ]);
          }else{
            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                title: Text(
                  "Desired Lift Info",
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