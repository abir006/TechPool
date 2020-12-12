import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';

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

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _events = {};
    _dailyEvents = [];
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
    setState(() {
      selectedDay = day;
      _dailyEvents = events;
      _dailyEvents.sort((a, b) {
        if (a.dateTime.isAfter(b.dateTime)) {
          return 1;
        } else {
          return -1;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return firstLoad
          ? FutureBuilder<QuerySnapshot>(
              future: firestore
                  .collection("Drives")
                  .where('Driver', isEqualTo: userRep.user.email)
                  .get(),
              builder: (context, snapshot) {
                _events = {};
                _dailyEvents = [];
                if (snapshot.hasData) {
                  firstLoad = false;
                  snapshot.data.docs.forEach((element) {
                    DateTime elementTime = element.data()["TimeStamp"].toDate();
                    Drive drive = Drive(
                        element.data()["StartCity"] +
                            " -> " +
                            element.data()["DestCity"],
                        element.data()["NumberSeats"],
                        element.data()["Passengers"].length,
                        elementTime);
                    _events[Jiffy(elementTime)
                        .startOf(Units.DAY)
                        .add(Duration(hours: 12))] = (_events[Jiffy(elementTime)
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
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [Text("Loading"), LinearProgressIndicator()]);
                }
              })
          : _buildPage(context, userRep);
    });
  }

  Scaffold _buildPage(BuildContext context, UserRepository userRep) {
    return Scaffold(
        floatingActionButton: Wrap(
          spacing: 5,
          direction: Axis.vertical,
          children: [
            FloatingActionButton(
              heroTag: "drive",
              backgroundColor: Colors.black,
              child: Icon(
                Icons.directions_car,
                size: 35,
                color: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return SetDrivePage(currentDate: selectedDay);
                    },
                  ),
                );
              },
            ),
            Transform.rotate(
                angle: 0.8,
                child: FloatingActionButton(
                  heroTag: "lift",
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.thumb_up_rounded,
                    size: 30,
                  ),
                  onPressed: () {
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
                  },
                ))
          ],
        ),
        backgroundColor: mainColor,
        appBar: AppBar(
          title: Text(
            "Home",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.notifications),
                onPressed: null)
          ],
        ),
        drawer: techDrawer(userRep, context, DrawerSections.home),
        body: Container(
            color: Colors.white,
            margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
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
                  child: ListView(children: [
                ..._dailyEvents.map((event) => transformEvent(event)).toList()
              ])),
            ])));
  }



  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }
}
