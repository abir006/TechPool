import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tech_pool/Utils.dart';
import 'package:tech_pool/pages/LocationSearch.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:geocoder/model.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:flutter/services.dart';

class SetDrivePage extends StatefulWidget {
  DateTime currentDate;
  //int numberOfSeatsIndex;
  //SetDrivePage({Key key,@required this.currentDate,this.time,this.numberOfSeatsIndex}): super(key: key);
  SetDrivePage({Key key, @required this.currentDate}) : super(key: key);
  @override
  _SetDrivePageState createState() => _SetDrivePageState();
}

class _SetDrivePageState extends State<SetDrivePage> {
  final _formKey = GlobalKey<FormState>();

  DateTime time;
  double _fontTextsSize = 17;
  DateTime _hourTime;
  DateTime _hourTimeCandidate;
  bool checkedBigTrunk = false;
  bool fullBackSeat = false;
  List<String> _passengers = ["1", "2", "3", "4", "5", "6"];
  String _numberOfPassengers = "3";
  TextEditingController _hourController;
  String noteToPassengers = "";

  TextEditingController _startPointController;
  TextEditingController _destPointController;
  LocationsResult returnResult;
  Address fromAddress;
  Address destAddress;
  //double _labelsTextsSize = 19;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(text: "");
    _startPointController = TextEditingController(text: "");
    _destPointController = TextEditingController(text: "");
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



    final stopPoint1text = Container(
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Stop 1',
          labelStyle: TextStyle(fontSize: _fontTextsSize),
        ),
      ),
    );
    final stopPoint2text = Container(
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Stop 2',
          labelStyle: TextStyle(fontSize: _fontTextsSize),
        ),
      ),
    );
    final stopPoint3text = Container(
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Stop 3',
          labelStyle: TextStyle(fontSize: _fontTextsSize),
        ),
      ),
    );

    // final startPointText = Container(
    //   child: TextFormField(
    //     decoration: InputDecoration(
    //       labelText: 'Start Point',
    //       labelStyle: TextStyle(fontSize: _fontTextsSize),
    //     ),
    //   ),
    // );

    // final destinationText = Container(
    //   child: TextFormField(
    //     decoration: InputDecoration(
    //       labelText: 'Destination',
    //       labelStyle: TextStyle(fontSize: _fontTextsSize),
    //     ),
    //   ),
    // );

    final startPointText = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
              nameLabel: "Start point:",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _startPointController,
              validator: (value) {
                if(_startPointController==null || _startPointController.text==""){return "No start point chosen";}
                else return null;}),
        ],
      ),
    );

    final destinationText = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
              nameLabel: "Destination point: ",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _destPointController,
              validator: (value) {
                if(_destPointController==null || _destPointController.text==""){return "No destination chosen";}
                else return null;}),
        ],
      ),
    );


    final chooseStartAndDestination =
    Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        child: RaisedButton.icon(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.black)),
          label: Text("Choose Start and Destination"),
          icon: Icon(Icons.map),
          onPressed: () async {
            returnResult = await Navigator.of(context).push(
                MaterialPageRoute<LocationsResult>(
                    builder: (BuildContext context) {
                      return LocationSearch(showAddStops: false);
                    },
                    fullscreenDialog: true
                ));
            setState(() {
              if (returnResult != null) {
                fromAddress = returnResult.fromAddress;
                destAddress = returnResult.toAddress;
                _startPointController.text =
                    returnResult.fromAddress.addressLine;
                _destPointController.text = returnResult.toAddress.addressLine;
              }
            });

          },
        ),
      ),
    ]);

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
              if (_formKey.currentState.validate()) {
                // Navigator.pushReplacement(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => LiftSearchReasultsPage(fromTime: _fromTime,toTime: _toTime, indexDist: _distances.indexOf(_maxDist)),
                //     ));
                Navigator.pop(context);
              }
            }));

    final deparatureTimeButton = Column(
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
                    builder: (_) =>
                    new SimpleDialog(
                      title: Center(child: Text("Choose departure time", style: TextStyle(fontSize:21))),
                      //content: Text("Hey! I'm Coflutter!"),
                      children:[
                        TimePickerSpinner(
                          is24HourMode: true,
                          normalTextStyle: TextStyle(fontSize: 28, color: Colors.grey),
                          highlightedTextStyle:  TextStyle(fontSize: 34, color: Colors.teal),
                          //spacing: 50,
                          //itemHeight: 80,
                          alignment: Alignment.center,
                          isForce2Digits: true,
                          minutesInterval: 5,
                          //time: _hourTime != null ? _hourTime : fixedTime,
                          time: _hourTime != null ? _hourTime : DateTime.now().add(new Duration(hours: 2)),
                          isShowSeconds: false,
                          onTimeChange: (time) {
                            setState(() {
                              _hourTimeCandidate = time;
                            });
                          },
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center, //Center Row contents horizontally,
                            children: [
                            //RaisedButton(
                            FlatButton(
                              child: Text('CANCEL', style: TextStyle(fontSize: 16, color: mainColor)),
                              onPressed: () {
                                setState(() {
                                  Navigator.of(context).pop();
                                });
                              },
                            ),
                            //SizedBox(width: 2*defaultSpaceWidth),
                            //RaisedButton(
                            FlatButton(
                              child: Text('CONFIRM', style: TextStyle(fontSize: 16, color: mainColor)),
                              onPressed: () {
                                _hourTime = _hourTimeCandidate;
                                _hourController.text = DateFormat('dd-MM – kk:mm').format(_hourTimeCandidate);
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        ),

                      ],
                    )
                );

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
                  value: checkedBigTrunk,
                  onChanged: (bool value) {
                    setState(() {
                      checkedBigTrunk = value;
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
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          LengthLimitingTextInputFormatter(4),
        ],
          validator: (value) {
            if (value.isEmpty) return 'Enter price';
            return null;
          }
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Set Drive", style: TextStyle(color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: Builder(
          builder: (context) => Container(
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
                      SizedBox(height: 1.5*defaultSpace),
                      chooseStartAndDestination,
                      startPointText,
                      SizedBox(height: defaultSpace),
                      //stopPoint1text,
                      // SizedBox(height: defaultSpace/3),
                      // stopPoint2text,
                      // SizedBox(height: defaultSpace/3),
                      // stopPoint3text,
                      destinationText,
                      SizedBox(height: 2*defaultSpace),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          deparatureTimeButton,
                          timeText1,
                          priceText,
                        ],
                      ),
                      // chooseTime,
                      // timeText2,
                      //Row(children: [chooseTime,timeText]),
                      //SizedBox(height: defaultSpace/2),

                      SizedBox(height: defaultSpace * 2),
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
  }

  @override
  void dispose() {
    _hourController.dispose();
    _startPointController.dispose();
    _destPointController.dispose();
    super.dispose();
  }
}
