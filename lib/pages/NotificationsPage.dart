import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:rxdart/rxdart.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDay = DateTime.now();
  List _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<List<QuerySnapshot>>(
          stream: CombineLatestStream([
          firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").snapshots()],
                  (values) => [values[0]]),
          builder: (context, snapshot) {
            _notifications = [];
            if (snapshot.hasData) {
              snapshot.data[0].docs.forEach((element) {
                var elementData = element.data();
                DateTime elementTime = elementData["TimeStamp"].toDate();
                String notificationType = elementData["NotificationType"];
                var notification;
                switch(notificationType) {
                  case "AcceptedLiftNotification" : {
                    notification = AcceptedLiftNotification(element.id,
                        elementData["StartCity"] +
                            " \u{2192} " +
                            elementData["DestCity"],
                        elementData["NumberSeats"],
                        elementData["Passengers"].length,
                        elementTime);

                  }
                  break;

                  case "RejectedLiftNotification" : {
                    notification = RejectedLiftNotification(element.id,
                        elementData["StartCity"] +
                            " \u{2192} " +
                            elementData["DestCity"],
                        elementData["NumberSeats"],
                        elementData["Passengers"].length,
                        elementTime);

                  }
                  break;

                  //default: {
                  case "RequestedLiftNotification" : {
                    notification = RequestedLiftNotification(element.id,
                        elementData["StartCity"] +
                            " \u{2192} " +
                            elementData["DestCity"],
                        elementData["NumberSeats"],
                        elementData["Passengers"].length,
                        elementTime);

                  }
                  break;
                }

                _notifications.add(notification);
              });
              /*snapshot.data[0].docs.forEach((element) {
                var elementData = element.data();
                DateTime elementTime = elementData["TimeStamp"].toDate();
                var lift = Lift(element.id,
                    elementData["StartCity"] +
                        " \u{2192} " +
                        elementData["DestCity"],
                    elementData["NumberSeats"],
                    elementData["Passengers"].length,
                    elementTime);
                _events[Jiffy(elementTime)
                    .startOf(Units.DAY)
                    .add(Duration(hours: 12))] = (_events[Jiffy(
                    elementTime)
                    .startOf(Units.DAY)
                    .add(Duration(hours: 12))] ??
                    []) +
                    [lift];
                if (elementTime
                    .isAfter(Jiffy(selectedDay).startOf(Units.DAY)) &&
                    elementTime
                        .isBefore(Jiffy(selectedDay).endOf(Units.DAY))) {
                  _notifications.add(lift);
                }
              });*/
              _notifications.sort((a, b) {
                if (a.dateTime.isAfter(b.dateTime)) {
                  return 1;
                } else {
                  return -1;
                }
              });
              return _buildPage(context, userRep);
            } else if (snapshot.hasError) {
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.error),
                    Text("Error on loading notifications from the database. Please try again.")
                  ]);
            } else {
              return _buildPage(context, userRep);
            }
          });
    });
  }

  Scaffold _buildPage(BuildContext context, UserRepository userRep) {
    return Scaffold(
        backgroundColor: mainColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Notifications",
            style: TextStyle(color: Colors.white),
          ),
        ),
        drawer: techDrawer(userRep, context, DrawerSections.home),
        body: Container(
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            child: Column(children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.013),
            //Divider(indent: 5, endIndent: 5, thickness: 2),
              Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: ListView(children: [
                      ..._notifications.map((notification) => notificationSwitcher(notification, context)).toList()
                    ]),
                  )),
            ])));
  }



  @override
  void dispose() {
    super.dispose();
  }
}
