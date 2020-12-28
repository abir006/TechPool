import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tech_pool/appValidator.dart';
import 'package:tech_pool/pages/NotificationsPage.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tech_pool/CalendarEvents.dart';
import 'package:tech_pool/TechDrawer.dart';
import 'SetDrivePage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDay = DateTime.now();
  CalendarController _calendarController;
  Map<DateTime, List> _events;
  List _dailyEvents;
  bool firstLoad = true;
  appValidator appValid;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _events = {};
    _dailyEvents = [];
    appValid = appValidator();
    appValid.checkConnection(context);
    appValid.checkVersion(context);
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
    setState(() {
      selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return StreamBuilder<List<QuerySnapshot>>(
              stream: CombineLatestStream([
              firestore.collection("Drives").where("Passengers", arrayContains: userRep.user?.email).snapshots(),firestore
                    .collection("Drives")
                    .where('Driver', isEqualTo: userRep.user?.email).snapshots(),firestore.collection("Notifications").doc(userRep.user?.email).collection("Pending").snapshots()],(vals) => [vals[0],vals[1],vals[2]]),
              builder: (context, snapshot) {
                _events = {};
                _dailyEvents = [];
                if (snapshot.hasData) {
                  snapshot.data[1].docs.forEach((element) {
                    try {
                      var elementData = element.data();
                      DateTime elementTime = elementData["TimeStamp"].toDate();
                      var drive = Drive(element.id,
                          elementData["StartCity"] +
                              " \u{2192} " +
                              elementData["DestCity"],
                          elementData["NumberSeats"],
                          elementData["Passengers"].length,
                          elementTime);
                      _events[Jiffy(elementTime)
                          .startOf(Units.DAY)
                          .add(Duration(hours: 12))] =
                          (_events[Jiffy(elementTime)
                              .startOf(Units.DAY)
                              .add(Duration(hours: 12))] ??
                              []) +
                              [drive];
                      if (elementTime
                          .isAfter(Jiffy(selectedDay).startOf(Units.DAY)) &&
                          elementTime
                              .isBefore(Jiffy(selectedDay).endOf(Units.DAY))) {
                        _dailyEvents.add(drive);
                      }
                    }catch(e){
                    }
                  });
                  snapshot.data[0].docs.forEach((element) {
                    try {
                      var elementData = element.data();
                      DateTime elementTime = elementData["TimeStamp"].toDate();
                      var lift = Lift(element.id,
                          elementData["StartCity"] +
                              " \u{2192} " +
                              elementData["DestCity"],
                          elementData["NumberSeats"],
                          elementData["Passengers"].length,
                          elementTime,elementData["PassengersInfo"][userRep.user.email]["bigBag"]);
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
                        _dailyEvents.add(lift);
                      }
                    }catch(e){
                    }
                  });
                  snapshot.data[2].docs.forEach((element) {
                    try {
                      var elementData = element.data();
                      DateTime elementTime = elementData["liftTime"].toDate();
                      var lift = PendingLift(elementData["startAddress"],elementData["destAddress"],elementData["driveId"],
                          elementData["startCity"] +
                              " \u{2192} " +
                              elementData["destCity"],
                          elementTime,elementData["distance"],elementData["passengerNote"],elementData["bigBag"]);
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
                        _dailyEvents.add(lift);
                      }
                    }catch(e){
                    }
                  });
                  _dailyEvents.sort((a, b) {
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
                        Text("Error loading events from cloud")
                      ]);
                } else {
                  return Scaffold(backgroundColor: mainColor,
                  appBar: AppBar(
                  elevation: 0,
                      title: Text(
                      "Home",
                      style: TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                      icon: StreamBuilder(
                          stream: firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").snapshots(), // a previously-obtained Future<String> or null
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
                      onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotificationsPage()))
                  )
                ],
                ),
                drawer: techDrawer(userRep, context, DrawerSections.home),
                body: Container(
                decoration: pageContainerDecoration,
                margin: pageContainerMargin,
                child: Center(child: CircularProgressIndicator())));
                }
              });
    });
  }

  /// the page content that needs to be showed if snapshot has and transformed correctly.
  Scaffold _buildPage(BuildContext context, UserRepository userRep) {
    return Scaffold(
        floatingActionButton: Wrap(
          spacing: 5,
          direction: Axis.vertical,
          children: [
            FloatingActionButton(
              heroTag: "drive",
              backgroundColor: selectedDay.isBefore(Jiffy(DateTime.now()).startOf(Units.DAY)) ? Colors.grey : mainColor,
              child: Icon(
                Icons.directions_car,
                size: 35,
                color: Colors.white,
              ),
              onPressed: () async {
                if (selectedDay.isBefore(Jiffy(DateTime.now()).startOf(Units.DAY))) {
                  showDialog(context: context,child: AlertDialog(title: Text("Drive error"),content: Text("Cant set a drive for a date that has already passed."),actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Dismiss"))],));
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return SetDrivePage(currentDate: selectedDay);
                      },
                    ),
                  );
                }
              }
            ),
            Transform.rotate(
                angle: 0.8,
                child: FloatingActionButton(
                  heroTag: "lift",
                  backgroundColor: selectedDay.isBefore(Jiffy(DateTime.now()).startOf(Units.DAY)) ? Colors.grey : Colors.black,
                  child: Icon(
                    Icons.thumb_up_rounded,
                    size: 30,
                  ),
                  onPressed: () {
                    if (selectedDay.isBefore(
                        Jiffy(DateTime.now()).startOf(Units.DAY))) {
                      showDialog(context: context,
                          child: AlertDialog(title: Text("Lift error"),
                            content: Text(
                                "Cant search a lift for a date that has already passed."),
                            actions: [TextButton(onPressed: () =>
                                Navigator.pop(context),
                                child: Text("Dismiss"))
                            ],));
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                            return SearchLiftPage(
                              currentdate: selectedDay,
                              popOrNot: false,
                            );
                          },
                        ),
                      );
                    }
                  }
                ))
          ],
        ),
        backgroundColor: mainColor,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Home",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
                icon: StreamBuilder(
                stream: firestore.collection("Notifications").doc(userRep.user?.email).collection("UserNotifications").snapshots(), // a previously-obtained Future<String> or null
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
                onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsPage()))
            )

        //     IconButton(
        //         icon: Icon(Icons.notifications),
        //         onPressed:() => Navigator.pushReplacement(
        // context,
        // MaterialPageRoute(
        //     builder: (context) => NotificationsPage())))
          ],
        ),
        drawer: techDrawer(userRep, context, DrawerSections.home),
        body: Container(
            decoration: pageContainerDecoration,
            margin: pageContainerMargin,
            child: Column(children: [
              TableCalendar(
                  initialSelectedDay: selectedDay,
                  daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: secondColor)),
                  calendarStyle: CalendarStyle(
                      markersColor: secondColor,
                      selectedColor: mainColor,
                      todayColor: mainColor[100]),
                  weekendDays: [5, 6],
                  availableCalendarFormats: {
                    CalendarFormat.month: 'Week',
                    CalendarFormat.week: 'Month'
                  },
                  calendarController: _calendarController,
                  events: _events,
                  onDaySelected: _onDaySelected),
              Divider(indent: 5, endIndent: 5, thickness: 2),
              Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: ListView(children: [...(_dailyEvents.isEmpty? [ListTile(leading: Icon(Icons.calendar_today),title: Text("No events yet"),)] :
                    _dailyEvents.map((event) => transformEvent(event,context)).toList())
              ]),
                  )),
            ])));
  }

  @override
  void dispose() {
    _calendarController.dispose();
    appValid.listener.cancel();
    appValid.versionListener.cancel();
    super.dispose();
  }
}
