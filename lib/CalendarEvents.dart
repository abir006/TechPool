import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tech_pool/pages/CalendarEventInfo.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/pages/DesiredLiftInfo.dart';
import 'Utils.dart';

/// A container class for Drive event.
class Drive{
  String driveId;
  String info;
  int numberOfSeats;
  int numberOfPassengers;
  DateTime dateTime;
  final String title = "Drive";
  Drive(this.driveId,this.info,this.numberOfSeats,this.numberOfPassengers,this.dateTime);
}

/// A container class for Lift Calendar event.
class Lift{
  String driveId;
  String info;
  int numberOfSeats;
  int numberOfPassengers;
  DateTime dateTime;
  bool bigBag;
  final String title = "Lift";
  Lift(this.driveId,this.info,this.numberOfSeats,this.numberOfPassengers,this.dateTime,this.bigBag);
}

/// A container class for PendingLift Calendar event.
class DesiredLift{
  String info;
  String desiredId;
  DateTime dateTime;
  DateTime endDateTime;
  int dist;
  String fromAddress;
  String fromCity;
  String toAddress;
  String toCity;
  bool bigTrunk;
  bool backSeatNotFull;
  final String title = "Desired lift";
  DesiredLift(this.info,this.desiredId,this.dateTime,this.endDateTime,this.dist,this.fromAddress,this.fromCity,this.toAddress,this.toCity,this.bigTrunk,this.backSeatNotFull);
}

/// A container class for PendingLift Calendar event.
class PendingLift{
  String driveId;
  String info;
  DateTime dateTime;
  int dist;
  String from;
  String to;
  String passengerNote;
  bool bigBag;
  final String title = "Pending lift";
  PendingLift(this.from,this.to,this.driveId,this.info,this.dateTime,this.dist,this.passengerNote,this.bigBag);
}

enum CalendarEventType { Drive, Lift , PendingLift , DesiredLift }

/// A util function for the calendar, returns the desired event container to
/// display under the calendar, according to the type of event received.
Widget transformEvent(dynamic event, BuildContext context){
  if (event is Drive) {
    return calendarListTile(event, Icon(Icons.directions_car,size: 30, color: mainColor),context,CalendarEventType.Drive);
  } else if (event is Lift) {
    return calendarListTile(event, Transform.rotate(angle: 0.8,child: Icon(Icons.thumb_up_rounded,size: 30, color: mainColor)),context,CalendarEventType.Lift);
  } else if (event is PendingLift) {
    return calendarListTile(event, Icon(Icons.access_time,size: 30, color: mainColor),context,CalendarEventType.PendingLift);
  }else if (event is DesiredLift){
    return calendarListTile(event, Icon(Icons.fact_check_outlined,size: 30, color: mainColor),context,CalendarEventType.DesiredLift);
  }
  else{
    return Container();
  }
}

Container calendarListTile(dynamic event,Widget leadingWidget,BuildContext context,CalendarEventType eventType) {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: greyColor,blurRadius: 1.0,
          spreadRadius: 0.0,offset: Offset(1.0, 1.0))],
      border: Border.all(color: (eventType == CalendarEventType.PendingLift || eventType == CalendarEventType.DesiredLift) ? Colors.orange : Colors.green, width: 0.65),
      borderRadius: BorderRadius.circular(12.0),
    ),
    margin:
    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: ListTile(leading: leadingWidget,
        title: Text("${event?.title} \n${event?.info}"),
        onTap: () async {
      if(eventType != CalendarEventType.DesiredLift) {
        var drive = await firestore.collection("Drives")
            .doc(event.driveId)
            .get();
        MyLift docLift = new MyLift("driver", "destAddress", "stopAddress", 5);
        drive.data().forEach((key, value) {
          if (value != null) {
            docLift.setProperty(key, value);
          }
        });
        docLift.liftId = event.driveId;
        if (eventType == CalendarEventType.PendingLift) {
          docLift.dist = event.dist;
          docLift.pendingStartAddress = event.from;
          docLift.pendingDestAddress = event.to;
          docLift.pendingNote = event.passengerNote;
          docLift.bigBag = event.bigBag;
        }
        else if (eventType == CalendarEventType.Lift) {
          docLift.bigBag = event.bigBag;
          docLift.dist = 0;
        }
        docLift.passengersInfo = Map<String, Map<String, dynamic>>.from(
            drive.data()["PassengersInfo"] ?? {});
        docLift.payments =
            (await firestore.collection("Profiles").doc(docLift.driver).get())
                .data()["allowedPayments"].join(", ");
        Navigator.of(context).push(new MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return CalendarEventInfo(lift: docLift, type: eventType);
            },
            fullscreenDialog: true
        ));
      }else {
        Navigator.of(context).push(new MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return DesiredLiftInfo(docId: event.desiredId);
            },
            fullscreenDialog: true
        ));
      }

        },
        subtitle: Row(mainAxisAlignment: MainAxisAlignment.start,children: [Text("${(DateFormat.Hm().format(event.dateTime)).toString()}" + (eventType == CalendarEventType.DesiredLift ? " - ${(DateFormat.Hm().format(event.endDateTime)).toString()}" : "")),...((eventType != CalendarEventType.PendingLift && eventType != CalendarEventType.DesiredLift) ? [Spacer(),Icon(Icons.person,color: Colors.black,),Text(" ${event.numberOfPassengers} / ${event.numberOfSeats}",style: TextStyle(color: Colors.black),)] : [])]),
        trailing: Icon(Icons.chevron_right_sharp,color: Colors.black,size:30,)),
  );
}