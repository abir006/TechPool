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

// mail for testing purposes:
// ofir.asulin@campus.technion.ac.il

class SetDrivePage extends StatefulWidget {
  DateTime currentDate;
  FirebaseFirestore db = FirebaseFirestore.instance;
  SetDrivePage({Key key, @required this.currentDate}) : super(key: key);
  @override
  _SetDrivePageState createState() => _SetDrivePageState();
}

class _SetDrivePageState extends State<SetDrivePage> {
  final _formKey2 = GlobalKey<FormState>();
  final _key2 = GlobalKey<ScaffoldState>();
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

  LocationsResult returnFromMapResult;
  Address startAddress;
  Address destAddress;
  List<Map> stopAddressesList = [];

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

    void check_locations(){
      _validateLocations = true;
      if (_startPointController.text == "") {
        _validateLocations = false;
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

    /*if(widget.numberOfSeatsIndex!=null){
      _numberOfPassengers =_passengers[widget.numberOfSeatsIndex];
      widget.numberOfSeatsIndex = null;
    }*/

    final stopPoint1text = Container(
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
    final stopPoint2text = Container(
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
    final stopPoint3text = Container(
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

    final startPointText = Stack(children: [
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchLableText(
              text: "Start: ",
            ),
            Expanded(child: generalInfoText(text: _startPointController.text)),
          ],
        ),
      ),
      //  InkWell(
      //  onTap: (){},
      //Container(color:Colors.transparent,child:SizedBox(width: defaultSpace*8,height:defaultSpace*9,)),
    ]);

    final destinationText = Stack(children: [
      Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchLableText(
                text: "Destination: ",
              ),
              Expanded(child: generalInfoText(text: _destPointController.text)),
            ],
          )),
      // Container(color:Colors.transparent,child:SizedBox(width: defaultSpace*8,height:defaultSpace*10,)),
    ]);

    final startPointText2 = Container(
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

    final destinationText2 = Container(
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
                    for(int i = 0; i<_numberOfStops; i++){
                      //String stopName = "Stop" + (i+1).toString();
                      Map mapToAdd = {'stopPoint' : GeoPoint(
                          returnFromMapResult.stopAddresses[i].coordinates.latitude,
                          returnFromMapResult.stopAddresses[i].coordinates.longitude),
                        'stopAddress' : returnFromMapResult.stopAddresses[i].addressLine.toString(),
                                      'stopCity' : returnFromMapResult.stopAddresses[i].locality};
                      stopAddressesList.add(mapToAdd);
                    }
                    check_locations();
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
                DateTime fixedTime = widget.currentDate
                    .subtract(new Duration(hours: widget.currentDate.hour))
                    .add(new Duration(hours: DateTime.now().hour));

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

    final timeText1 = Container(
      child: textBoxFieldDisableCentered(
          size: MediaQuery.of(context).size,
          hintText: "",
          textFieldController: _hourController,
          validator: (value) {
            if (_chosenTime == null)
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
      height: 7.5 * defaultSpace,
      child: TextFormField(
        maxLength: 150,
        //150 characters for test purposes:
        //wordwordword1wordwordword2wordwordword3wordwordword4wordwordword5wordwordword6wordwordword7wordwordword8wordwordword9wordwordword10wordwordword11
        //maxLengthEnforced: true,
        controller: _noteController,
        decoration: InputDecoration(
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
                        mainColor, // background color for the dropdown items
                    buttonTheme: ButtonTheme.of(context).copyWith(
                      alignedDropdown:
                          true, //If false (the default), then the dropdown's menu will be wider than its button.
                    )),
                child: DropdownButton<String>(
                    dropdownColor: mainColor,
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
                //setState(() {
                  check_locations();
                //});
                if (_formKey2.currentState.validate() && _validateLocations) {
                  try {

                    //Random random = new Random();
                    // final String driveName =
                    //     "0_test_drive" + random.nextInt(1000).toString();
                    // final String driveName =
                    //     "0_test_" + DateTime.now().toString();
                    // await drives
                    //     .doc(driveName)
                    //     .set({

                    CollectionReference drives = widget.db.collection('Drives');
                    drives.add({
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

                    Navigator.pop(context);
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
                                SizedBox(height: 1.5 * defaultSpace),
                                chooseStartAndDestination,
                                startPointText,


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
                                SizedBox(height: 1 * defaultSpace),

                                _numberOfStops > 0
                                    ? stopPoint1text
                                    : Container(),
                                _numberOfStops > 1
                                    ? stopPoint2text
                                    : Container(),
                                _numberOfStops > 2
                                    ? stopPoint3text
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

                                SizedBox(height: 1 * defaultSpace),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    departureTimeButton,
                                    timeText1,
                                  ],
                                ),
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

Widget searchLableText({@required String text}) {
  return Container(
    child: Text(
      text,
      style: TextStyle(fontSize: 17, color: Colors.black.withOpacity(0.6)),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}