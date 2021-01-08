import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/pages/LocationSearch.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _key = GlobalKey<ScaffoldState>();
  final GlobalKey<PopupMenuButtonState> _homeMenuKey = GlobalKey();
  final GlobalKey<PopupMenuButtonState> _workMenuKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection("Favorites").doc(userRep.user.email).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Map<String,Map<String,dynamic>> snapshotMap = Map<String,Map<String,dynamic>>.from(snapshot.data.data());
              return Scaffold(
                  backgroundColor: mainColor,
                  appBar: AppBar(
                    elevation: 0,
                    title: Text(
                      "Favorites",
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      IconButton(
                          icon: StreamBuilder(
                              stream: firestore.collection("Notifications").doc(
                                  userRep.user?.email).collection(
                                  "UserNotifications").snapshots(),
                              // a previously-obtained Future<String> or null
                              builder: (BuildContext context, snapshot) {
                                if (snapshot.hasData) {
                                  //QuerySnapshot values = snapshot.data;
                                  //builder: (_, snapshot) =>
                                  return BadgeIcon(
                                    icon: Icon(Icons.notifications, size: 25),
                                    badgeCount: snapshot.data.size,
                                  );
                                }
                                else {
                                  return BadgeIcon(
                                    icon: Icon(Icons.notifications, size: 25),
                                    badgeCount: 0,
                                  );
                                }
                              }
                          ),
                          onPressed: () =>
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          NotificationsPage()))
                      )

                      //     IconButton(
                      //         icon: Icon(Icons.notifications),
                      //         onPressed:() => Navigator.pushReplacement(
                      // context,
                      // MaterialPageRoute(
                      //     builder: (context) => NotificationsPage())))
                    ],
                  ),
                  drawer: techDrawer(
                      userRep, context, DrawerSections.favorites),
                  body: Container(
                    decoration: pageContainerDecoration,
                    margin: pageContainerMargin,
                    child: ListView(children: [
                      ListTile(onTap: () async {
                        if(_homeMenuKey.currentState != null){
                          _homeMenuKey.currentState.showButtonMenu();
                        }else{
                          var returnResult = await Navigator.of(context)
                              .push(MaterialPageRoute<LocationsResult>(
                              builder: (BuildContext context) {
                                return LocationSearch(
                                  showAddStops: false, fromFavorites: true,);
                              },
                              fullscreenDialog: true));
                          if (returnResult != null) {
                            await firestore.collection("Favorites").doc(userRep.user.email).update({"Home" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}});
                          }
                        }
                      },title: Text("Home"),
                        subtitle: Text((!snapshotMap.containsKey("Home") ? "Click edit to set home address" : snapshotMap["Home"]["Address"])),
                        leading: Icon(Icons.home, size: 30,
                          color: secondColor,),
                        trailing: snapshotMap.containsKey("Home") ? PopupMenuButton(key: _homeMenuKey,icon: Icon(Icons.more_vert),
                            itemBuilder: (BuildContext context) => [PopupMenuItem(value: "Edit location",child: Row(children: [Icon(Icons.edit_location),Text("Edit address")]),),PopupMenuItem(value: "Delete",child: Row(children: [Icon(Icons.delete),Text("Delete")]))],
                            onSelected: (value2) async {
                              if(value2 == "Delete"){
                                snapshotMap.remove("Home");
                                await firestore.collection("Favorites").doc(userRep.user.email).set(snapshotMap);
                              } else if (value2 == "Edit location") {
                                var returnResult = await Navigator.of(context)
                                    .push(MaterialPageRoute<LocationsResult>(
                                    builder: (BuildContext context) {
                                      return LocationSearch(
                                        showAddStops: false, fromFavorites: true,);
                                    },
                                    fullscreenDialog: true));
                                if (returnResult != null) {
                                  await firestore.collection("Favorites").doc(
                                      userRep.user.email).update({
                                    "Home": {
                                      "Address": returnResult.fromAddress
                                          .addressLine,
                                      "Point": GeoPoint(
                                          returnResult.fromAddress.coordinates
                                              .latitude,
                                          returnResult.fromAddress.coordinates
                                              .longitude)
                                    }
                                  });
                                }
                              }
                            }
                        ) : IconButton(icon: Icon(Icons.edit),
                          onPressed: () async {
                            var returnResult = await Navigator.of(context)
                                .push(MaterialPageRoute<LocationsResult>(
                                builder: (BuildContext context) {
                                  return LocationSearch(
                                    showAddStops: false, fromFavorites: true,);
                                },
                                fullscreenDialog: true));
                            if (returnResult != null) {
                              await firestore.collection("Favorites").doc(userRep.user.email).update({"Home" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}});
                            }
                          },

                        ),),
                      Divider(),
                      ListTile(onTap: () async {
                        if(_workMenuKey.currentState != null){
                          _workMenuKey.currentState.showButtonMenu();
                        }else{
                          var returnResult = await Navigator.of(context)
                              .push(MaterialPageRoute<LocationsResult>(
                              builder: (BuildContext context) {
                                return LocationSearch(
                                  showAddStops: false, fromFavorites: true,);
                              },
                              fullscreenDialog: true));
                          if (returnResult != null) {
                            await firestore.collection("Favorites").doc(userRep.user.email).update({"Work" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}});
                          }
                        }
                      },title: Text("Work"),
                        subtitle: Text((!snapshotMap.containsKey("Work") ? "Click edit to set work address" : snapshotMap["Work"]["Address"])),
                        leading: Icon(Icons.work, size: 30,
                          color: secondColor,),
                        trailing: snapshotMap.containsKey("Work") ? PopupMenuButton(key: _workMenuKey,icon: Icon(Icons.more_vert),
                            itemBuilder: (BuildContext context) => [PopupMenuItem(value: "Edit location",child: Row(children: [Icon(Icons.edit_location),Text("Edit address")]),),PopupMenuItem(value: "Delete",child: Row(children: [Icon(Icons.delete),Text("Delete")]))],
                            onSelected: (value2) async {
                              if(value2 == "Delete"){
                                snapshotMap.remove("Work");
                                await firestore.collection("Favorites").doc(userRep.user.email).set(snapshotMap);
                              } else if (value2 == "Edit location") {
                                var returnResult = await Navigator.of(context)
                                    .push(MaterialPageRoute<LocationsResult>(
                                    builder: (BuildContext context) {
                                      return LocationSearch(
                                        showAddStops: false, fromFavorites: true,);
                                    },
                                    fullscreenDialog: true));
                                if (returnResult != null) {
                                  await firestore.collection("Favorites").doc(
                                      userRep.user.email).update({
                                    "Work": {
                                      "Address": returnResult.fromAddress
                                          .addressLine,
                                      "Point": GeoPoint(
                                          returnResult.fromAddress.coordinates
                                              .latitude,
                                          returnResult.fromAddress.coordinates
                                              .longitude)
                                    }
                                  });
                                }
                              }
                            }
                        ) : IconButton(icon: Icon(Icons.edit),
                          onPressed: () async {
                            var returnResult = await Navigator.of(context)
                                .push(MaterialPageRoute<LocationsResult>(
                                builder: (BuildContext context) {
                                  return LocationSearch(
                                    showAddStops: false, fromFavorites: true,);
                                },
                                fullscreenDialog: true));
                            if (returnResult != null) {
                              await firestore.collection("Favorites").doc(userRep.user.email).update({"Work" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}});
                            }
                          },),),
                    ],),
                  ));
            }else if(snapshot.hasError){
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.error),
                    Text("Error loading favorites from cloud")
                  ]);
            }else{
              return Scaffold(
                key: _key,
                  backgroundColor: mainColor,
                  appBar: AppBar(
                    elevation: 0,
                    title: Text(
                      "Favorites",
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      IconButton(
                          icon: StreamBuilder(
                              stream: firestore.collection("Notifications").doc(
                                  userRep.user?.email).collection(
                                  "UserNotifications").snapshots(),
                              // a previously-obtained Future<String> or null
                              builder: (BuildContext context, snapshot) {
                                if (snapshot.hasData) {
                                  //QuerySnapshot values = snapshot.data;
                                  //builder: (_, snapshot) =>
                                  return BadgeIcon(
                                    icon: Icon(Icons.notifications, size: 25),
                                    badgeCount: snapshot.data.size,
                                  );
                                }
                                else {
                                  return BadgeIcon(
                                    icon: Icon(Icons.notifications, size: 25),
                                    badgeCount: 0,
                                  );
                                }
                              }
                          ),
                          onPressed: () =>
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          NotificationsPage()))
                      )

                      //     IconButton(
                      //         icon: Icon(Icons.notifications),
                      //         onPressed:() => Navigator.pushReplacement(
                      // context,
                      // MaterialPageRoute(
                      //     builder: (context) => NotificationsPage())))
                    ],
                  ),
                  drawer: techDrawer(
                      userRep, context, DrawerSections.favorites),
                  body: Container(
                    decoration: pageContainerDecoration,
                    margin: pageContainerMargin,
                    child: Center(child: CircularProgressIndicator(),),
                  ));
            }
          });
    }
    );
  }
}
