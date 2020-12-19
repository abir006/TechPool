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

  void filter(QuerySnapshot value,UserRepository userRep){
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
}

  /*Stream<QuerySnapshot> initList3(UserRepository userRep) async* {
    return firestore.collection("Drives")
        .where('TimeStamp', isLessThanOrEqualTo: Timestamp.fromDate(widget.toTime),isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromTime))
        .snapshots();
  }*/

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
    //Future<String> _calculation = initList();
    final searchLift = Container(
      decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.only(topLeft:Radius.circular(20.0),topRight:Radius.circular(20.0) ),),
        child: FlatButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.white)),
            icon: Icon(Icons.edit_outlined, color: Colors.white),
            label: Text("Edit Search",
                style: TextStyle(color: Colors.white, fontSize: 17)),
            onPressed: () async {
            liftRes    returnResult = await Navigator.of(context).push(
                    MaterialPageRoute<liftRes>(
                        builder: (BuildContext context) {
                          return SearchLiftPage(currentdate: widget.fromTime, fromtime: widget.fromTime,totime: widget.toTime,indexDis: widget.indexDist , startAd: widget.startAddress, destAd:widget.destAddress, bigTrunk: widget.bigTrunk, backSeat: widget.backSeat,popOrNot: true,);
                        },
                        fullscreenDialog: true
                    ));
                setState(() {
                  if (returnResult != null) {
                    widget.startAddress = returnResult.startAddress;
                    widget.startAddress = returnResult.destAddress;
                    widget.fromTime = returnResult.fromTime;
                    widget.toTime = returnResult.toTime;
                    widget.indexDist = returnResult.indexDist;
                    widget.bigTrunk = returnResult.bigTrunk;
                    widget.backSeat = returnResult.backSeat;
                    widget.indexDist = returnResult.indexDist;
                  }
                });
            }));

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
          searchLift,
          SizedBox(width: defaultSpacewidth*0.2,)
        ])));


    final _futureBuildLists = Consumer<UserRepository>(
      builder: (context, userRep, _) =>  StreamBuilder<QuerySnapshot>(
      stream:firestore.collection("Drives")
          .where('TimeStamp', isLessThanOrEqualTo: Timestamp.fromDate(widget.toTime),isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromTime))
          .snapshots(), // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
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
            return Center(child: Text("No lifts found", style: TextStyle(fontSize: 30),),);
          };
        }else{
          return Center(child: CircularProgressIndicator(),);
        }
      }
    ));


    return Scaffold(
      appBar: AppBar(
        title: Text("Search Results",style: TextStyle(color: Colors.white),),
      ),
      body:Container(
          decoration: pageContainerDecoration,
          margin: pageContainerMargin,
          //padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth),
          child: Column(
            children: [sortAndSearch, Expanded(child:_futureBuildLists)],
          )),
      backgroundColor: mainColor,
    );
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
    return FutureBuilder<List<String>>(
        future: initNames(lift.driver),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
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
                          child: Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.016, top: MediaQuery
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
                            color: Colors.teal,
                            image: DecorationImage(fit: BoxFit.fill,
                                image: NetworkImage(snapshot.data[0])),

                          ))),
                  Container(
                      margin: EdgeInsets.only(
                          left: MediaQuery
                              .of(context)
                              .size
                              .height * 0.016, top: MediaQuery
                          .of(context)
                          .size
                          .height * 0.016),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          infoText(snapshot.data[1]),
                          placesText(lift.startCity, lift.destCity),
                          allInfoText(lift.time, lift.dist ~/ 1000, lift.price,
                              lift.numberOfSeats, lift.passengers.length),
                        ],
                      )),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios_outlined),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .height * 0.016,)
                ],
              ),
            ));
          }else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
  Widget allInfoText(DateTime time,int dist, int price,int avaliable,int taken){
   return Container(
       child:Row(
     children: [
       Icon(Icons.timer),
       Text(DateFormat('kk:mm').format(time)),
       SizedBox(width: MediaQuery.of(context).size.height * 0.01),
       Container(child:Image.asset("assets/images/tl-.png",scale: 0.9)),
       SizedBox(width: MediaQuery.of(context).size.height * 0.005),
       Text(dist.toString()+"km"),
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
        child: Text(from+" -> "+to,
          style: TextStyle(fontSize: fontTextsSize, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          maxLines: 2,
        )
    );
  }
}
/*
Future<String> initPic(String id) async {
      return imageUrl = await FirebaseStorage.instance
      .ref('uploads')
     .child(id)
     .getDownloadURL();
  }
  Future<DocumentSnapshot> initSnapshot(String id) async {
    try {
      return docProfile = await firestore.collection("Profiles").doc(id).get();
    }catch(e){
      print(e);
      return null;
    }
  }
  Future<bool> initAll() async {
     q  = await firestore.collection("Drives").where('TimeStamp', isLessThanOrEqualTo: Timestamp.fromDate(widget.toTime),isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromTime)).get();
     return true;
  }
  Future<bool> initProfiles() async{
    List<MyLift> tempLift =  <MyLift>[];
    DocumentSnapshot docProfile;
    String imageUrl ="";
    tempLift.clear();
    for(int i=0;i<liftList.length;i++) {
      imageUrl ="";
      docProfile = null;
      imageUrl = await FirebaseStorage.instance
          .ref('uploads')
          .child(liftList[i].driver)
          .getDownloadURL();
      //docProfile = await firestore.collection("Profiles").doc(liftList[i].driver).get();
    //  Future<bool> p3 = initSnapshot(liftList[i].driver);
     // await p3;
    //  Future<bool> p4 = initPic(liftList[i].driver);
     //  await p4;
     // var futures = List<Future>();

     // futures.add(initSnapshot(liftList[i].driver));
     // futures.add(initPic(liftList[i].driver));
     // Future.wait(futures);
   //   liftList[i].driverName = docProfile.data()["firstName"]+" "+docProfile.data()["lastName"];
   //   liftList[i].driverName = (docProfile.data()["firstName"]+" "+docProfile.data()["lastName"]);
      liftList[i].imageUrl = imageUrl;
      tempLift.add(liftList[i]);
    }
    liftList.clear();
    liftList.addAll(tempLift);
    tempLift.clear();

    for(int i=0;i<liftList.length;i++) {
     docProfile = await firestore.collection("Profiles").doc(liftList[i].driver).get();
      //Future<bool> p3 = initSnapshot(liftList[i].driver);
      //await p3;
      liftList[i].driverName = docProfile.data()["firstName"]+" "+docProfile.data()["lastName"];
      liftList[i].driverName = (docProfile.data()["firstName"]+" "+docProfile.data()["lastName"]);
      tempLift.add(liftList[i]);
    }
    liftList.clear();
    liftList.addAll(tempLift);
    return true;
  }
  
  
  Future<String> initList() async {
    Future<bool> p = initAll();
    await p;
      try {
        liftList.clear();
        //q  = await firestore.collection("Drives").where('TimeStamp', isLessThanOrEqualTo: Timestamp.fromDate(widget.toTime),isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromTime)).get();
       // var futures2 = List<Future>();
      //  futures2.add(initAll());
      //  Future.wait(futures2);
        q.docs.forEach(
                (element) async {
              MyLift docLift = new MyLift(
                  "driver", "destAddress", "stopAddress", 5);
              element.data().forEach((key, value) {
                if (value != null) {
                  docLift.setProperty(key, value);
                }
              });
          //     docLift.imageUrl = await initPic(docLift.driver);
               /*
               await FirebaseStorage.instance
                .ref('uploads')
               .child(docLift.driver)
               .getDownloadURL();*/

        //    DocumentSnapshot q3 = await initSnapshot(docLift.driver);
           // await firestore.collection("Profiles").doc(docLift.driver).get();
          //  docLift.driverName = "0";
       //     docLift.driverName = q3.data()["firstName"] + " " + q3.data()["lastName"];

              /*   DocumentSnapshot q =
              await firestore.collection("Profiles").doc(docLift.driver).get();
              docLift.driverName = "0";
               docLift.driverName =
                   q2.docs.asMap()[docLift.driver][docLift.driver]["firstName"] + " " +    q2.docs.asMap()["lastName"];*/
              docLift.liftId = element.id;
              liftList.add(docLift);
            });
      } catch (e) {
        print(e);
      }
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
        double distToStart = clacDis(element.startPoint, startPointing);
        double distToEnd = clacDis(element.destPoint, destPointing);
        element.stops.forEach((key) {
          (key as Map).forEach((key, value) {
            if(key=="stopPoint") {
              GeoPoint pointStop = value as GeoPoint;
              distToStart = min(distToStart, clacDis(pointStop, startPointing));
              distToEnd = min(distToEnd, clacDis(pointStop, destPointing));
            }
          });
        });
        element.dist = (distToStart + distToEnd).toInt();
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
/*
    List<MyLift> tempLift =  <MyLift>[];
    liftList.forEach((element) async {
      DocumentSnapshot q =
      await firestore.collection("Profiles").doc(element.driver).get();
      element.driverName = q.data()["firstName"]+" "+q.data()["lastName"];
       // element.driverName ="0";
      element.driverName = (q.data()["firstName"]+" "+q.data()["lastName"]);
      tempLift.add(element);
    });
    liftList=tempLift;*/
      if (_currsSearchDrop == "Time") {
        liftList.sort(timeComparator);
      } else {
        liftList.sort(distComparator);
      }
    await Future.wait(liftList.map((e) async {
        DocumentSnapshot q =  await firestore.collection("Profiles").doc(e.driver).get();
        e.driverName = q.data()["firstName"]+" "+q.data()["lastName"];
        return e;
      }));

    await Future.wait(liftList.map((e) async {
     e.imageUrl = await FirebaseStorage.instance
          .ref('uploads')
          .child(e.driver)
          .getDownloadURL();
      return e;
    }));
     // var futures = List<Future>();
     // Future<bool> p2 = initProfiles();
     // await p2;
     // futures.add(initFire());
      //Future.wait(futures);
      return "finish";
  }
 */




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
  
 final _fbuildTiles = ListView.separated(
      shrinkWrap: true,
      itemCount: liftList.length,
      separatorBuilder: (BuildContext context, int index) => Divider(thickness: 4,),
      itemBuilder: (BuildContext context, int index) {
        return _buildTile(liftList[index]);
      },
    );
 */