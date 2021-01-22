import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/streams.dart';
import 'package:tech_pool/Utils.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/pages/LiftInfoPage.dart';
import 'package:tech_pool/pages/ProfilePage.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';


class LiftSearchReasultsPage extends StatefulWidget {
  DateTime fromTime = DateTime.now();
  DateTime toTime = DateTime.now().add(Duration(days: 1,hours: 0,minutes: 0,microseconds: 0));
  int indexDist = 20000;
  List<int> distances = [1000,5000,20000,40000];
  Address startAddress;
  Address destAddress;
  bool backSeat;
  bool bigTrunk;


  LiftSearchReasultsPage({Key key,@required this.fromTime,@required this.toTime,@required this.indexDist,@required this.startAddress,@required this.destAddress, @required this.backSeat, @required this.bigTrunk}): super(key: key);
  
  @override
  _LiftSearchReasultsPageState createState() => _LiftSearchReasultsPageState();
}

class _LiftSearchReasultsPageState extends State<LiftSearchReasultsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _pageKey = GlobalKey<_LiftSearchReasultsPageState>();
  List<String> _searchParams = ["Time", "Distance"];
  String _currsSearchDrop = "Time";
  List<MyLift> liftList =  <MyLift>[];
  DocumentSnapshot docProfile;
  String imageUrl ="";
  QuerySnapshot q;
  QuerySnapshot q1;
  bool addDesired = true;
  QuerySnapshot q2;
  Map<String,DocumentSnapshot> mapi = new   Map<String,DocumentSnapshot>();

  @override
  void initState() {
    addDesired = true;
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
    }).catchError((e) {return Future.error(e);});
    //  return null;
  }

  /// filters from the list all the lifts that didn't meet the user criteria
  void filter(List<QuerySnapshot> value,UserRepository userRep){
    q = value[0];
    q1 = value[1];
    q2 = value[2];
    q2.docs.forEach((element) {
      if(element!=null) {
        mapi[element.id] = element;
      }
    });
    liftList.clear();
    q.docs.forEach(
            (element) async {
          MyLift docLift = new MyLift(
              "driver", "destAddress", "stopAddress", 5);
          element.data().forEach((key, value) {
            if (value != null) {
              docLift.setProperty(key, value);
            }
          });
          docLift.liftId = element.id;
          liftList.add(docLift);
        });

    Coordinates startPointing = widget.startAddress.coordinates;
    Coordinates destPointing = widget.destAddress.coordinates;
    List<MyLift> liftListDelete = <MyLift>[];
    liftList.forEach((element) {
      bool toRemove = false;
      if (widget.backSeat) {
        if (!element.backSeat) {
          toRemove = true;
        }
      }
      if (widget.bigTrunk) {
        if (!element.bigTrunk) {
          toRemove = true;
        }
      }
      toRemove = element.driver == userRep.user.email || toRemove;
      toRemove = element.passengers.contains(userRep.user.email) || toRemove;
      toRemove = element.passengers.length>=element.numberOfSeats || toRemove;
      q1.docs.forEach((element1) {
        toRemove = element1.data()["driveId"]==element.liftId || toRemove;

      });
      double distToStart = clacDis(element.startPoint, startPointing);
      double distToEnd = clacDis(element.destPoint, destPointing);
      element.stops.forEach((key) {
        (key as Map).forEach((key, value) {
          if (key == "stopPoint") {
            GeoPoint pointStop = value as GeoPoint;
            distToStart = min(distToStart, clacDis(pointStop, startPointing));
            distToEnd = min(distToEnd, clacDis(pointStop, destPointing));
          }
        });
      });
      element.dist = (distToStart + distToEnd).toInt();
      if(element.dist> widget.distances[widget.indexDist]) toRemove = true;
      if (toRemove) {
        liftListDelete.add(element);
      }
    });

    liftListDelete.forEach((element) {
      liftList.remove(element);
    });
    Comparator<MyLift> timeComparator = (a, b) {
      if (a.time == b.time) {
        return a.dist.compareTo(b.dist);
      }
      return a.time.compareTo(b.time);
    };

    Comparator<MyLift> distComparator = (a, b) {
      if (a.dist == b.dist) {
        return a.time.compareTo(b.time);
      }
      return a.dist.compareTo(b.dist);
    };

    if (_currsSearchDrop == "Time") {
      liftList.sort(timeComparator);
    } else {
      liftList.sort(distComparator);
    }
}

///returns the a list that represents all the lift that met the user criteria
  Future<dynamic> initList2(UserRepository userRep) async {
    return firestore.collection("Drives")
        .where('TimeStamp', isLessThanOrEqualTo: Timestamp.fromDate(widget.toTime),isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromTime))
        .get().then((value) {
      q = value;
      liftList.clear();
      q.docs.forEach(
              (element) async {
            MyLift docLift = new MyLift(
                "driver", "destAddress", "stopAddress", 5);
            element.data().forEach((key, value) {
              if (value != null) {
                docLift.setProperty(key, value);
              }
            });
            docLift.liftId = element.id;
            liftList.add(docLift);
          });

      Coordinates startPointing = widget.startAddress.coordinates;
      Coordinates destPointing = widget.destAddress.coordinates;
      List<MyLift> liftListDelete = <MyLift>[];
      liftList.forEach((element) {
        bool toRemove = false;
        if (widget.backSeat) {
          if (!element.backSeat) {
            toRemove = true;
          }
        }
        if (widget.bigTrunk) {
          if (!element.bigTrunk) {
            toRemove = true;
          }
        }
        toRemove = element.driver == userRep.user.email || toRemove;
        toRemove = element.passengers.contains(userRep.user.email) || toRemove;
        toRemove = element.passengers.length>=element.numberOfSeats || toRemove;
        double distToStart = clacDis(element.startPoint, startPointing);
        double distToEnd = clacDis(element.destPoint, destPointing);
        element.stops.forEach((key) {
          (key as Map).forEach((key, value) {
            if (key == "stopPoint") {
              GeoPoint pointStop = value as GeoPoint;
              distToStart = min(distToStart, clacDis(pointStop, startPointing));
              distToEnd = min(distToEnd, clacDis(pointStop, destPointing));
            }
          });
        });
        element.dist = (distToStart + distToEnd).toInt();
        if(element.dist> widget.distances[widget.indexDist]) toRemove = true;
        if (toRemove) {
          liftListDelete.add(element);
        }
      });

      liftListDelete.forEach((element) {
        liftList.remove(element);
      });
      Comparator<MyLift> timeComparator = (a, b) {
        if (a.time == b.time) {
          return a.dist.compareTo(b.dist);
        }
        return a.time.compareTo(b.time);
      };

      Comparator<MyLift> distComparator = (a, b) {
        if (a.dist == b.dist) {
          return a.time.compareTo(b.time);
        }
        return a.dist.compareTo(b.dist);
      };

      if (_currsSearchDrop == "Time") {
        liftList.sort(timeComparator);
      } else {
        liftList.sort(distComparator);
      }
      return Future.wait(liftList.map((e) async {
        return firestore.collection("Profiles").doc(e.driver).get().then((value) {
        DocumentSnapshot q = value;
        e.driverName = q.data()["firstName"] + " " + q.data()["lastName"];
        return FirebaseStorage.instance
            .ref('uploads')
            .child(e.driver)
            .getDownloadURL().then((value) {
              e.imageUrl = value;
              return "ok";
            });
        });
      }));
    });
  }
  
  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpaceHeight = MediaQuery.of(context).size.height * 0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;

///legacy edit lift button
    final searchLift =  Consumer<UserRepository>(
        builder: (context, userRep, _) =>Container(
      decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.only(topLeft:Radius.circular(20.0),topRight:Radius.circular(20.0) ),),
        child: FlatButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.white)),
            icon: Icon(Icons.fact_check_outlined, color: Colors.white),
            label: Text("Add Desire",
                style: TextStyle(color: Colors.white, fontSize: 17)),
            onPressed: () async {
              try {
                FirebaseFirestore.instance.collection('Desired').add({
                  'backSeatNotFull': (widget.backSeat),
                  'bigTrunk': widget.bigTrunk,
                  'destAddress': widget.destAddress.addressLine,
                  'destCity': widget.destAddress.locality,
                  'destPoint': GeoPoint(widget.destAddress.coordinates.latitude,
                      widget.destAddress.coordinates.longitude),
                  'liftTimeEnd': widget.toTime,
                  'liftTimeStart': widget.fromTime,
                  'maxDistance': widget.distances[widget.indexDist],
                  'passengerId': userRep.user.email,
                  'startCity': widget.startAddress.locality,
                  'startAddress': widget.startAddress.addressLine,
                  'startPoint': GeoPoint(
                      widget.startAddress.coordinates.latitude,
                      widget.startAddress.coordinates.longitude),
                });
                setState(() {
                  addDesired=false;
                });
              }catch(e){

              }
            })));

    final sortAndSearch = Container(
        decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.only(topLeft:Radius.circular(20.0),topRight:Radius.circular(20.0) )),
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
                    canvasColor: Colors.black,
                    // background color for the dropdown items
                    buttonTheme: ButtonTheme.of(context).copyWith(
                      alignedDropdown:
                          true, //If false (the default), then the dropdown's menu will be wider than its button.
                    )),
                child: Container(
                  child: DropdownButton<String>(
                      underline: Container(color: Colors.white,height: 2,),
                      elevation: 0,
                      value: _currsSearchDrop,
                      iconEnabledColor:Colors.white,
                      iconDisabledColor:Colors.white,
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
                      }).toList()),
                )),
          ),
          Spacer(),
          addDesired ? searchLift:Container(),
          SizedBox(width: defaultSpacewidth*0.2,)
        ])));

///build the entire list of the lifts
    final _futureBuildLists = Consumer<UserRepository>(
      builder: (context, userRep, _) =>  StreamBuilder<List<QuerySnapshot>>(
      stream: CombineLatestStream([firestore.collection("Drives")
          .where('TimeStamp', isLessThanOrEqualTo: Timestamp.fromDate(widget.toTime),isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromTime))
          .snapshots(),
        firestore
          .collection("Notifications")
          .doc(userRep.user.email).collection("Pending").snapshots(),
        FirebaseFirestore.instance
            .collection('Profiles')
            .snapshots(),
      ],(vals) => [vals[0],vals[1],vals[2]]), // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<List<QuerySnapshot>> snapshot){
        if(snapshot.hasData) {
          filter(snapshot.data, userRep);
          if(liftList.length>0){
          return  ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.only(left: defaultSpacewidth*0.4, right: defaultSpacewidth*0.4, bottom: defaultSpacewidth*0.4,top:defaultSpacewidth*0.4 ),
            itemCount: liftList.length,
            separatorBuilder: (BuildContext context, int index) => Divider(thickness: 4,),
            itemBuilder: (BuildContext context, int index) {
              return _buildTile(liftList[index]);
            },
          );}else{
            return Center(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.update, size: 30),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Text("No lifts found",style: TextStyle(fontSize: 30, color: Colors.black))
                ]));
                }
          
        }else if(snapshot.hasError){
          return Center(child: Text("Error loading the lifts", style: TextStyle(fontSize: 30),),);
        }else{
          return Center(child: CircularProgressIndicator(),);
        }
      }
    ));


    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Search Results",style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              } )
        ],
      ),

      body:Container(
          decoration: pageContainerDecoration,
          margin: pageContainerMargin,
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          child: Container(
              padding: const EdgeInsets.only(bottom: 6.0),
            child: Column(

              children: [sortAndSearch, Expanded(child:_futureBuildLists)],
            ),
          )),
      backgroundColor: mainColor,
    );
  }

///build the tile of the lift
  Widget _buildTile(MyLift lift) {
    return InkWell(
              onTap: () async {
                liftRes temp =  liftRes(
                  fromTime: widget.fromTime,
                  toTime: widget.toTime,
                  indexDist: 2,
                  startAddress: widget.startAddress,
                  destAddress: widget.destAddress,
                  bigTrunk: widget.bigTrunk,
                  backSeat: widget.backSeat,);
                await Navigator.of(context).push(new MaterialPageRoute<Null>(
                    builder: (BuildContext context) {
                      return LiftInfoPage(lift: lift, resLift:temp);
                    },
                    fullscreenDialog: true
                ));
                setState(() {

                });
              },
                child: Container(
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
                                    email: lift.driver, fromProfile: false,);
                                },
                                fullscreenDialog: true
                            ));
                        setState(() {

                        });
                      },
                     // child: Hero(
                       // tag: 'dash',
                          child: /* Material(
                            child: mapi[lift.driver].data()["pic"] != null
                                ? InkWell(
                              onTap: () async {
                                FocusScope.of(context).unfocus();
                                await Navigator.of(context)
                                    .push(MaterialPageRoute<liftRes>(
                                    builder: (BuildContext context) {
                                      return ProfilePage(
                                        email:lift.driver,
                                        fromProfile: false,
                                      );
                                    },
                                    fullscreenDialog: true));
                              },
                              child:
                              CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  color: mainColor,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.0,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        secondColor),
                                  ),
                                  width: 50.0,
                                  height: 50.0,
                                  padding: EdgeInsets.all(15.0),
                                ),
                                color: secondColor,
                                colorBlendMode: BlendMode.dstOver ,
                                imageUrl:   mapi[lift.driver].data()["pic"],
                                width: 50.0,
                                height: 50.0,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Icon(
                              Icons.account_circle,
                              size: 50.0,
                              color: secondColor,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(25.0)),
                            clipBehavior: Clip.hardEdge,
                          )),*/
                          Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.016, top: MediaQuery
                              .of(context)
                              .size
                              .height * 0.016),
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
                            color: secondColor,
                            image: DecorationImage(fit: BoxFit.fill,
                                image: NetworkImage(mapi[lift.driver].data()["pic"])),
                          ))),
                  Container(
                      margin: EdgeInsets.only(
                          left: MediaQuery
                              .of(context)
                              .size
                              .width * 0.016, top: MediaQuery
                          .of(context)
                          .size
                          .height * 0.016),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          infoText(mapi[lift.driver].data()["firstName"]+ " " +mapi[lift.driver].data()["lastName"]),
                          placesText(lift.startCity, lift.destCity),
                          allInfoText(lift.time, lift.dist/1000, lift.price,
                              lift.numberOfSeats, lift.passengers.length),
                        ],
                      )),
                  Spacer(),
                  Expanded(child: Container(child: Icon(Icons.arrow_forward_ios_outlined),)),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.06)
                ],
              ),
            ));
  }

///all the info in the lift tile
  Widget allInfoText(DateTime time,double dist, int price,int avaliable,int taken){
   return Container(
       child:Row(
     children: [
       Icon(Icons.timer),
       Text(DateFormat('kk:mm').format(time)),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
       SizedBox(width: MediaQuery.of(context).size.height * 0.005),
       Text(dist.toStringAsFixed(1)+"km"),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Icon(Icons.person),
       Text(taken.toString()+"/"+avaliable.toString()),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Container(child:Image.asset("assets/images/shekel.png",scale: 0.9)),
       SizedBox(width: MediaQuery.of(context).size.height * 0.003),
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
        child: Text(from+" \u{2192} "+to,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
           // overflow: TextOverflow.ellipsis,
          maxLines: null,
        )
    );
  }
}