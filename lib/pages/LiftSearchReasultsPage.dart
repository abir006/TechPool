import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:tech_pool/Utils.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:dropdown_customizable/dropdown_customizable.dart';
import 'package:f_datetimerangepicker/f_datetimerangepicker.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class LiftSearchReasultsPage extends StatefulWidget {
  @override
  _LiftSearchReasultsPageState createState() => _LiftSearchReasultsPageState();
}

class _LiftSearchReasultsPageState extends State<LiftSearchReasultsPage> {
  final _pageKey = GlobalKey<_LiftSearchReasultsPageState>();
  List<String> _searchParams = ["Time", "Distance"];
  String _currsSearchDrop = "Time";

  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpaceHeight = MediaQuery.of(context).size.height * 0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;

    final searchLift = Container(
        child: FlatButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Icon(Icons.edit_outlined, color: Colors.white),
            label: Text("Edit Search",
                style: TextStyle(color: Colors.white, fontSize: 17)),
            onPressed: () {}));

    final sortAndSearch = Container(
        color: Colors.lightBlue,
      child:Container(
          margin: EdgeInsets.only(
              left: defaultSpacewidth),
        child: Row(children: [
          Text(
            ' Sort by:',
            style: TextStyle(fontSize: fontTextsSize, color: Colors.white),
          ),
          Container(
            child: Theme(
                data: Theme.of(context).copyWith(
                    canvasColor: Colors.lightBlue,
                    // background color for the dropdown items
                    buttonTheme: ButtonTheme.of(context).copyWith(
                      alignedDropdown:
                          true, //If false (the default), then the dropdown's menu will be wider than its button.
                    )),
                child: DropdownButton<String>(
                    elevation: 0,
                    value: _currsSearchDrop,
                    onChanged: (String newValue) {
                      setState(() {
                        _currsSearchDrop = newValue;
                      });
                    },
                    items: _searchParams
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value, style: TextStyle(color: Colors.white)),
                      );
                    }).toList())),
          ),
          Spacer(),
          searchLift,
        ])));

    final _fbuildTiles = ListView.separated(
      shrinkWrap: true,
      itemCount: 30,
      separatorBuilder: (BuildContext context, int index) => Divider(thickness: 4,),
      itemBuilder: (BuildContext context, int index) {
        return _buildTile(null);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Search Results"),
      ),
      body: Container(
          margin: EdgeInsets.only(
              left: defaultSpacewidth, right: defaultSpacewidth, bottom: 10),
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          color: Colors.white,
          child: Column(
            children: [sortAndSearch, Expanded(child:_fbuildTiles)],
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
                children: [infoText("Ori"),placesText("Technion","Ramat Gan"),allInfoText(DateTime.now(), 24, 23, 3, 1),],
              )),
        Spacer(),
       InkWell(child:Icon(Icons.arrow_forward_ios_outlined),onTap:() {},),
              SizedBox(width:MediaQuery.of(context).size.height * 0.016 ,)
            ],
      ),
    );
  }
  Widget allInfoText(DateTime time,int dist, int price,int avaliable,int taken){
   return Container(
       child:Row(
     children: [
       Icon(Icons.timer),
       Text(DateFormat('kk:mm').format(time)),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Icon(Icons.directions_walk),
       Text(dist.toString()+"km"),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Icon(Icons.person),
       Text(taken.toString()+"/"+avaliable.toString()),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Container(child:Image.asset("assets/images/shekel.png",scale: 1.3)),
       Text(price.toString()),

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

  Widget placesText(String from,String to) {
    return  Container(
      width: MediaQuery.of(context).size.height * 0.016*20,
        child: Text(from+" -> "+to,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }
}
