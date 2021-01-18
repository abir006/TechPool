import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:badges/badges.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/pages/HomePage.dart';
import 'package:tech_pool/widgets/loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../appValidator.dart';
import 'ChatTalkPage.dart';
import 'NotificationsPage.dart';
import 'ProfilePage.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  ChatPage({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => ChatPageState(currentUserId: currentUserId);
}

class ChatPageState extends State<ChatPage> {
  ChatPageState({Key key, @required this.currentUserId});
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> filteredDocs = new List<DocumentSnapshot>();
  List<DocumentSnapshot> onlyDocs = new List<DocumentSnapshot>();
  String query = '';
  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TextEditingController _searchText;
  appValidator appValid;
  SlidableController slidableController;
  List<String> net = [];

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  void handleSlideAnimationChanged(Animation<double> slideAnimation) {
    setState(() {
    });
  }

  @override
  void initState() {
    super.initState();
    slidableController = SlidableController(
      onSlideAnimationChanged: handleSlideAnimationChanged,
    );
    _searchText = TextEditingController();
    registerNotification();
    //configLocalNotification();
    appValid = appValidator();
    appValid.checkConnection(context);
    appValid.checkVersion(context);
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      Platform.isAndroid
          ? showNotification(message['notification'])
          : showNotification(message['aps']['alert']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      FirebaseFirestore.instance
          .collection('Profiles')
          .doc(currentUserId)
          .update({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      // handleSignOut();
    } else {
      // Navigator.push(
      //   context, MaterialPageRoute(builder: (context) => ChatSettings()));
    }
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.dfa.flutterchatdemo'
          : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      'your channel description',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    print(message);
//    print(message['body'].toString());
//    print(json.encode(message));

    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));

//    await flutterLocalNotificationsPlugin.show(
//        0, 'plain title', 'plain body', platformChannelSpecifics,
//        payload: 'item x');
  }

  Future<bool> onBackPress() async {
    QuerySnapshot q2 = await FirebaseFirestore.instance
        .collection("ChatFriends")
        .doc(currentUserId)
        .collection("UnRead")
        .get();

    FirebaseFirestore.instance.runTransaction((transaction) async {
      q2.docs.forEach((element) {
        transaction.delete(element.reference);
      });
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    color: secondColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0))),
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    this.setState(() {
      isLoading = false;
    });

    // Navigator.of(context).pushAndRemoveUntil(
    //  MaterialPageRoute(builder: (context) => MyApp()),
    //    (Route<dynamic> route) => false);
  }

  List<DocumentSnapshot> onItemChanged(String value) {
    setState(() {
      query = _searchText.text;
    });
  }

  void filter(List<DocumentSnapshot> data, List<DocumentSnapshot> network) {
    filteredDocs = [];
    onlyDocs=[];
    onlyDocs.addAll(network);
    net = [];
    network.forEach((element) {
      net.add(element.id);
    });
    data.forEach((element) {
      String name = (element["firstName"] +
          element["lastName"].replaceAll(new RegExp(r"\s+\b|\b\s"), ""));
      String query2 = query.replaceAll(new RegExp(r"\s+\b|\b\s"), "");
      if (query != '') {
        if(name.toLowerCase().contains(query2.toLowerCase())) {
          filteredDocs.add(element);
        }
      } else {
        if (net.contains(element.id)) {
          filteredDocs.add(element);
        }
      }
    });
    if (query == '') {
      Comparator<DocumentSnapshot> timeComparator = (a, b) {
        if(a.data()['read']==true && b.data()['read']!=true){
          return 1;
        }
        if(a.data()['read']!=true && b.data()['read']==true){
          return -1;
        }
        return (int.parse(b.data()['timestamp']).compareTo(
            int.parse(a.data()['timestamp'])));
      };
      Comparator<DocumentSnapshot> networComp = (a, b) {
        return (net.indexOf(a.id).compareTo(net.indexOf(b.id)));
      };
      network.sort(timeComparator);
      net = [];
      network.forEach((element) {
        net.add(element.id);
      });
      filteredDocs.sort(networComp);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
      Consumer<UserRepository>(
      builder: (context, userRep, _) =>
          IconButton(
              icon: StreamBuilder(
                  stream: firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").where("read", isEqualTo: "false").snapshots(), // a previously-obtained Future<String> or null
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData) {
                      //QuerySnapshot values = snapshot.data;
                      //builder: (_, snapshot) =>
                      return BadgeIcon(
                        icon: Icon(Icons.notifications, size: 25),
                        badgeCount: snapshot.data.size,
                      );
                    }
                    else{
                      return BadgeIcon(
                        icon: Icon(Icons.notifications, size: 25),
                        badgeCount: 0,
                      );
                    }
                  }
              ),
              onPressed: () async {
      QuerySnapshot q2 = await FirebaseFirestore.instance
        .collection("ChatFriends")
        .doc(currentUserId)
        .collection("UnRead")
        .get();

    FirebaseFirestore.instance.runTransaction((transaction) async {
      q2.docs.forEach((element) {
        transaction.delete(element.reference);
      });
    });
                  Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationsPage()));}
          ),),
        ],
      ),
      drawer: Consumer<UserRepository>(builder: (context, auth, _) {
        return techDrawer(auth, context, DrawerSections.chats);
      }),
      body: WillPopScope(
        child: GestureDetector(
          onTap:() {
            FocusScope.of(context).requestFocus(new FocusNode());
            try{
            slidableController.activeState.close();}
          catch(e){}},
          child: Container(
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            child: Stack(
              children: <Widget>[
                // List
                Container(
                  child: StreamBuilder<List<QuerySnapshot>>(
                    stream: CombineLatestStream([
                      FirebaseFirestore.instance
                          .collection('ChatFriends')
                          .doc(currentUserId)
                          .collection('Network')
                          .snapshots(),
                      FirebaseFirestore.instance
                          .collection('Profiles')
                          .snapshots(),
                    ], (vals) => [vals[0], vals[1]]),
                    builder:
                        (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(secondColor),
                          ),
                        );
                      } else {
                        filter(snapshot.data[1].docs, snapshot.data[0].docs);
                        return Column(children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            child: TextField(
                              controller: _searchText,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search Here...',
                                suffixIcon: query != ''
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            query = '';
                                            _searchText.clear();
                                          });
                                        },
                                        icon: Icon(Icons.clear),
                                      )
                                    : Container(),
                              ),
                              onChanged: onItemChanged,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.all(10.0),
                              itemBuilder: (context, index) =>
                                  buildItem(context, filteredDocs[index]),
                              itemCount: filteredDocs.length,
                            ),
                          )
                        ]);
                      }
                    },
                  ),
                ),

                // Loading
                Positioned(
                  child: isLoading ? const Loading() : Container(),
                )
              ],
            ),
          ),
        ),
        onWillPop: onBackPress,
      ),
      backgroundColor: mainColor,
    );
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
      }).catchError((e) {
        return Future.error(e);
      });
    }).catchError((e) {
      return Future.error(e);
    });
    //  return null;
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    return Consumer<UserRepository>(builder: (context, userRep, _) {
              if (document.id.toString() == userRep.user.email) {
                return Container();
              } else {
                return Slidable(
                  enabled: net.contains(document.id),
                  controller: slidableController,
                  actionPane: SlidableScrollActionPane(),
                  actionExtentRatio: 0.25,
                  actions: <Widget>[
                SlideAction(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(0,1, 0, 12,),
                    child: FlatButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      child: Center(child:
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline,color: Colors.white,),
                          Text("Delete",style: TextStyle(color: Colors.white,fontSize: 10),)
                        ],
                      ),),
                      height: 100,
                   // caption: 'Delete',
                      color: Colors.red,
                    //  icon: Icons.delete_outline,
                      onPressed: () async {
                        FirebaseFirestore.instance.runTransaction((transaction) async {

                          QuerySnapshot q2 = await FirebaseFirestore.instance
                              .collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()).collection(document.id.toString())
                              .get();

                          Future.wait(q2.docs.map((element) {
                            transaction.delete(element.reference);
                            return Future( ()=>Null);
                          }));
                            transaction.delete(firestore.collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()));
                        });
                      //  FirebaseFirestore.instance.runTransaction((transaction) async {
                      //    transaction.delete(firestore.collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()));
                      //  });
                      },
                    ),
                  ),
                )],
                  child: Container(
                    child: FlatButton(
                      child: Row(
                        children: <Widget>[
                          Material(
                            child: document.data()['pic'] != null
                                ? InkWell(
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();
                                      await Navigator.of(context)
                                          .push(MaterialPageRoute<liftRes>(
                                              builder: (BuildContext context) {
                                                return ProfilePage(
                                                  email: document.id.toString(),
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
                                      imageUrl:   document.data()['pic'],
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
                          ),
                          Flexible(
                            child: Container(
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    child: Text(
                                      document.data()['firstName'] +
                                          " " +
                                          document.data()['lastName'],
                                      style: TextStyle(color: primaryColor),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    margin:
                                        EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                                  ),
                                /*   Container(
                                    child: Text(
                                      'About me: ${document.data()['aboutMe'] ??
                                          'Not available'}',
                                      style: TextStyle(color: primaryColor),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    margin: EdgeInsets.fromLTRB(
                                        10.0, 0.0, 0.0, 0.0),
                                  )*/
                                ],
                              ),
                              margin: EdgeInsets.only(left: 20.0),
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()).collection(document.id.toString()).orderBy('timestamp', descending: true).snapshots(), // a previously-obtained Future<String> or null
                  builder: (BuildContext context, snapshot) {
                        if(snapshot.hasData) {
                          return snapshot.data.docs.length!=0?
                          Column(
                            children: [
                              Badge(
                                elevation: 0,
                                shape: BadgeShape.circle,
                                padding: EdgeInsets.all(7),
                                badgeContent: Text(
                                  snapshot.data.docs.length.toString(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DateFormat('dd/MM').format(DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.data.docs[0]['timestamp']))).compareTo(DateFormat('dd/MM').format(DateTime.now())) == 0 ? Text( "Today "+DateFormat('kk:mm').format(DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.data.docs[0]['timestamp']))), style:TextStyle(fontSize: 12)):Text( DateFormat('dd/MM kk:mm').format(DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.data.docs[0]['timestamp']))), style:TextStyle(fontSize: 12))],
                          ):Container();
                        }
                      else{
                        return Container();
                      }
                  }
                        ),
                        /* Stack(children:[Container(
                              width: 30.0,
                              height: 30.0,
                              //padding: EdgeInsets.all(15.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondColor,
                              ),

                           // child: Badge(badgeContent: Text("2"),),
                          ),
                           Container(
                               width: 20.0,
                               height: 20.0,
                             //  padding: EdgeInsets.all(5.0),
                               child: Text("2")),])*/
                        ],
                      ),
                      onPressed: () async {
                        QuerySnapshot q2 = await FirebaseFirestore.instance
                            .collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()).collection(document.id.toString())
                            .get();

                        FirebaseFirestore.instance.runTransaction((transaction) async {
                          q2.docs.forEach((element) {
                            transaction.delete(element.reference);
                          });
                          try {
                            transaction.update(
                              FirebaseFirestore.instance.collection("ChatFriends")
                                  .doc(userRep.user?.email)
                                  .collection("Network")
                                  .doc(document.id.toString()),
                              {
                                'read': true
                              },
                            );
                          }catch(e){}

                        });
                        FocusScope.of(context).unfocus();
                        try{
                          slidableController.activeState.close();}
                          catch(e){}


                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatTalkPage(
                                      peerId: document.id,
                                      peerAvatar: document.data()['pic'],
                                      userId: currentUserId,
                                    )));
                      },
                      color: greyColor2,
                      padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                    margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
                  ),
                );
              }
    });
  }

  void dispose() {
    _searchText.dispose();
    appValid.listener.cancel();
    appValid.versionListener.cancel();
    super.dispose();
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}






/*Widget buildItem(BuildContext context, DocumentSnapshot document) {
    return Consumer<UserRepository>(builder: (context, userRep, _) {
      if (document.id.toString() == userRep.user.email) {
        return Container();
      }
        else{
                return Container(
                  child: FlatButton(
                    child: Row(
                      children: <Widget>[
                        Container(
                          child: FutureBuilder<List<String>>(
                    future: initNames(document.id.toString()),
                    // a previously-obtained Future<String> or null
                    builder:
                          (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                            if (snapshot.hasData) {
                              return Material(
                                  child: InkWell(
                                      onTap: () async {
                                        await Navigator.of(context)
                                            .push(MaterialPageRoute<liftRes>(
                                            builder: (BuildContext context) {
                                              return ProfilePage(
                                                email: document.id.toString(),
                                                fromProfile: false,
                                              );
                                            },
                                            fullscreenDialog: true));
                                      },
                                      child:
                                      CachedNetworkImage(
                                        placeholder: (context, url) =>
                                            Container(
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
                                        imageUrl: snapshot.data[0],
                                        width: 50.0,
                                        height: 50.0,
                                        fit: BoxFit.cover,
                                      )));
                            }
                            else {
                              return Material(child: Icon(
                                Icons.account_circle,
                                size: 50.0,
                                color: secondColor,
                              ),
                                borderRadius: BorderRadius.all(
                                    Radius.circular(25.0)),
                                clipBehavior: Clip.hardEdge,)
                            }
                          }),
                        ),
                        Flexible(
                          child: Container(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  child: Text(
                                    document.data()['firstName'] +
                                        " " +
                                        document.data()['lastName'],
                                    style: TextStyle(color: primaryColor),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  margin:
                                  EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                                ),
                                /* Container(
                                  child: Text(
                                    'About me: ${document.data()['aboutMe'] ??
                                        'Not available'}',
                                    style: TextStyle(color: primaryColor),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.fromLTRB(
                                      10.0, 0.0, 0.0, 0.0),
                                )*/
                              ],
                            ),
                            margin: EdgeInsets.only(left: 20.0),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                            stream: firestore.collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()).collection(document.id.toString()).snapshots(), // a previously-obtained Future<String> or null
                            builder: (BuildContext context, snapshot) {
                              if(snapshot.hasData) {
                                return snapshot.data.docs.length!=0? Badge(
                                  elevation: 0,
                                  shape: BadgeShape.circle,
                                  padding: EdgeInsets.all(7),
                                  badgeContent: Text(
                                    snapshot.data.docs.length.toString(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ):Container();
                              }
                              else{
                                return Container();
                              }
                            }
                        ),
                        /* Stack(children:[Container(
                            width: 30.0,
                            height: 30.0,
                            //padding: EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: secondColor,
                            ),

                         // child: Badge(badgeContent: Text("2"),),
                        ),
                         Container(
                             width: 20.0,
                             height: 20.0,
                           //  padding: EdgeInsets.all(5.0),
                             child: Text("2")),])*/
                      ],
                    ),
                    onPressed: () async {
                      QuerySnapshot q2 = await FirebaseFirestore.instance
                          .collection("ChatFriends").doc(userRep.user?.email).collection("Network").doc(document.id.toString()).collection(document.id.toString())
                          .get();

                      FirebaseFirestore.instance.runTransaction((transaction) async {
                        q2.docs.forEach((element) {
                          transaction.delete(element.reference);
                        });
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatTalkPage(
                                peerId: document.id,
                                peerAvatar: snapshot.data[0],
                                userId: currentUserId,
                              )));
                    },
                    color: greyColor2,
                    padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
                );
              }
            }
          });
    });
  }
  */