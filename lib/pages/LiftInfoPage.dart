import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tech_pool/Utils.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';


class LiftInfoPage extends StatefulWidget {
  MyLift lift = new MyLift("driver", "destAddress", "stopAddress", 5);

  LiftInfoPage({Key key,@required this.lift}): super(key: key);

  @override
  _LiftInfoPageState createState() => _LiftInfoPageState();
}

class _LiftInfoPageState extends State<LiftInfoPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpace = MediaQuery.of(context).size.height*0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height*0.016;

    List<Widget> _buildRowList() {
      List<Widget> stops = [];
      int i = 1;
      widget.lift.stops.forEach((key, value) {
        stops.add(Row( crossAxisAlignment: CrossAxisAlignment.start,children: [labelText(text: "Stop-"+ i.toString() +" "),Expanded(child:infoText(key.toString()))],));
        stops.add(SizedBox(height: defaultSpace));
        i++;
      });
      return stops;
    }

    Widget _buildRow(BuildContext context) {
      return Container(
        child: Column( // As you expect multiple lines you need a column not a row
          children: _buildRowList(),
        ),
      );
    }

    final searchLift =
    Container(
        padding: EdgeInsets.only(left: sizeFrameWidth*0.2, right:sizeFrameWidth*0.2,bottom:defaultSpace*2 ) ,
        height: defaultSpace*6,
        child: RaisedButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Transform.rotate(angle: 0.8,child:Icon(Icons.thumb_up_rounded,color:  Colors.white)),
            label: Text("Request Lift  ",style: TextStyle(color: Colors.white,fontSize: 17)),
            onPressed: () {}
        ));

    final allInfo = Container(
      child:  ListView(
          shrinkWrap: true,
        padding: EdgeInsets.only(left: defaultSpacewidth, right:defaultSpacewidth),
          children: [
            SizedBox(height: defaultSpace),
            Text("Lift Info",style:TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: defaultSpace),
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
                 children:[labelText(text: "Date and time: "),Expanded(child:infoText(DateFormat('dd-MM - kk:mm').format(widget.lift.time)))],
           ),
            SizedBox(height: defaultSpace),
            Row(children:[labelText(text: "Starting Point: "),Expanded(child:infoText(widget.lift.startCity))]),
            SizedBox(height: defaultSpace),
            _buildRow(context),
            Row(children:[labelText(text: "Destination: "),Expanded(child:infoText(widget.lift.destCity))]),
            SizedBox(height: defaultSpace),
            Row(children:[labelText(text: "Big Trunk: "),widget.lift.bigTrunk?Icon(Icons.check_circle_outline,color: Colors.teal): Icon(Icons.cancel_outlined,color: Colors.pink)]),
            SizedBox(height: defaultSpace),
            Row(children:[labelText(text: "Backseat not full?: "),widget.lift.backSeat?Icon(Icons.check_circle_outline,color: Colors.teal): Icon(Icons.cancel_outlined,color: Colors.pink)]),
            SizedBox(height: defaultSpace),
            Row(children:[labelText(text: "Drivers note: "),Expanded(child:infoText(widget.lift.note))]),
            SizedBox(height: defaultSpace),
            Row(children:[labelText(text: "Price: "),Expanded(child:infoText(widget.lift.price.toString()))]),
            Divider(thickness: 3,),
            Text("Driver:",style:TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            _buildTile(widget.lift),
            SizedBox(height: defaultSpace),

            
    ]));
    return Scaffold(
      appBar: AppBar(
        title: Text("Lift Info",style: TextStyle(color: Colors.white),),
      ),
      body:Container(
          margin: EdgeInsets.only(
              left: defaultSpacewidth, right: defaultSpacewidth, bottom: 10),
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          color: Colors.white,
          child: Column(
            children: [Expanded(child:allInfo),searchLift],
          )),
      backgroundColor: mainColor,
    );
  }

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
        fullscreenDialog: true
    ));
  }


  Widget _buildTile(MyLift lift) {
    return Container(
      child:
      Row(
        children:[
          Container(
              margin: EdgeInsets.only(
                  left: MediaQuery.of(context).size.height * 0.016, top: MediaQuery.of(context).size.height * 0.016),
              width: MediaQuery.of(context).size.height * 0.016*4,
              height: MediaQuery.of(context).size.height * 0.016*4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal,
              )),
          Container(
              margin: EdgeInsets.only(
                  left: MediaQuery.of(context).size.height * 0.016, top: MediaQuery.of(context).size.height * 0.016),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
               children: [infoText(lift.driver),placesText(lift.startAddress),allInfoText(lift.time),],
              )),
          Spacer(),
          SizedBox(width:MediaQuery.of(context).size.height * 0.016 ,)
        ],
      ),
    );
  }
  Widget allInfoText(DateTime time){
    return Container(
        child:Row(
          children: [
            Icon(Icons.timer),
            Text(DateFormat('kk:mm').format(time)),
          ],
        ));
  }

  Widget infoText(String info) {
    return  Container(
        width: MediaQuery.of(context).size.height * 0.016*20,
        child: Text(info,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }

  Widget placesText(String from) {
    return  Container(
        width: MediaQuery.of(context).size.height * 0.016*20,
        child: Text(from,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }
}
