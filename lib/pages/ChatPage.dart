import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/widgets/loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'ChatTalkPage.dart';
import 'ProfilePage.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:tech_pool/TechDrawer.dart';

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
  String query='';
  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  TextEditingController _searchText;

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    _searchText = TextEditingController();
    registerNotification();
    configLocalNotification();
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

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
            EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
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
        exit(0);
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

  List<DocumentSnapshot>


  onItemChanged(String value) {
    setState(() {
      query = _searchText.text;
    });
  }
  void filter(List<DocumentSnapshot> data){
    filteredDocs =[];
    data.forEach((element) {
      String name =element["firstName"]+element["lastName"];
      if(query=='' || name.toLowerCase().contains(query.toLowerCase())){
        filteredDocs.add(element);
      }
    });

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
      ),
      drawer: Consumer<UserRepository>(builder: (context, auth, _) => techDrawer(auth, context, DrawerSections.profile)),
      body: WillPopScope(
        child: Container(
          decoration: pageContainerDecoration,
          margin: pageContainerMargin,
          child: Stack(
            children: <Widget>[
              // List
              Container(
                child: StreamBuilder(
                  stream:
                  FirebaseFirestore.instance.collection('Profiles').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      );
                    } else {
                      filter(snapshot.data.documents);
                      return Column(children:[
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                             controller: _searchText,
                          decoration: InputDecoration(
                            prefixIcon:Icon(Icons.search),
                            hintText: 'Search Here...',
                            suffixIcon: query !=''?IconButton(
                              onPressed: () {  setState(() {
                                query ='';
                                _searchText.clear();});},
                              icon: Icon(Icons.clear),
                            ): Container(),
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
                        )]);
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
       // onWillPop: onBackPress,
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
      return FutureBuilder<List<String>>(
          future: initNames(document.id.toString()),
          // a previously-obtained Future<String> or null
          builder: (BuildContext context,
              AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.hasData) {
              if (document.id.toString() == userRep.user.email) {
                return Container();
              } else {
                return Container(
                  child: FlatButton(
                    child: Row(
                      children: <Widget>[
                       Material(
                          child: snapshot.data[0] != null
                              ? 
                          InkWell(
                    onTap: () async {
                  await Navigator.of(context).push(
                      MaterialPageRoute<liftRes>(
                          builder: (BuildContext context) {
                            return ProfilePage(
                              email: document.id.toString(), fromProfile: false,);
                          },
                          fullscreenDialog: true
                      ));},
                            child: CachedNetworkImage(
                              placeholder: (context, url) =>
                                  Container(
                                    color: mainColor,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.0,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(themeColor),
                                    ),
                                    width: 50.0,
                                    height: 50.0,
                                    padding: EdgeInsets.all(15.0),
                                  ),
                              imageUrl: snapshot.data[0],
                              width: 50.0,
                              height: 50.0,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Icon(
                            Icons.account_circle,
                            size: 50.0,
                            color: greyColor,
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
                                    document.data()['firstName']+" "+document.data()['lastName'],
                                    style: TextStyle(color: primaryColor),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.fromLTRB(
                                      10.0, 0.0, 0.0, 5.0),
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
                      ],
                    ),
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ChatTalkPage(
                      peerId: document.id,
                      peerAvatar: snapshot.data[0],
                      userId: currentUserId,
                    )));
                    },
                    color: greyColor2,
                    padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
                    shape:
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
                );
              }
            }
            else {
              if (snapshot.hasError) {
                  return Container();
              } else {
                return Center(child: CircularProgressIndicator(),);
              }
            }
          });
    });
  }
  void dispose() {
    _searchText.dispose();
    super.dispose();
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
