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
import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';
import 'dart:math';
import 'package:date_time_picker/date_time_picker.dart';

class SetDrivePage extends StatefulWidget {
  DateTime currentDate;
  FirebaseFirestore db = FirebaseFirestore.instance;
  SetDrivePage({Key key, @required this.currentDate}) : super(key: key);
  @override
  _SetDrivePageState createState() => _SetDrivePageState();
}

class _SetDrivePageState extends State<SetDrivePage> {
  //FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _formKey2 = GlobalKey<FormState>();
  final _key2 = GlobalKey<ScaffoldState>();
  final myColor = Color(0xfff808080);
  double _fontTextsSize = 17;
  DateTime _chosenTime;
  DateTime _chosenTimeCandidate;
  bool _bigTrunk = false;
  bool _fullBackSeat = false;
  List<String> _passengers = ["1", "2", "3", "4", "5", "6"];
  String _numberOfPassengers = "3";
  TextEditingController _hourController;
  int _numberOfStops = 0;
  TextEditingController _priceController;
  TextEditingController _noteController;
  TextEditingController _startPointController;
  TextEditingController _destPointController;
  TextEditingController _stopPoint1Controller;
  TextEditingController _stopPoint2Controller;
  TextEditingController _stopPoint3Controller;
  bool _validateLocations = true;
  bool _validateTime = true;
  String _timeError = "";

  LocationsResult returnFromMapResult;
  Address startAddress;
  Address destAddress;
  List<Map> stopAddressesList = [];

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(text: "Press to choose time");
    _startPointController = TextEditingController(text: "");
    _destPointController = TextEditingController(text: "");
    _stopPoint1Controller = TextEditingController(text: "");
    _stopPoint2Controller = TextEditingController(text: "");
    _stopPoint3Controller = TextEditingController(text: "");
    _priceController = TextEditingController(text: "");
    _noteController = TextEditingController(text: "");
  }


  //After inserting the drive to db, search for fit desired lifts and notify the relevant hitchhikers
  Future<bool> _checkForFitDesiredAndSendNotifications(MyLift relDrive) async {
    Coordinates startPointCoords = startAddress.coordinates;
    Coordinates destPointCoords = destAddress.coordinates;
    try{
      QuerySnapshot relevantDesired = await widget.db.collection("Desired")
          .where('liftTimeStart', isLessThanOrEqualTo: Timestamp.fromDate(relDrive.time))
          .get();
          //.where('passengerId', isNotEqualTo: relDrive.driver)
          //.where('liftTimeEnd', isGreaterThanOrEqualTo: Timestamp.fromDate(relDrive.time))
          //.where('backSeatNotFull', isEqualTo: relDrive.backSeat)
          //.where('bigTrunk', isEqualTo: relDrive.bigTrunk)
      relevantDesired.docs.forEach((curDesired) async {
        //DateTime liftTimeEnd2 = DateTime.fromMicrosecondsSinceEpoch(curDesired["liftTimeEnd"] * 1000);
        DateTime liftTimeEnd = DateTime.fromMicrosecondsSinceEpoch(curDesired["liftTimeEnd"].microsecondsSinceEpoch);
        String curDesiredPassengerId = curDesired["passengerId"];
        String driver = relDrive.driver;
        DateTime driveTime = relDrive.time;
        if (curDesiredPassengerId != driver && liftTimeEnd.isAfter(driveTime)) {
          int maxDistance = curDesired["maxDistance"];
          bool curDesiredBigTrunk = curDesired["backSeatNotFull"];
          bool curDesiredBackSeatNotFull = curDesired["bigTrunk"];
          bool relDriveBackSeatNotFull = relDrive.backSeat;
          //back seat not full = true means: back seat is not full
          //back seat not full = false means: back seat is full!
          if ( (relDrive.bigTrunk || (!relDrive.bigTrunk && !curDesiredBigTrunk))
              && relDriveBackSeatNotFull || (!relDrive.backSeat && !curDesiredBackSeatNotFull)) {
            double distToStart = clacDis(
                curDesired["startPoint"], startPointCoords);
            double distToEnd = clacDis(
                curDesired["destPoint"], destPointCoords);
            relDrive.stops.forEach((key) {
              (key as Map).forEach((key, value) {
                if (key == "stopPoint") {
                  GeoPoint pointStop = value as GeoPoint;
                  distToStart =
                      min(distToStart, clacDis(pointStop, startPointCoords));
                  distToEnd =
                      min(distToEnd, clacDis(pointStop, destPointCoords));
                }
              });
            });
            int curDist = (distToStart + distToEnd).toInt();
            if (curDist <= maxDistance) {
              String curPassengerID = curDesired["passengerId"];
              await widget.db.collection("Notifications")
                  .doc(curPassengerID)
                  .collection("UserNotifications")
                  .add(
                  {
                    //Insert a desired notification to this person
                    "destCity": relDrive.destCity,
                    "startCity": relDrive.startCity,
                    "startAddress": curDesired["startAddress"],
                    "destAddress": curDesired["startAddress"],
                    "distance": curDist,
                    "driveId": relDrive.liftId,
                    "driverId": relDrive.driver,
                    "liftTime": relDrive.time,
                    "notificationTime": DateTime.now(),
                    "price": relDrive.price,
                    "type": "DesiredLift",
                    "read": "false",
                  }
              );
            }
          }
        }
      });
    return true;
    } catch(e){
      return false;
    }
  }



  @override
  Widget build(BuildContext context) {

    //checking if locations were chosen in the map widget
    void checkLocations(){
      _validateLocations = true;
      if (_startPointController.text == "") {
        _validateLocations = false;
      }
    }

    void checktimes() {
      _validateTime = true;

      if (_chosenTime == null) {
        _validateTime = false;
        _timeError = "Time not chosen";
      }
      else if (_chosenTime.isBefore(DateTime.now())){
        _validateTime = false;
        _timeError = "Time already passed";
        //_hourController.text = "";
      }
    }


    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpace = MediaQuery.of(context).size.height * 0.013;
    double defaultSpaceWidth = MediaQuery.of(context).size.height * 0.016;
    /*if(widget.time!=null) {
      _hourTime = widget.time;
      _hourController.text = DateFormat('dd-MM – kk:mm').format(widget.time);
      widget.time=null;
    }*/

    // if(_chosenTime !=null) {
    //   _chosenTime = widget.currentDate
    //       .subtract(new Duration(hours: widget.currentDate.hour))
    //       .add(new Duration(hours: DateTime.now().hour))
    //       .add(new Duration(minutes: DateTime.now().minutes));
    // }


    // final stopPoint1text_2 = Container(
    //   child: Row(
    //     children: [
    //       textBoxFieldDisable(
    //         nameLabel: "Stop 1:",
    //         size: MediaQuery.of(context).size,
    //         hintText: "",
    //         textFieldController: _stopPoint1Controller,
    //       ),
    //     ],
    //   ),
    // );
    // final stopPoint2text_2 = Container(
    //   child: Row(
    //     children: [
    //       textBoxFieldDisable(
    //         nameLabel: "Stop 2:",
    //         size: MediaQuery.of(context).size,
    //         hintText: "",
    //         textFieldController: _stopPoint2Controller,
    //       ),
    //     ],
    //   ),
    // );
    // final stopPoint3text_2 = Container(
    //   child: Row(
    //     children: [
    //       textBoxFieldDisable(
    //         nameLabel: "Stop 3:",
    //         size: MediaQuery.of(context).size,
    //         hintText: "",
    //         textFieldController: _stopPoint3Controller,
    //       ),
    //     ],
    //   ),
    // );

    final stopPoint1text = Stack(children: [
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchLabelText(
              text: "Stop 1: ",
            ),
            Expanded(child: generalInfoText(text: _stopPoint1Controller.text)),
            //SizedBox(height: 0.5 * defaultSpace),
          ],
        ),
      ),
    ]);

    final stopPoint2text = Stack(children: [
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchLabelText(
              text: "Stop 2: ",
            ),
            Expanded(child: generalInfoText(text: _stopPoint2Controller.text)),
          ],
        ),
      ),
    ]);

    final stopPoint3text = Stack(children: [
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchLabelText(
              text: "Stop 3: ",
            ),
            Expanded(child: generalInfoText(text: _stopPoint3Controller.text)),
          ],
        ),
      ),
    ]);


    final startPointText = Stack(children: [
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchLabelText(
              text: "Starting point: ",
            ),
            Expanded(child: generalInfoText(text: _startPointController.text)),
          ],
        ),
      ),
    ]);

    final destinationText = Stack(children: [
      Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchLabelText(
                text: "Destination: ",
              ),
              Expanded(child: generalInfoText(text: _destPointController.text)),
            ],
          )),
    ]);

    // final startPointText2 = Container(
    //   child: Row(
    //     children: [
    //       textBoxFieldDisable(
    //           nameLabel: "Start:",
    //           size: MediaQuery.of(context).size,
    //           hintText: "",
    //           textFieldController: _startPointController,
    //           validator: (value) {
    //             if (_startPointController == null ||
    //                 _startPointController.text == "") {
    //               return "No start point chosen";
    //             } else
    //               return null;
    //           }),
    //     ],
    //   ),
    // );

    // final destinationText2 = Container(
    //   child: Row(
    //     children: [
    //       textBoxFieldDisable(
    //           nameLabel: "Destination:",
    //           size: MediaQuery.of(context).size,
    //           hintText: "",
    //           textFieldController: _destPointController,
    //           validator: (value) {
    //             if (_destPointController == null ||
    //                 _destPointController.text == "") {
    //               return "No destination chosen";
    //             } else
    //               return null;
    //           }),
    //     ],
    //   ),
    // );

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

                  //After returning from the map widget,
                  //update the relevant stop addresses controllers
                  if (returnFromMapResult != null) {
                    stopAddressesList = [];
                    startAddress = returnFromMapResult.fromAddress;
                    destAddress = returnFromMapResult.toAddress;
                    _startPointController.text =
                        returnFromMapResult.fromAddress.addressLine;
                    _destPointController.text =
                        returnFromMapResult.toAddress.addressLine;
                    _numberOfStops = returnFromMapResult.numberOfStops;
                    if (_numberOfStops > 0) {
                      _stopPoint1Controller.text =
                          returnFromMapResult.stopAddresses[0].addressLine;
                      if (_numberOfStops > 1) {
                        _stopPoint2Controller.text =
                            returnFromMapResult.stopAddresses[1].addressLine;
                        if (_numberOfStops > 2) {
                          _stopPoint3Controller.text =
                              returnFromMapResult.stopAddresses[2].addressLine;
                        }
                      }
                    }
                    //Create the stop addresses map, that will later be added to the db
                    for(int i = 0; i<_numberOfStops; i++){
                      //String stopName = "Stop" + (i+1).toString();
                      Map mapToAdd = {'stopPoint' : GeoPoint(
                          returnFromMapResult.stopAddresses[i].coordinates.latitude,
                          returnFromMapResult.stopAddresses[i].coordinates.longitude),
                        'stopAddress' : returnFromMapResult.stopAddresses[i].addressLine.toString(),
                                      'stopCity' : returnFromMapResult.stopAddresses[i].locality};
                      stopAddressesList.add(mapToAdd);
                    }
                    checkLocations();
                  }
                });
              },
            ),
          ),
        ]);

    Map<int, Color> color =
    {
      50:Color.fromRGBO(136,14,79, .1),
      100:Color.fromRGBO(136,14,79, .2),
      200:Color.fromRGBO(136,14,79, .3),
      300:Color.fromRGBO(136,14,79, .4),
      400:Color.fromRGBO(136,14,79, .5),
      500:Color.fromRGBO(136,14,79, .6),
      600:Color.fromRGBO(136,14,79, .7),
      700:Color.fromRGBO(136,14,79, .8),
      800:Color.fromRGBO(136,14,79, .9),
      900:Color.fromRGBO(136,14,79, 1),
    };

    final dateChoose = Theme(
        data: ThemeData(
          // primaryColorLight: secondColor,
          primarySwatch:MaterialColor(0xff308ea1, color,),
          //    colorScheme: ColorScheme(primary:Colors.grey,primaryVariant:Colors.grey,onBackground: Colors.grey,background: Colors.grey,onPrimary: Colors.grey,secondary: Colors.grey,secondaryVariant: Colors.grey,surface: Colors.grey,onSurface: Colors.grey,error: Colors.grey,onError: Colors.grey,onSecondary: Colors.grey,brightness:Brightness.light ) ,
          //  primaryColor: myColor,
          // accentColor: secondColor,
          //  canvasColor: primaryColor,
          //  dialogBackgroundColor: primaryColor,
          backgroundColor: primaryColor,
          appBarTheme: AppBarTheme(color: Colors.pink),
          secondaryHeaderColor: primaryColor,
          dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              titleTextStyle: TextStyle(backgroundColor: myColor)),
        ),
        child:// Builder(
        //builder: (context) =>
        Stack(children: [
          DateTimePicker(
            decoration: InputDecoration(
              labelText: "Date",
              labelStyle: TextStyle(fontSize: 17,color:myColor),icon: Icon(Icons.event,color: myColor,),
              disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(width:1,color: myColor),),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(width:1,color: myColor),
              ),
            ),
            enableInteractiveSelection:false,
            cursorColor: Colors.grey,
            type: DateTimePickerType.date,
            dateMask: 'd MMM, yyyy',
            initialValue: widget.currentDate.toString(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
            icon: Icon(Icons.event),
            dateLabelText: 'Date',
            timeLabelText: "Hour",
            selectableDayPredicate: (date) {
              // Disable weekend days to select from the calendar
              return true;
            },
            onFieldSubmitted: (val) {
              print(val);
            },
            onChanged: (val) {
              setState(() {

                DateTime chosen = DateFormat('yyyy-mm-dd').parse(val);
                // if (_toTimeTemp != null) {
                //   _toTimeTemp = DateTime(
                //       e.year,
                //       e.month,
                //       e.day,
                //       _toTimeTemp.hour,
                //       _toTimeTemp.minute,
                //       _toTimeTemp.second,
                //       _toTimeTemp.millisecond,
                //       _toTimeTemp.microsecond);
                // }
                // if (_fromTimeTemp != null) {
                //   _fromTimeTemp = DateTime(
                //       e.year,
                //       e.month,
                //       e.day,
                //       _fromTimeTemp.hour,
                //       _fromTimeTemp.minute,
                //       _fromTimeTemp.second,
                //       _fromTimeTemp.millisecond,
                //       _fromTimeTemp.microsecond);
                // }

                if (_chosenTime != null) {
                  _chosenTime = DateTime(
                      chosen.year,
                      chosen.month,
                      chosen.day,
                      _chosenTime.hour,
                      _chosenTime.minute,
                      _chosenTime.second,
                      _chosenTime.millisecond,
                      _chosenTime.microsecond);
                }
                // if (_toTime != null) {
                //   _toTime = DateTime(
                //       e.year,
                //       e.month,
                //       e.day,
                //       _toTime.hour,
                //       _toTime.minute,
                //       _toTime.second,
                //       _toTime.millisecond,
                //       _toTime.microsecond);
                // }
                if (widget.currentDate != null) {
                  widget.currentDate = DateTime(
                      chosen.year,
                      chosen.month,
                      chosen.day,
                      widget.currentDate.hour,
                      widget.currentDate.minute,
                      widget.currentDate.second,
                      widget.currentDate.millisecond,
                      widget.currentDate.microsecond);
                }
                checktimes();
              });
            },
            validator: (val) {
              print(val);
              return null;
            },
            onSaved: (val) => print(val),
          ),
          //Container(color: Colors.transparent,child: SizedBox(width: 500,height: 100,),)
        ]
        )
      //  )
    );


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
                DateTime fixedTime = widget.currentDate
                    .subtract(new Duration(hours: widget.currentDate.hour))
                    .subtract(new Duration(minutes: widget.currentDate.minute))
                    .add(new Duration(hours: DateTime.now().hour))
                    .add(new Duration(minutes: DateTime.now().minute));

                showDialog(
                    context: context,
                    builder: (_) => new SimpleDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                          title: Center(
                              child: Text("Choose departure time",
                                  style: TextStyle(fontSize: 21))),
                          //content: Text("Hey!"),
                          children: [
                            TimePickerSpinner(
                              is24HourMode: true,
                              normalTextStyle:
                                  TextStyle(fontSize: 28, color: Colors.grey),
                              highlightedTextStyle:
                                  TextStyle(fontSize: 34, color: secondColor),
                              //spacing: 50,
                              //itemHeight: 80,
                              alignment: Alignment.center,
                              isForce2Digits: true,
                              minutesInterval: 5,
                              time:
                                  _chosenTime != null ? _chosenTime : fixedTime,
                              isShowSeconds: false,
                              onTimeChange: (time) {
                                setState(() {
                                  _chosenTimeCandidate = time;
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, //Center Row contents horizontally,
                              children: [
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
                                FlatButton(
                                  child: Text('CONFIRM',
                                      style: TextStyle(
                                          fontSize: 16, color: mainColor)),
                                  onPressed: () {
                                    _hourController.text =
                                        DateFormat('dd/MM - kk:mm')
                                            .format(_chosenTimeCandidate);
                                    _chosenTime = _chosenTimeCandidate;
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

    final chooseTime2 =
    Container(
      child: InkWell(
        child: TextField(
          maxLength: 30,
          decoration:  InputDecoration(
            icon: Icon(Icons.timer,color: myColor,),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1000.0),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(width:1,color: myColor),
            ),
            labelText: "Time",
            labelStyle: TextStyle(fontSize: 17,color:myColor),
          ),
          controller: _hourController,
          textCapitalization: TextCapitalization.sentences,
          //controller: controllerText,
          //  maxLines: maxLines,
          enabled: false,
        ),
        onTap: () {
          DateTime fixedTime = widget.currentDate
              .subtract(new Duration(hours: widget.currentDate.hour))
              .subtract(new Duration(minutes: widget.currentDate.minute))
              .add(new Duration(hours: DateTime.now().hour))
              .add(new Duration(minutes: DateTime.now().minute));

          showDialog(
              context: context,
              builder: (_) => new SimpleDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                title: Center(
                    child: Text("Choose departure time",
                        style: TextStyle(fontSize: 21))),
                //content: Text("Hey!"),
                children: [
                  TimePickerSpinner(
                    is24HourMode: true,
                    normalTextStyle:
                    TextStyle(fontSize: 28, color: Colors.grey),
                    highlightedTextStyle:
                    TextStyle(fontSize: 34, color: secondColor),
                    //spacing: 50,
                    //itemHeight: 80,
                    alignment: Alignment.center,
                    isForce2Digits: true,
                    minutesInterval: 5,
                    time:
                    _chosenTime != null ? _chosenTime : fixedTime,
                    isShowSeconds: false,
                    onTimeChange: (time) {
                      setState(() {
                        _chosenTimeCandidate = time;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, //Center Row contents horizontally,
                    children: [
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
                      FlatButton(
                        child: Text('CONFIRM',
                            style: TextStyle(
                                fontSize: 16, color: mainColor)),
                        // onPressed: () {
                        //   _hourController.text =
                        //   //DateFormat('dd/MM - kk:mm')
                        //   DateFormat('kk:mm')
                        //           .format(_chosenTimeCandidate);
                        //   _chosenTime = _chosenTimeCandidate;
                        //   checktimes();
                        //   Navigator.of(context).pop();
                        // },
                        onPressed: () {
                          setState(() {
                            _hourController.text =
                            //DateFormat('dd/MM - kk:mm')
                            DateFormat('kk:mm')
                                .format(_chosenTimeCandidate);
                            _chosenTime = _chosenTimeCandidate;
                            checktimes();
                            Navigator.of(context).pop();
                          });
                        },
                      )
                    ],
                  ),
                ],
              ));
        },
      ),
    );

    final timeText1 = Container(
      child: textBoxFieldDisableCentered(
          size: MediaQuery.of(context).size,
          hintText: "",
          textFieldController: _hourController,
          validator: (value) {
            if (_chosenTime == null)
              return '                             Time not chosen';
             else if (_chosenTime.isBefore(DateTime.now())){
              _hourController.text = "";
              return '                             Time already passed';
            }
            else
              return null;
          }),
    );

    // child: textBoxFieldDisableCentered(
    //     size: MediaQuery.of(context).size,
    //     hintText: "",
    //     textFieldController: _hourController,
    //     validator: (value) {
    //       // return '                               Time not chosen';
    //       if (_chosenTime == null)
    //         return 'Time not chosen';
    //       // else if (_chosenTime.isBefore(DateTime.now()))
    //       //   return 'Time already passed';
    //       else
    //         return null;
    //     }),

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
                  value: _bigTrunk,
                  onChanged: (bool value) {
                    setState(() {
                      _bigTrunk = value;
                    });
                  })),
        ],
      ),
    );

    final backSeatText = Container(
      height: 3 * defaultSpace,
      //height: MediaQuery.of(context).size.height,
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
                  value: _fullBackSeat,
                  onChanged: (bool value) {
                    setState(() {
                      _fullBackSeat = value;
                    });
                  })),
        ],
      ),
    );

    final noteToPassengersText = Container(
      height: 8.5 * defaultSpace,
      child: TextFormField(
        maxLength: 150,
        //150 characters for test purposes:
        //wordwordword1wordwordword2wordwordword3wordwordword4wordwordword5wordwordword6wordwordword7wordwordword8wordwordword9wordwordword10wordwordword11
        //maxLengthEnforced: true,
        controller: _noteController,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          //counterText: '',
          labelText: 'Note to passengers:',
          labelStyle: TextStyle(fontSize: _fontTextsSize),
        ),
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(150),
        ],
      ),
    );

    final priceText = Container(
      margin: EdgeInsets.only(right: defaultSpaceWidth * 18),
      width: defaultSpaceWidth * 8,
      child: TextFormField(
          //maxLengthEnforced: true,
          maxLength: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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
            if (value.isEmpty)
              return 'Enter price';
            else
              return null;
          }),
    );

    final backSeatRowText = Container(
      width: MediaQuery.of(context).size.width,
      height: 7 * defaultSpace,
      child: Row(
        children: [
          //priceText,
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
                    Colors.white, // background color for the dropdown items
                    buttonTheme: ButtonTheme.of(context).copyWith(
                      alignedDropdown:
                          true, //If false (the default), then the dropdown's menu will be wider than its button.
                    )),
                child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    elevation: 0,
                    value: _numberOfPassengers,
                    onChanged: (String newValue) {
                      setState(() {
                        _numberOfPassengers = newValue;
                      });
                    },
                    items: _passengers
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList())),
          ),
        ],
      ),
    );

    return Consumer<UserRepository>(builder: (context, userRep, child) {
      final setDrive = Container(
          height: defaultSpace * 4,
          padding: EdgeInsets.only(
              left: sizeFrameWidth * 0.23, right: sizeFrameWidth * 0.23),
          child: RaisedButton.icon(
              color: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.black)),
              icon: Icon(Icons.directions_car_sharp, color: Colors.white),
              label: Text("  Set Drive  ",
                  style: TextStyle(color: Colors.white, fontSize: 17)),
              onPressed: () async {
                setState(() {
                  checkLocations();
                  checktimes();
                });
                if (_formKey2.currentState.validate() && _validateLocations && _validateTime) {
                  try {

                    //for testing purposes:
                    //Random random = new Random();
                    // final String driveName =
                    //     "0_test_drive" + random.nextInt(1000).toString();
                    // final String driveName =
                    //     "0_test_" + DateTime.now().toString();
                    // await drives
                    //     .doc(driveName)
                    //     .set({

                    // CollectionReference drives = widget.db.collection('Drives');
                    // drives.add({

                    DocumentReference newDriveRef = await widget.db.collection('Drives').add({
                      'BackSeatNotFull': !(_fullBackSeat),
                      'BigTrunk': _bigTrunk,
                      'Note': _noteController.text,
                      'NumberSeats': int.parse(_numberOfPassengers),
                      'Price': int.parse(_priceController.text),

                      'StartAddress': startAddress.addressLine,
                      'StartCity': startAddress.locality,
                      'StartPoint': GeoPoint(
                          startAddress.coordinates.latitude,
                          startAddress.coordinates.longitude),

                      'DestAddress': destAddress.addressLine,
                      'DestCity': destAddress.locality,
                      'DestPoint': GeoPoint(destAddress.coordinates.latitude,
                          destAddress.coordinates.longitude),

                      'Stops' : stopAddressesList,

                      'Passengers': [],
                      'PassengersInfo': {},
                      'TimeStamp': _chosenTime,
                      'Driver': userRep.user.email,
                      //'Driver': "testing@technion.co.il",
                    });



                    //((element) async {
                    DocumentSnapshot currentDriveDoc = await widget.db.collection('Drives').doc(newDriveRef.id).get();
                    MyLift docLift = new MyLift(
                        "driver", "destAddress", "stopAddress", 5);
                    currentDriveDoc.data().forEach((key, value) {
                      if (value != null) {
                        docLift.setProperty(key, value);
                      }
                    });
                    docLift.liftId = currentDriveDoc.id;
                    // });

                    bool res = await _checkForFitDesiredAndSendNotifications(docLift);

                    FocusManager.instance.primaryFocus.unfocus();
                    Navigator.of(context).pop();
                    // .then((value) => Navigator.pop(context))
                    // .catchError((error) => print("Something went wrong. Please try again"));
                  }
                  catch(e){
                    _key2.currentState.showSnackBar(SnackBar(content: Text("Something went wrong. Please try again", style: TextStyle(fontSize: 19,color: Colors.red),)));
                  }

                }
              }));

      final preferences = Container(
          alignment: Alignment.bottomLeft,
          color: Colors.transparent,
          child: ConfigurableExpansionTile(
            header: Container(
                color: Colors.transparent,
                child: Text("Preferences",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            animatedWidgetFollowingHeader: const Icon(
              Icons.expand_more,
              color: const Color(0xFF707070),
            ),
            headerBackgroundColorStart: Colors.transparent,
            expandedBackgroundColor: Colors.transparent,
            headerBackgroundColorEnd: Colors.transparent,
            children: [
              bigTrunkText,
              SizedBox(height: defaultSpace),
              backSeatText,
              SizedBox(height: defaultSpace),
              noteToPassengersText,
            ],
          ));

      return Scaffold(
        key: _key2,
        appBar: AppBar(
          elevation: 0,
          title: Text("Set Drive", style: TextStyle(color: Colors.white)),
        ),
        body: Container(
          decoration: pageContainerDecoration,
          margin: pageContainerMargin,
          child: Form(
            key: _formKey2,
            child: Builder(
              builder: (context) => Container(
                  color: Colors.white,
                  margin: EdgeInsets.only(
                      left: defaultSpaceWidth,
                      top: defaultSpace / 6,
                      right: defaultSpaceWidth,
                      bottom: 10),
                  child: Column(
                    children: [
                      Expanded(
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

                                //       ...returnFromMapResult.stopAddresses.asMap().map((i, stop){
                                //       if(stop!=null){
                                //         return MapEntry(i, Container(
                                //           child: Row(
                                //             children: [
                                //               textBoxFieldDisable(
                                //                 nameLabel: "Stop " + i.toString() + ":", //Consider to edit,
                                //                 size: MediaQuery.of(context).size,
                                //                 hintText: "",
                                //                 textFieldController: _stopPoint1Controller,
                                //                 // validator: (value) {
                                //                 //   if(_startPointController==null || _startPointController.text==""){return "No start point chosen";}
                                //                 //   else return null;}
                                //               ),
                                //             ],
                                //           ),
                                //         ));
                                //       }
                                //       else
                                //         return MapEntry(i, Container());
                                //     }
                                // ).values.toList(),

                                SizedBox(height: 1.5 * defaultSpace),
                                chooseStartAndDestination,
                                SizedBox(height: 1.5 * defaultSpace),
                                startPointText,
                                SizedBox(height: 1.5 * defaultSpace),

                                _numberOfStops > 0
                                    ? stopPoint1text
                                    : Container(),
                                _numberOfStops > 1
                                    ? stopPoint2text
                                    : Container(),
                                _numberOfStops > 2
                                    ? stopPoint3text
                                    : Container(),
                                _numberOfStops > 0 ?
                                SizedBox(height: 1 * defaultSpace)
                                    : Container(),

                                destinationText,

                                _validateLocations
                                    ? Container() :
                                SizedBox(height: 1 * defaultSpace),
                                _validateLocations
                                ? SizedBox(height: 0 * defaultSpace)
                                    : Center(
                                child: Text(
                                "Choose start and destination",
                                style: TextStyle(color: Colors.red))),

                                // SizedBox(height: 1 * defaultSpace),
                                // Column(
                                //   mainAxisAlignment: MainAxisAlignment.center,
                                //   crossAxisAlignment: CrossAxisAlignment.center,
                                //   children: [
                                //     departureTimeButton,
                                //     timeText1,
                                //   ],
                                // ),
                                SizedBox(height: 1.5*defaultSpace),

                                dateChoose,
                                SizedBox(height: defaultSpace),
                                chooseTime2,
                                //Center(child:Row(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.start,children: [SizedBox(width: 10*defaultSpace,),Expanded(child:Times)],)),
                                // fromText,
                                //SizedBox(height: 0.5 * defaultSpace),
                                _validateTime
                                    ? SizedBox(height: 0 * defaultSpace)
                                    : Center(
                                    child: Text(_timeError,
                                        style:
                                        TextStyle(color: Colors.red))),
                                SizedBox(height: 1.3*defaultSpace),
                                priceText,
                                backSeatRowText,
                                //SizedBox(height: defaultSpace),
                                Divider(thickness: 3),
                                preferences,
                                Divider(thickness: 3),
                              ])
                        ]),
                      ),
                      SizedBox(height: 1 * defaultSpace),
                      setDrive,
                      SizedBox(height: 2 * defaultSpace),
                    ],
                  )),
            ),
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

Widget searchLabelText({@required String text}) {
  return Container(
    child: Text(
      text,
      style: TextStyle(fontSize: 17, color: Colors.black.withOpacity(0.6)),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}