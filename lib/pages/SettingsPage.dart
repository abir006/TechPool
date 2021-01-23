import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';

import 'ChatPage.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection("Profiles").doc(userRep.user.email).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Map<String,dynamic> snapshotMap;
              if(snapshot.data.data() == null){
                snapshotMap = {};
              }else {
                snapshotMap = Map<String,
                    dynamic>.from(snapshot.data.data());
              }
              print(snapshotMap);
              return Scaffold(
                  backgroundColor: mainColor,
                  appBar: AppBar(
                    elevation: 0,
                    title: Text(
                      "Settings",
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
                      userRep, context, DrawerSections.settings),
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
                    ),    margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child:SwitchListTile(title: Text("Receive hour before reminder notifications"),value: (snapshotMap["reminderNotif"] ?? true),onChanged: (current) async {
                        if(!current) {
                          await firestore.collection("Profiles").doc(
                              userRep.user.email).update(
                              {"reminderNotif": false});
                        }else{
                          await firestore.collection("Profiles").doc(
                              userRep.user.email).update(
                              {"reminderNotif": true});
                        }
                      },)),
                Container( decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                  border: Border.all(color: secondColor, width: 0.65),
                  borderRadius: BorderRadius.circular(12.0),
                ),    margin:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child:SwitchListTile(title: Text("Receive chat notifications"),value: (snapshotMap["chatNotif"] ?? true),onChanged: (current) async {
                        if(!current) {
                          await firestore.collection("Profiles").doc(
                              userRep.user.email).update(
                              {"chatNotif": false});
                        }else{
                          await firestore.collection("Profiles").doc(
                              userRep.user.email).update(
                              {"chatNotif": true});
                        }
                      },)),
                Container( decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
                      spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
                  border: Border.all(color: secondColor, width: 0.65),
                  borderRadius: BorderRadius.circular(12.0),
                ),    margin:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child:SwitchListTile(title: Text("Receive lift and drive notifications"),value: (snapshotMap["liftNotif"] ?? true),onChanged: (current) async {
                        if(!current) {
                          await firestore.collection("Profiles").doc(
                              userRep.user.email).update(
                              {"liftNotif": false});
                        }else{
                          await firestore.collection("Profiles").doc(
                              userRep.user.email).update(
                              {"liftNotif": true});
                        }
                      },)),
                    ],
                    ),
                  ));
            }else if(snapshot.hasError){
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.error),
                    Text("Error loading settings from cloud")
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
                      "Settings",
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
                      userRep, context, DrawerSections.settings),
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