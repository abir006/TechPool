import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:tech_pool/Utils.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:dropdown_customizable/dropdown_customizable.dart';
import 'package:f_datetimerangepicker/f_datetimerangepicker.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class LiftSearchReasultsPage extends StatefulWidget {
  DateTime fromTime = DateTime.now();
  DateTime toTime = DateTime.now().add(Duration(days: 1,hours: 0,minutes: 0,microseconds: 0));
  int indexDist = 20000;
  List<int> distances = [1000,5000,20000,40000];
  LiftSearchReasultsPage({Key key,@required this.fromTime,@required this.toTime,@required this.indexDist}): super(key: key);
  
  @override
  _LiftSearchReasultsPageState createState() => _LiftSearchReasultsPageState();
}

class _LiftSearchReasultsPageState extends State<LiftSearchReasultsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _pageKey = GlobalKey<_LiftSearchReasultsPageState>();
  List<String> _searchParams = ["Time", "Distance"];
  String _currsSearchDrop = "Time";
  List<MyLift> liftList =  <MyLift>[];


  Future<String> initList() async {
    try {
      liftList.clear();
      QuerySnapshot q  = await firestore.collection("Drives").where('TimeStamp', isLessThan: Timestamp.fromDate(widget.toTime),isGreaterThan: Timestamp.fromDate(widget.fromTime)).get();
      q.docs.forEach(
              (element) {
        MyLift docLift = new MyLift("driver", "destAddress", "stopAddress", 5);
        element.data().forEach((key, value) {
          if(value!=null) {
            docLift.setPropertiy(key,value);
          }
        });
        liftList.add(docLift);
      });
    } catch (e) {
    }

    Comparator<MyLift> timeComparator = (a, b) {
      if(a.time == b.time){
        return a.dist.compareTo(b.dist);
      }
      return a.time.compareTo(b.time);
    };

    Comparator<MyLift> distComparator = (a, b) {
      if(a.dist == b.dist){
        return a.time.compareTo(b.time);
      }
      return a.dist.compareTo(b.dist);
    };

    if(_currsSearchDrop == "Time"){
      liftList.sort(timeComparator);
    }else{
      liftList.sort(timeComparator);
    }
    return "finish";
  }

  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpaceHeight = MediaQuery.of(context).size.height * 0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    Future<String> _calculation = initList();
    final searchLift = Container(
        child: FlatButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Icon(Icons.edit_outlined, color: Colors.white),
            label: Text("Edit Search",
                style: TextStyle(color: Colors.white, fontSize: 17)),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchLiftPage(cuurentdate: widget.fromTime, fromtime: widget.fromTime,totime: widget.toTime,indexDis: widget.indexDist ,),
                  ));

            }));

    final sortAndSearch = Container(
        color: Colors.black.withOpacity(0.4),
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
                    canvasColor: Colors.grey,
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
      itemCount: liftList.length,
      separatorBuilder: (BuildContext context, int index) => Divider(thickness: 4,),
      itemBuilder: (BuildContext context, int index) {
        return _buildTile(liftList[index]);
      },
    );

    final _futureBuildLists = FutureBuilder<void>(
      future:_calculation, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<void> snapshot){
        if(snapshot.hasData) {
          return  ListView.separated(
            shrinkWrap: true,
            itemCount: liftList.length,
            separatorBuilder: (BuildContext context, int index) => Divider(thickness: 4,),
            itemBuilder: (BuildContext context, int index) {
              return _buildTile(liftList[index]);
            },
          );
        }else{
          return Center(child: CircularProgressIndicator(),);
        }
      }
    );


    return Scaffold(
      appBar: AppBar(
        title: Text("Search Results",style: TextStyle(color: Colors.white),),
      ),
      body:Container(
          margin: EdgeInsets.only(
              left: defaultSpacewidth, right: defaultSpacewidth, bottom: 10),
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          color: Colors.white,
          child: Column(
            children: [sortAndSearch, Expanded(child:_futureBuildLists)],
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
                children: [infoText(lift.driver),placesText(lift.startAddress,lift.destAddress),allInfoText(lift.time, 24, lift.price, lift.numberOfSeats, lift.passengers.length),],
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
       Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
       Text(dist.toString()+"km"),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Icon(Icons.person),
       Text(taken.toString()+"/"+avaliable.toString()),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Container(child:Image.asset("assets/images/shekel.png",scale: 0.9)),
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
