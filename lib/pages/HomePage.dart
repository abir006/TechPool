import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tech_pool/Utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tech_pool/pages/SearchLiftPage.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDay = DateTime.now();
  CalendarController _calendarController;
  Map<DateTime, List> _events = {DateTime.now() : [Drive('A Drive'),Lift('A Lift')],DateTime.now().add(Duration(days: 1)) : [Lift('A Lift')]};
  List  _dailyEvents = [];

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
    setState(() {
      selectedDay = day;
      _dailyEvents = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, userRep, child) {
      return Scaffold(floatingActionButton: Wrap(spacing: 5,direction: Axis.vertical,children: [FloatingActionButton(heroTag: "drive",backgroundColor: Colors.white,child: Icon(Icons.directions_car,size: 35,color: Colors.black,), onPressed: () async {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              //TODO: replace with Set Drive Page.
              return SearchLiftPage(currentdate: selectedDay);
            },
          ),
        );
       },)
        ,Transform.rotate(angle: 0.8,child: FloatingActionButton(heroTag: "lift",backgroundColor: Colors.black, child: Icon(Icons.thumb_up_rounded,size: 30,),onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return SearchLiftPage(currentdate: selectedDay,popOrNot: false,);
              },
            ),
          );
        },))],),backgroundColor: mainColor,appBar: AppBar(title: Text("Home",  style: TextStyle(color: Colors.white),), actions: [IconButton(icon :Icon(Icons.exit_to_app),
          onPressed: () async => await (userRep.auth.signOut().then((_) => userRep.user = null)))],),drawer: Drawer(child: Container(color: mainColor, child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [Text("Drawer")],),)),
          body: Container(color: Colors.white,margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: ListView(children: [
            TableCalendar(availableCalendarFormats: {CalendarFormat.month : 'Week', CalendarFormat.week : 'Month'},calendarController: _calendarController, events: _events,onDaySelected: _onDaySelected),
           Divider(indent: 5,endIndent: 5,thickness: 2), ..._dailyEvents
                  .map((event) => transformEvent(event))
                  .toList(),
            ])));
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }
}
