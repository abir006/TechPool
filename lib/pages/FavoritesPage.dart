import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/main.dart';
import 'package:tech_pool/pages/LocationSearch.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';

import 'ChatPage.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _key = GlobalKey<ScaffoldState>();
  final GlobalKey<PopupMenuButtonState> _homeMenuKey = GlobalKey();
  final GlobalKey<PopupMenuButtonState> _workMenuKey = GlobalKey();
  final GlobalKey<PopupMenuButtonState> _universityMenuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    chatTalkPage = false;
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection("Favorites").doc(userRep.user.email).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Widget> favorites = [];
              Map<String,Map<String,dynamic>> snapshotMap;
              if(snapshot.data.data() == null){
                snapshotMap = {};
              }else {
                snapshotMap = Map<String,
                    Map<String, dynamic>>.from(snapshot.data.data());
              }
              snapshotMap.forEach((key, value) {
                final GlobalKey<PopupMenuButtonState> _menuKey = GlobalKey();
                if(key != "Home" && key != "Work" && key != "University"){
                  favorites.add(Container( decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                        spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                    border: Border.all(color: secondColor, width: 0.65),
                    borderRadius: BorderRadius.circular(12.0),
                  ),    margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: ListTile(onTap: () => _menuKey.currentState.showButtonMenu(),title: Text(key),
                      subtitle: Text(value["Address"]),
                      leading: Icon(Icons.favorite, size: 30,
                        color: secondColor,),
                      trailing:  PopupMenuButton(key: _menuKey,icon: Icon(Icons.more_vert),
                          itemBuilder: (BuildContext context) => [PopupMenuItem(value: "Edit name",child: Row(children: [Icon(Icons.edit),Text("Edit name")],)),PopupMenuItem(value: "Edit location",child: Row(children: [Icon(Icons.edit_location),Text("Edit address")]),),PopupMenuItem(value: "Delete",child: Row(children: [Icon(Icons.delete),Text("Delete")]))],
                          onSelected: (value2) async {
                            if(value2 == "Delete"){
                              snapshotMap.remove(key);
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
                                  key: {
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
                            }else if (value2 == "Edit name"){
                              showDialog(context: context,builder: (_) {
                                var _formKey = GlobalKey<FormState>();
                                var _controller = TextEditingController();
                                _controller.text = key;
                                return AlertDialog(shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                                  title: Text("Edit name"),content: Form(key: _formKey,child: TextFormField(decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),labelText: "Name"),controller: _controller,validator: (val) {
                                    if (val.isEmpty) {return 'Please enter name';} else if(val.toLowerCase() == "home" || val.toLowerCase() == "work" || val.toLowerCase() == "university"){return 'Cant select this name';}else if(snapshotMap.containsKey(val)) {return 'Name already exists';}return null;
                                  },)),
                                  actions: [
                                    TextButton(onPressed: () =>
                                        Navigator.pop(context),
                                        child: Text("Discard")),
                                    TextButton(onPressed: () async {
                                      if(_formKey.currentState.validate()) {
                                        snapshotMap.remove(key);
                                        snapshotMap[_controller.text] = value;
                                        await firestore.collection("Favorites")
                                            .doc(userRep.user.email)
                                            .set(snapshotMap);
                                        Navigator.pop(context);
                                      }
                                    },
                                        child: Text("Confirm"))
                                  ],
                                );
                              });
                            }
                          }
                      )
                      /*IconButton(icon: Icon(Icons.more_vert),
                            onPressed: () async {
                              var returnResult = await Navigator.of(context)
                                  .push(MaterialPageRoute<LocationsResult>(
                                  builder: (BuildContext context) {
                                    return LocationSearch(
                                      showAddStops: false, fromFavorites: true,);
                                  },
                                  fullscreenDialog: true));
                              if (returnResult != null) {
                                await firestore.collection("Favorites").doc(userRep.user.email).update({key : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}});
                              }
                            },

                          )*/,),
                  )
                  );
                  //favorites.add(Divider(thickness: 1,indent: 10,endIndent: 10,color: mainColor,));
                }
              });
              return Scaffold(
                  floatingActionButton: FloatingActionButton(heroTag: "add",
                    backgroundColor: Colors.black,
                    child: Icon(Icons.add, size: 30),
                    onPressed: () {
                      showDialog(context: context,builder: (_) {
                        LocationsResult returnResult;
                        final _formKey = GlobalKey<FormState>();
                        var _controller = TextEditingController();
                        return Scaffold(
                            key: _key,
                            backgroundColor: Colors.transparent,
                            body: Builder(
                                builder: (context) => AlertDialog(shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                                  title: Text("New favorite"),content: Form(key: _formKey,child: Wrap(runSpacing: 10,alignment: WrapAlignment.center,
                                    children: [
                                      TextFormField(decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),labelText: "Name"),controller: _controller,validator: (val) {
                                        if (val.isEmpty) {return 'Please enter name';} else if(val.toLowerCase() == "home" || val.toLowerCase() == "work" || val.toLowerCase() == "university"){return 'Cant select this name';}else if(snapshotMap.containsKey(val)) {return 'Name already exists';}return null;
                                      },),
                                      RaisedButton.icon(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                            side: BorderSide(color: Colors.black)),
                                        label: Text("Choose location"),
                                        icon: Icon(Icons.map),
                                        onPressed: () async {
                                          returnResult = await Navigator.of(context)
                                              .push(MaterialPageRoute<LocationsResult>(
                                              builder: (BuildContext context) {
                                                return LocationSearch(showAddStops: false,fromFavorites: true,);
                                              },
                                              fullscreenDialog: true));
                                        },
                                      )
                                    ],
                                  )),
                                  actions: [
                                    TextButton(onPressed: () =>
                                        Navigator.pop(context),
                                        child: Text("Discard")),
                                    TextButton(onPressed: () async {
                                      if(_formKey.currentState.validate()) {
                                        if (returnResult == null) {
                                          _key.currentState.showSnackBar(SnackBar(
                                              content: Text("Please select location")));
                                        } else {
                                          await firestore.collection("Favorites")
                                              .doc(userRep.user.email)
                                              .set({
                                            _controller.text: {
                                              "Address": returnResult.fromAddress.addressLine,
                                              "Point": GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)
                                            }
                                          },SetOptions(merge: true));
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                        child: Text("Confirm"))
                                  ],
                                )));
                      });
                    },
                  ),
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
                                  "UserNotifications").where("read", isEqualTo: "false").snapshots(),
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
                      ),  IconButton(
                          icon: StreamBuilder(
                              stream: firestore.collection("ChatFriends").doc(userRep.user?.email).collection("UnRead").snapshots(), // a previously-obtained Future<String> or null
                              builder: (BuildContext context, snapshot) {
                                if (snapshot.hasData) {
                                  //QuerySnapshot values = snapshot.data;
                                  //builder: (_, snapshot) =>

                                  return BadgeIcon(
                                    icon: Icon(Icons.message_outlined, size: 25),
                                    badgeCount: snapshot.data.size,
                                  );
                                }
                                else{
                                  return BadgeIcon(
                                    icon: Icon(Icons.message_outlined, size: 25),
                                    badgeCount: 0,
                                  );
                                }
                              }
                          ),
                          onPressed: () async {
                            QuerySnapshot q2 = await  FirebaseFirestore.instance.collection("ChatFriends").doc(userRep.user.email)
                                .collection("UnRead").get();

                            FirebaseFirestore.instance.runTransaction((transaction) async {
                              q2.docs.forEach((element) {
                                transaction.delete(element.reference);
                              });
                            });
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatPage(currentUserId: userRep.user.email,fromNotification: false)));}
                      )
                    ],
                  ),
                  drawer: techDrawer(
                      userRep, context, DrawerSections.favorites),
                  body: Container(
                    decoration: pageContainerDecoration,
                    margin: pageContainerMargin,
                    child: ListView(children: [
                      Container( decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                            spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                        border: Border.all(color: secondColor, width: 0.65),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                        margin:
                        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(onTap: () async {
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
                              await firestore.collection("Favorites").doc(userRep.user.email).set({"Home" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}},SetOptions(merge: true));
                            }
                          }
                        },title: Text("Home"),
                          subtitle: Text((!snapshotMap.containsKey("Home") ? "Click to set home address" : snapshotMap["Home"]["Address"])),
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
                                await firestore.collection("Favorites").doc(userRep.user.email).set({"Home" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}},SetOptions(merge: true));
                              }
                            },

                          ),),
                      ),
                     // Divider(thickness: 1,indent: 10,endIndent: 10,color: mainColor,),
                      Container( decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                            spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                        border: Border.all(color: secondColor, width: 0.65),
                        borderRadius: BorderRadius.circular(12.0),
                      ),    margin:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(onTap: () async {
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
                              await firestore.collection("Favorites").doc(userRep.user.email).set({"Work" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}},SetOptions(merge: true));
                            }
                          }
                        },title: Text("Work"),
                          subtitle: Text((!snapshotMap.containsKey("Work") ? "Click to set work address" : snapshotMap["Work"]["Address"])),
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
                                await firestore.collection("Favorites").doc(userRep.user.email).set({"Work" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}},SetOptions(merge: true));
                              }
                            },),),
                      ),
                     // Divider(thickness: 1,indent: 10,endIndent: 10,color: mainColor,),
                      Container( decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                            spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                        border: Border.all(color: secondColor, width: 0.65),
                        borderRadius: BorderRadius.circular(12.0),
                      ),    margin:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(onTap: () async {
                          if(_universityMenuKey.currentState != null){
                            _universityMenuKey.currentState.showButtonMenu();
                          }else{
                            var returnResult = await Navigator.of(context)
                                .push(MaterialPageRoute<LocationsResult>(
                                builder: (BuildContext context) {
                                  return LocationSearch(
                                    showAddStops: false, fromFavorites: true,);
                                },
                                fullscreenDialog: true));
                            if (returnResult != null) {
                              await firestore.collection("Favorites").doc(userRep.user.email).set({"University" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}},SetOptions(merge: true));
                            }
                          }
                        },title: Text("University"),
                          subtitle: Text((!snapshotMap.containsKey("University") ? "Click to set university address" : snapshotMap["University"]["Address"])),
                          leading: Icon(Icons.school, size: 30,
                            color: secondColor,),
                          trailing: snapshotMap.containsKey("University") ? PopupMenuButton(key: _universityMenuKey,icon: Icon(Icons.more_vert),
                              itemBuilder: (BuildContext context) => [PopupMenuItem(value: "Edit location",child: Row(children: [Icon(Icons.edit_location),Text("Edit address")]),),PopupMenuItem(value: "Delete",child: Row(children: [Icon(Icons.delete),Text("Delete")]))],
                              onSelected: (value2) async {
                                if(value2 == "Delete"){
                                  snapshotMap.remove("University");
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
                                      "University": {
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
                                await firestore.collection("Favorites").doc(userRep.user.email).set({"University" : {"Address" : returnResult.fromAddress.addressLine,"Point" : GeoPoint(returnResult.fromAddress.coordinates.latitude,returnResult.fromAddress.coordinates.longitude)}},SetOptions(merge: true));
                              }
                            },

                          ),),
                      ),
                    //  Divider(thickness: 1,indent: 10,endIndent: 10,color: mainColor,),
                      ...favorites
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
                  floatingActionButton: FloatingActionButton(heroTag: "add",
                    backgroundColor: Colors.black,
                    child: Icon(Icons.add, size: 30),
                    onPressed: () {},
                  ),
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
                                  "UserNotifications").where("read", isEqualTo: "false").snapshots(),
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
