import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/pages/LocationSearch.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:geocoder/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SetDrivePage extends StatefulWidget {
  DateTime currentDate;
  FirebaseFirestore db = FirebaseFirestore.instance;
  //int numberOfSeatsIndex;
  //SetDrivePage({Key key,@required this.currentDate,this.time,this.numberOfSeatsIndex}): super(key: key);
  SetDrivePage({Key key, @required this.currentDate}) : super(key: key);
  @override
  _SetDrivePageState createState() => _SetDrivePageState();
}

class _SetDrivePageState extends State<SetDrivePage> {
  final _formKey2 = GlobalKey<FormState>();

  DateTime time;
  double _fontTextsSize = 17;
  DateTime _hourTime;
  DateTime _hourTimeCandidate;
  bool bigTrunk = false;
  bool fullBackSeat = false;
  List<String> passengers = ["1", "2", "3", "4", "5", "6"];
  String numberOfPassengers = "3";
  TextEditingController _hourController;
  int numberOfStops = 0;
  //String price;
  //String noteToPassengers = "";
  TextEditingController _priceController;
  TextEditingController _noteController;
  TextEditingController _startPointController;
  TextEditingController _destPointController;
  TextEditingController _stopPoint1Controller;
  TextEditingController _stopPoint2Controller;
  TextEditingController _stopPoint3Controller;

  LocationsResult returnFromMapResult;
  Address startAddress;
  Address destAddress;
  //double _labelsTextsSize = 19;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(text: "");
    _startPointController = TextEditingController(text: "");
    _destPointController = TextEditingController(text: "");
    _stopPoint1Controller = TextEditingController(text: "");
    _stopPoint2Controller = TextEditingController(text: "");
    _stopPoint3Controller = TextEditingController(text: "");
    _priceController = TextEditingController(text: "");
    _noteController = TextEditingController(text: "");
  }

  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpace = MediaQuery.of(context).size.height * 0.013;
    double defaultSpaceWidth = MediaQuery.of(context).size.height * 0.016;
    /*if(widget.time!=null) {
      _hourTime = widget.time;
      _hourController.text = DateFormat('dd-MM – kk:mm').format(widget.time);
      widget.time=null;
    }*/

    /*if(widget.numberOfSeatsIndex!=null){
      _numberOfPassengers =_passengers[widget.numberOfSeatsIndex];
      widget.numberOfSeatsIndex = null;
    }*/

    /*final stopPoint1text = numberOfStops > 0
        ? Container(
            child: Row(
              children: [
                textBoxFieldDisable(
                  nameLabel: "Stop 1:",
                  size: MediaQuery.of(context).size,
                  hintText: "",
                  textFieldController: _stopPoint1Controller,
                  // validator: (value) {
                  //   if(_startPointController==null || _startPointController.text==""){return "No start point chosen";}
                  //   else return null;}
                ),
              ],
            ),
          )
        : Container();

    final stopPoint2text = numberOfStops > 1
        ? Container(
            child: Row(
              children: [
                textBoxFieldDisable(
                  nameLabel: "Stop 2:",
                  size: MediaQuery.of(context).size,
                  hintText: "",
                  textFieldController: _stopPoint2Controller,
                ),
              ],
            ),
          )
        : Container();

    final stopPoint3text = numberOfStops > 2
        ? Container(
            child: Row(
              children: [
                textBoxFieldDisable(
                  nameLabel: "Stop 3:",
                  size: MediaQuery.of(context).size,
                  hintText: "",
                  textFieldController: _stopPoint3Controller,
                ),
              ],
            ),
          )
        : Container();
      */

    final stopPoint1text_2 = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
            nameLabel: "Stop 1:",
            size: MediaQuery.of(context).size,
            hintText: "",
            textFieldController: _stopPoint1Controller,
          ),
        ],
      ),
    );
    final stopPoint2text_2 = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
            nameLabel: "Stop 2:",
            size: MediaQuery.of(context).size,
            hintText: "",
            textFieldController: _stopPoint2Controller,
          ),
        ],
      ),
    );
    final stopPoint3text_2 = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
            nameLabel: "Stop 3:",
            size: MediaQuery.of(context).size,
            hintText: "",
            textFieldController: _stopPoint3Controller,
          ),
        ],
      ),
    );

    final startPointText = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
              nameLabel: "Start:",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _startPointController,
              validator: (value) {
                if (_startPointController == null ||
                    _startPointController.text == "") {
                  return "No start point chosen";
                } else
                  return null;
              }),
        ],
      ),
    );

    final destinationText = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
              nameLabel: "Destination:",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _destPointController,
              validator: (value) {
                if (_destPointController == null ||
                    _destPointController.text == "") {
                  return "No destination chosen";
                } else
                  return null;
              }),
        ],
      ),
    );

    final chooseStartAndDestination = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            child: RaisedButton.icon(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.black)),
              label: Text("Choose Start and Destination"),
              icon: Icon(Icons.map),
              onPressed: () async {
                returnFromMapResult = await Navigator.of(context)
                    .push(MaterialPageRoute<LocationsResult>(
                        builder: (BuildContext context) {
                          return LocationSearch(showAddStops: true);
                        },
                        fullscreenDialog: true));
                setState(() {
                  if (returnFromMapResult != null) {
                    startAddress = returnFromMapResult.fromAddress;
                    destAddress = returnFromMapResult.toAddress;
                    _startPointController.text =
                        returnFromMapResult.fromAddress.addressLine;
                    _destPointController.text =
                        returnFromMapResult.toAddress.addressLine;
                    numberOfStops = returnFromMapResult.numberOfStops;
                    if(numberOfStops > 0) _stopPoint1Controller.text = returnFromMapResult.stopAddresses[0].addressLine;
                    if(numberOfStops > 1) _stopPoint2Controller.text = returnFromMapResult.stopAddresses[1].addressLine;
                    if(numberOfStops > 2) _stopPoint3Controller.text = returnFromMapResult.stopAddresses[2].addressLine;
                    /*numberOfStops = 0;
                    for(int i = 0; i < returnFromMapResult.stopAddresses.length; i++) {
                      //bool exists = returnFromMapResult.stopAddresses[i] as bool;
                      bool exists = (returnFromMapResult.stopAddresses[i] != null);
                      int addition = exists ? 1 : 0;
                      numberOfStops += addition;
                    }*/
                  }
                });
              },
            ),
          ),
        ]);


    final departureTimeButton = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: RaisedButton.icon(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.black)),
              label: Text("Departure time"),
              icon: Icon(Icons.timer),
              onPressed: () {
                //DateTime fixedTime = DateTime.now();
                //fixedTime.add(new Duration(minutes: 25));

                showDialog(
                    context: context,
                    builder: (_) => new SimpleDialog(
                          title: Center(
                              child: Text("Choose departure time",
                                  style: TextStyle(fontSize: 21))),
                          //content: Text("Hey! I'm Coflutter!"),
                          children: [
                            TimePickerSpinner(
                              is24HourMode: true,
                              normalTextStyle:
                                  TextStyle(fontSize: 28, color: Colors.grey),
                              highlightedTextStyle:
                                  TextStyle(fontSize: 34, color: Colors.teal),
                              //spacing: 50,
                              //itemHeight: 80,
                              alignment: Alignment.center,
                              isForce2Digits: true,
                              minutesInterval: 5,
                              //time: _hourTime != null ? _hourTime : fixedTime,
                              time: _hourTime != null
                                  ? _hourTime
                                  : DateTime.now().add(new Duration(hours: 2)),
                              isShowSeconds: false,
                              onTimeChange: (time) {
                                setState(() {
                                  _hourTimeCandidate = time;
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, //Center Row contents horizontally,
                              children: [
                                //RaisedButton(
                                FlatButton(
                                  child: Text('CANCEL',
                                      style: TextStyle(
                                          fontSize: 16, color: mainColor)),
                                  onPressed: () {
                                    setState(() {
                                      Navigator.of(context).pop();
                                    });
                                  },
                                ),
                                //SizedBox(width: 2*defaultSpaceWidth),
                                //RaisedButton(
                                FlatButton(
                                  child: Text('CONFIRM',
                                      style: TextStyle(
                                          fontSize: 16, color: mainColor)),
                                  onPressed: () {
                                    _hourTime = _hourTimeCandidate;
                                    _hourController.text =
                                        DateFormat('dd-MM – kk:mm')
                                            .format(_hourTimeCandidate);
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            ),
                          ],
                        ));
              },
            ),
          ),
          //Text(resultString ?? "")
        ]);

    final timeText1 = Container(
      child: textBoxFieldDisableCentered(
          //nameLabel: "Deppparture Time: ",
          size: MediaQuery.of(context).size,
          hintText: "",
          textFieldController: _hourController,
          validator: (value) {
            if (_hourTime == null)
              return '                               Time not chosen';
            else
              return null;
          }),
    );

    final bigTrunkText = Container(
      height: 4 * defaultSpace,
      child: Row(
        children: [
          Text(
            'Big trunk? ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
          Theme(
              data: ThemeData(unselectedWidgetColor: secondColor),
              child: Checkbox(
                  value: bigTrunk,
                  onChanged: (bool value) {
                    setState(() {
                      bigTrunk = value;
                    });
                  })),
        ],
      ),
    );

    final backSeatText = Container(
      height: 4 * defaultSpace,
      child: Row(
        children: [
          Text(
            'Full back seat? ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
          Theme(
              data: ThemeData(unselectedWidgetColor: secondColor),
              child: Checkbox(
                  value: fullBackSeat,
                  onChanged: (bool value) {
                    setState(() {
                      fullBackSeat = value;
                    });
                  })),
        ],
      ),
    );

    final seatsNumberText = Container(
      height: 4 * defaultSpace,
      child: Row(
        children: [
          Text(
            'Number of seats: ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
          Container(
            color: Colors.transparent,
            child: Theme(
                data: Theme.of(context).copyWith(
                    canvasColor:
                        mainColor, // background color for the dropdown items
                    buttonTheme: ButtonTheme.of(context).copyWith(
                      alignedDropdown:
                          true, //If false (the default), then the dropdown's menu will be wider than its button.
                    )),
                child: DropdownButton<String>(
                    dropdownColor: mainColor,
                    elevation: 0,
                    value: numberOfPassengers,
                    onChanged: (String newValue) {
                      setState(() {
                        numberOfPassengers = newValue;
                      });
                    },
                    items: passengers
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList())),
          )
        ],
      ),
    );

    final noteToPassengersText = Container(
      child: TextFormField(
        maxLength: 150,
        //150 characters to use:
        //wordwordword1wordwordword2wordwordword3wordwordword4wordwordword5wordwordword6wordwordword7wordwordword8wordwordword9wordwordword10wordwordword11
        //maxLengthEnforced: true,
        controller: _noteController,
        decoration: InputDecoration(
          labelText: 'Note to passengers:',
          labelStyle: TextStyle(fontSize: _fontTextsSize),
        ),
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(150),
        ],
      ),
    );

    final priceText = Container(
      margin: const EdgeInsets.only(right: 280),
      child: TextFormField(
          //maxLengthEnforced: true,
          maxLength: 3,
          decoration: InputDecoration(
            counterText: '',
            labelText: 'Price: ₪',
            labelStyle: TextStyle(fontSize: _fontTextsSize),
          ),
          keyboardType: TextInputType.number,
          controller: _priceController,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {
            if (value.isEmpty) return 'Enter price';
            else return null;
          }),
    );

    return Consumer<UserRepository>(builder: (context, userRep, child) {
      final setDrive = Container(
          padding: EdgeInsets.only(
              left: sizeFrameWidth * 0.23, right: sizeFrameWidth * 0.23),
          height: 40,
          child: RaisedButton.icon(
              color: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.black)),
              icon: Icon(Icons.directions_car_sharp, color: Colors.white),
              label: Text("  Set Drive  ",
                  style: TextStyle(color: Colors.white, fontSize: 17)),
              onPressed: () {
                if (_formKey2.currentState.validate()) {
                  // try{
                  // }
                  // catch{
                  // }
                  //driveName = "drive5"
                  CollectionReference drives = widget.db.collection('Drives');
                  drives.add({
                    'BackSeatNotFull': !(fullBackSeat),
                    'BigTrunk': bigTrunk,
                    'Note': _noteController.text,
                    'NumberSeats': numberOfPassengers,
                    'Price': _priceController.text,
                    'StartAddress': startAddress.addressLine,
                    'StartCity': startAddress.locality,
                    'StartPoint': GeoPoint(startAddress.coordinates.latitude,startAddress.coordinates.longitude),
                    'DestAddress': destAddress.addressLine,
                    'DestCity': destAddress.locality,
                    'DestPoint': GeoPoint(destAddress.coordinates.latitude,destAddress.coordinates.longitude),
                    //'TimeStamp': DateTime.now(),//Should add+2?
                    'TimeStamp': time,//Should add+2?
                    'Driver': userRep.user.email,
                    //'Driver': "testing@technion.co.il",
                  })
                      .then((value) => Navigator.pop(context))
                      .catchError((error) => print("Failed to add user: $error"));


                }
              }));


      return Scaffold(
        appBar: AppBar(
          title: Text("Set Drive", style: TextStyle(color: Colors.white)),
        ),
        body: Form(
          key: _formKey2,
          child: Builder(
            builder: (context) =>
                Container(
                    color: Colors.white,
                    margin: EdgeInsets.only(
                        left: defaultSpaceWidth,
                        right: defaultSpaceWidth,
                        bottom: 10),
                    child: Stack(children: [
                      Container(
                          child: Center(
                              child: Icon(
                                Icons.directions_car_sharp,
                                size: 330,
                                color: Colors.cyan.withOpacity(0.1),
                              ))),
                      ListView(
                          padding: EdgeInsets.only(
                              left: defaultSpaceWidth,
                              right: defaultSpaceWidth,
                              bottom: 10),
                          children: [
                            //SizedBox(height: defaultSpace),
                            //locationText,
                            SizedBox(height: 1.5 * defaultSpace),
                            chooseStartAndDestination,
                            startPointText,


                            /*...returnFromMapResult.stopAddresses.asMap().map((i, stop){
                            if(stop!=null){
                              return MapEntry(i, Container(
                                child: Row(
                                  children: [
                                    textBoxFieldDisable(
                                      nameLabel: "Stop " + i.toString() + ":", //Consider to edit,
                                      size: MediaQuery.of(context).size,
                                      hintText: "",
                                      textFieldController: _stopPoint1Controller,
                                      // validator: (value) {
                                      //   if(_startPointController==null || _startPointController.text==""){return "No start point chosen";}
                                      //   else return null;}
                                    ),
                                  ],
                                ),
                              ));
                            }
                            else
                              return MapEntry(i, Container());
                          }
                      ).values.toList(),*/

                            numberOfStops > 0 ? stopPoint1text_2 : Container(),
                            numberOfStops > 1 ? stopPoint2text_2 : Container(),
                            numberOfStops > 2 ? stopPoint3text_2 : Container(),
                            /*stopPoint1text,
                      stopPoint2text,
                      stopPoint3text,*/

                            //if(numberOfStops > 0) Column(children: [SizedBox(height: defaultSpace), stopPoint1text]),
                            // numberOfStops > 1 ? Column(children: [SizedBox(height: defaultSpace), stopPoint2text]) : null,
                            // numberOfStops > 2 ? Column(children: [SizedBox(height: defaultSpace), stopPoint3text]) : null,
                            // SizedBox(height: defaultSpace/3),
                            // stopPoint2text,
                            // SizedBox(height: defaultSpace/3),
                            // stopPoint3text,

                            destinationText,
                            SizedBox(height: 2 * defaultSpace),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                departureTimeButton,
                                timeText1,
                                priceText,
                              ],
                            ),
                            SizedBox(height: 2 * defaultSpace),
                            //propertiesText,
                            //SizedBox(height: defaultSpace/2),
                            bigTrunkText,
                            backSeatText,
                            seatsNumberText,
                            noteToPassengersText,
                            SizedBox(height: 2 * defaultSpace),
                            setDrive,
                          ])
                    ])),
          ),
        ),
        backgroundColor: mainColor,
      );
    });

  }

  @override
  void dispose() {
    _hourController.dispose();
    _startPointController.dispose();
    _destPointController.dispose();
    _stopPoint1Controller.dispose();
    _stopPoint2Controller.dispose();
    _stopPoint3Controller.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
