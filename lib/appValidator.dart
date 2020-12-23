import 'dart:async';
import 'package:tech_pool/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';

class appValidator {
  bool fallback = false;
  StreamSubscription<DataConnectionStatus> listener;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot> versionListener;
  var internetStatus = "Unknown";
  var contentMessage = "Unknown";

  void _showDialog(String title, String content, BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: new Text(title),
              content: new Text(content),
              actions: <Widget>[

              ]),
          );
        }
    );
  }

  checkConnection(BuildContext context) async {
    listener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          if(fallback==true) {
           // _showDialog(internetStatus, contentMessage, context);
            fallback = false;
            Navigator.of(context).pop();
          }
          break;
        case DataConnectionStatus.disconnected:
          fallback=true;
          internetStatus = "You are disconnected from the internet. ";
          contentMessage = "Please connect to the internet. The app wont work properly otherwise.";
          _showDialog(internetStatus, contentMessage, context);
          break;
      }
    });
    return await DataConnectionChecker().connectionStatus;
  }

  checkVersion(BuildContext context) async {
    versionListener = firestore.collection("Version").doc("VersionControl").snapshots().listen((event) {
      if(event.data()["version"] != versionNumber){
        _showDialog("Your'e app is out-dated", "Please update your app through the app store", context);
      }
    });
  }
}