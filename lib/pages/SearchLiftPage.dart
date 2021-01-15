import 'dart:ui';

import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder/model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tech_pool/Utils.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:dropdown_customizable/dropdown_customizable.dart';
import 'package:f_datetimerangepicker/f_datetimerangepicker.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/appValidator.dart';
import 'package:tech_pool/pages/LocationSearch.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:tech_pool/pages/LiftSearchReasultsPage.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class SearchLiftPage extends StatefulWidget {
  DateTime currentdate;
  DateTime fromtime;
  DateTime totime;
  Address startAd;
  Address destAd;
  int indexDis;
  bool bigTrunk;
  bool backSeat;
  bool popOrNot;
  SearchLiftPage(
      {Key key,
      @required this.currentdate,
      this.fromtime,
      this.totime,
      this.indexDis,
      this.startAd,
      this.destAd,
      this.bigTrunk,
      this.backSeat,
      this.popOrNot})
      : super(key: key);
  @override
  _SearchLiftPageState createState() => _SearchLiftPageState();
}

class _SearchLiftPageState extends State<SearchLiftPage> {
  final _formKey = GlobalKey<FormState>();
  final myColor = Color(0xfff808080);
  double _fontTextsSize = 17;
  double _lablesTextsSize = 19;
  String resultString;
  DateTime _fromTime = null;
  DateTime _toTime = null;
  DateTime _fromTimeTemp = null;
  DateTime _toTimeTemp = null;
  bool checkedBigTrunck = false;
  bool backSeatNotfull = false;
  List<String> _distances = ["1km", "5km", "20km", "40km"];
  String _maxDist = "20km";
  TextEditingController _fromControler;
  TextEditingController _toControler;
  TextEditingController _startPointControler;
  TextEditingController _destPointControler;
  LocationsResult returnResult = null;
  Address fromAddress;
  Address destAddress;
  bool checkpoints = true;
  bool checkPointError = false;
  int hasSpace = 0;
  bool _validateTime = true;
  bool _validateLocations = true;

  CalendarController _calendarController;
  List<String> _errors = [
    "Choose from and to time",
    "From time equal to to time",
    "The from time is after the to time",
    "The from time is before current time"
  ];
  int _indexError = 0;

  double _spaces = 0;

  @override
  void initState() {
    super.initState();
    _fromControler = TextEditingController(text: "No Time Chosen");
    _toControler = TextEditingController(text: "");
    _startPointControler = TextEditingController(text: "");
    _destPointControler = TextEditingController(text: "");
    _calendarController = CalendarController();
  }

  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpace = MediaQuery.of(context).size.height * 0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height * 0.016;
    if (widget.currentdate == null) widget.currentdate = DateTime.now();
    DateTime currentDate = DateTime(
        widget.currentdate.year,
        widget.currentdate.month,
        widget.currentdate.day,
        DateTime.now().hour,
        (DateTime.now().minute ~/ 5) * 5,
        DateTime.now().second,
        DateTime.now().millisecond,
        DateTime.now().microsecond);

    ///update all information from the caller page if there is any
    if (widget.totime != null) {
      _toTime = widget.totime;
      _toControler.text = DateFormat('kk:mm').format(widget.totime);
      widget.totime = null;
    }
    if (widget.fromtime != null) {
      _fromTime = widget.fromtime;
      _fromControler.text = DateFormat('kk:mm').format(widget.fromtime) +
          "-" +
          _toControler.text;
      widget.fromtime = null;
    }
    if (widget.indexDis != null) {
      _maxDist = _distances[widget.indexDis];
      widget.indexDis = null;
    }
    if (widget.startAd != null) {
      fromAddress = widget.startAd;
      _startPointControler.text = fromAddress.addressLine;
      widget.startAd = null;
    }

    if (widget.destAd != null) {
      destAddress = widget.destAd;
      _destPointControler.text = destAddress.addressLine;
      widget.destAd = null;
    }

    if (widget.backSeat != null) {
      backSeatNotfull = widget.backSeat;
      widget.backSeat = null;
    }

    if (widget.bigTrunk != null) {
      checkedBigTrunck = widget.bigTrunk;
      widget.bigTrunk = null;
    }

    void checklocations() {
      _validateLocations = true;
      if (_startPointControler.text == "") {
        _validateLocations = false;
      }
    }

    void checktimes() {
      _validateTime = true;
      if (_fromTime == null || _toTime == null) {
        _validateTime = false;
        _indexError = 0;
      } else {
        if ((_fromTime.hour > _toTime.hour) ||
            (_toTime.hour == _fromTime.hour &&
                _toTime.minute < _fromTime.minute)) {
          _validateTime = false;
          _indexError = 2;
        } else {
          if (_fromTime.hour == _toTime.hour &&
              _toTime.minute == _fromTime.minute) {
            _validateTime = false;
            _indexError = 1;
          } else if ((currentDate.compareTo(DateTime.now()) <= 0) &&
              (_fromTime.hour < DateTime.now().hour ||
                  (_fromTime.hour == DateTime.now().hour &&
                      _fromTime.minute < DateTime.now().minute))) {
            _validateTime = false;
            _indexError = 3;
          }
        }
      }
    }

    final startPointText = Stack(children: [
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchLableText(
              text: "Starting point: ",
            ),
            Expanded(child: generalInfoText(text: _startPointControler.text)),
          ],
        ),
      ),
    ]);

    final destinationText = Stack(children: [
      Container(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchLableText(
            text: "Destination: ",
          ),
          Expanded(child: generalInfoText(text: _destPointControler.text)),
        ],
      )),
      // Container(color:Colors.transparent,child:SizedBox(width: defaultSpace*8,height:defaultSpace*10,)),
    ]);

    final searchLift = Container(
        padding: EdgeInsets.only(
            left: sizeFrameWidth * 0.2, right: sizeFrameWidth * 0.2),
        height: defaultSpace * 4.5,
        child: RaisedButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Icon(Icons.search, color: Colors.white),
            label: Text("Search Lift  ",
                style: TextStyle(color: Colors.white, fontSize: 17)),
            onPressed: () {
              setState(() {
                checklocations();
                checktimes();
              });
              if (_validateLocations && _validateTime) {
                if (widget.popOrNot == false) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiftSearchReasultsPage(
                          fromTime: _fromTime,
                          toTime: _toTime,
                          indexDist: _distances.indexOf(_maxDist),
                          startAddress: fromAddress,
                          destAddress: destAddress,
                          bigTrunk: checkedBigTrunck,
                          backSeat: backSeatNotfull,
                        ),
                      ));
                } else {
                  Navigator.pop<liftRes>(
                      context,
                      liftRes(
                        fromTime: _fromTime,
                        toTime: _toTime,
                        indexDist: _distances.indexOf(_maxDist),
                        startAddress: fromAddress,
                        destAddress: destAddress,
                        bigTrunk: checkedBigTrunck,
                        backSeat: backSeatNotfull,
                      ));
                }
              }
            }));

    ///legacy clear button
    final clearButton = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: sizeFrameWidth * 0.1,
              child: RaisedButton.icon(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.black)),
                  icon: Icon(Icons.delete_outline),
                  label: Text("Delete"),
                  onPressed: () {}))
        ]);

    final chooseStartAndDestination = Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
                returnResult = await Navigator.of(context)
                    .push(MaterialPageRoute<LocationsResult>(
                        builder: (BuildContext context) {
                          return LocationSearch(showAddStops: false);
                        },
                        fullscreenDialog: true));
                setState(() {
                  if (returnResult != null) {
                    fromAddress = returnResult.fromAddress;
                    destAddress = returnResult.toAddress;
                    _startPointControler.text =
                        returnResult.fromAddress.addressLine;
                    _destPointControler.text =
                        returnResult.toAddress.addressLine;
                    checklocations();
                  }
                });
              },
            ),
          ),
        ]);

    final toTimePicker = TimePickerSpinner(
      is24HourMode: true,
      normalTextStyle: TextStyle(fontSize: 28, color: Colors.grey),
      highlightedTextStyle: TextStyle(fontSize: 34, color: secondColor),
      //spacing: 50,
      //itemHeight: 80,
      alignment: Alignment.center,
      isForce2Digits: true,
      minutesInterval: 5,
      //time: _hourTime != null ? _hourTime : fixedTime,
      time: _toTime != null ? _toTime : currentDate,
      isShowSeconds: false,
      onTimeChange: (time) {
        setState(() {
          _toTimeTemp = time;
        });
      },
    );

    final fromTimePicker = TimePickerSpinner(
      is24HourMode: true,
      normalTextStyle: TextStyle(fontSize: 28, color: Colors.grey),
      highlightedTextStyle: TextStyle(fontSize: 34, color: secondColor),
      //spacing: 50,
      //itemHeight: 80,
      alignment: Alignment.center,
      isForce2Digits: true,
      minutesInterval: 5,
      //time: _hourTime != null ? _hourTime : fixedTime,
      time: _fromTime != null ? _fromTime : currentDate,
      isShowSeconds: false,
      onTimeChange: (time) {
        setState(() {
          _fromTimeTemp = time;
        });
      },
    );

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

    ///Contains the two widgets from and to timer pickers
    final newChooseTime = DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: defaultSpace * 3,
          elevation: 0,
          leading: Container(),
          titleSpacing: 0,
          bottom: ColoredTabBar(
              Colors.white,
              TabBar(
                tabs: [
                  Text("From",
                      style: TextStyle(fontSize: 18, color: mainColor)),
                  Text("To", style: TextStyle(fontSize: 18, color: mainColor)),
                ],
              )),
        ),
        body: TabBarView(
          dragStartBehavior: DragStartBehavior.down,
          children: [
            fromTimePicker,
            toTimePicker,
          ],
        ),
      ),
    );
    final chooseDate =
        /*  Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.pink,
      ),
      child:  Builder(
        builder: (context) =>  InkWell(
          child: Container(
            child:Row(children:[
            Icon(Icons.calendar_today),
            ]),
          ),
          onTap: () => showDatePicker(
            context: context,
            initialDate: new DateTime.now(),
            firstDate:
            DateTime.now().subtract( Duration(days: 30)),
            lastDate:  DateTime.now().add( Duration(days: 30)),
          ),
        ),
      ),
    );*/
        /*RaisedButton.icon(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.black)),
        label: Text("Choose time"),
        icon: Icon(Icons.timer),
        onPressed: () {
          showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2025),
            builder: (context, child) {
              return Theme(
                data: ThemeData(primaryColor: secondColor,  accentColor: Colors.green,),
                child: child,
              );
            },
          );
        });*/

        Theme(
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
                        initialValue: currentDate.toString(),
                        firstDate: currentDate,
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

                          DateTime e = DateFormat('yyyy-mm-dd').parse(val);
                          if (_toTimeTemp != null) {
                            _toTimeTemp = DateTime(
                                e.year,
                                e.month,
                                e.day,
                                _toTimeTemp.hour,
                                _toTimeTemp.minute,
                                _toTimeTemp.second,
                                _toTimeTemp.millisecond,
                                _toTimeTemp.microsecond);
                          }
                          if (_fromTimeTemp != null) {
                            _fromTimeTemp = DateTime(
                                e.year,
                                e.month,
                                e.day,
                                _fromTimeTemp.hour,
                                _fromTimeTemp.minute,
                                _fromTimeTemp.second,
                                _fromTimeTemp.millisecond,
                                _fromTimeTemp.microsecond);
                          }

                          if (_fromTime != null) {
                            _fromTime = DateTime(
                                e.year,
                                e.month,
                                e.day,
                                _fromTime.hour,
                                _fromTime.minute,
                                _fromTime.second,
                                _fromTime.millisecond,
                                _fromTime.microsecond);
                          }
                            if (_toTime != null) {
                              _toTime = DateTime(
                                  e.year,
                                  e.month,
                                  e.day,
                                  _toTime.hour,
                                  _toTime.minute,
                                  _toTime.second,
                                  _toTime.millisecond,
                                  _toTime.microsecond);
                            }
                            if (currentDate != null) {
                              currentDate = DateTime(
                                  e.year,
                                  e.month,
                                  e.day,
                                  currentDate.hour,
                                  currentDate.minute,
                                  currentDate.second,
                                  currentDate.millisecond,
                                  currentDate.microsecond);
                            }
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

    final chooseTime2 =
     Container(
     // child: Row(
      //  children: [
          //Icon(Icons.timer,color: Color(0xfff686868),),
        //  SizedBox(width: 15,),
       //   Expanded(
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
                controller: _fromControler,
                textCapitalization: TextCapitalization.sentences,
                //controller: controllerText,
                //  maxLines: maxLines,
                enabled: false,
              ),
                onTap:() {
                  showDialog(
                      context: context,
                      builder: (_) => new SimpleDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(20.0))),
                        backgroundColor: Colors.white,
                        children: [
                          Container(
                              height: defaultSpace * 30,
                              width: defaultSpace * 30,
                              child: newChooseTime),
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
                                  setState(() {
                                    if (_fromTimeTemp == null)
                                      _fromTimeTemp = currentDate;
                                    if (_toTimeTemp == null)
                                      _toTimeTemp = (_toTime != null
                                          ? _toTime
                                          : currentDate);
                                    _fromTime = _fromTimeTemp;
                                    _toTime = _toTimeTemp;
                                    _toControler.text =
                                        DateFormat('kk:mm').format(_toTime);
                                    _fromControler.text =
                                        DateFormat('kk:mm')
                                            .format(_fromTime) +
                                            " - " +
                                            _toControler.text;
                                    checktimes();
                                  });
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          ),
                        ],
                      ));
                },
            ),
          );
      //  ],
     // ),
   // );
    ///the chooseTime button
    final chooseTime = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              child: RaisedButton.icon(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.black)),
                label: Text("Choose time"),
                icon: Icon(Icons.timer),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (_) => new SimpleDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20.0))),
                            backgroundColor: Colors.white,
                            children: [
                              Container(
                                  height: defaultSpace * 30,
                                  width: defaultSpace * 30,
                                  child: newChooseTime),
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
                                      setState(() {
                                        if (_fromTimeTemp == null)
                                          _fromTimeTemp = currentDate;
                                        if (_toTimeTemp == null)
                                          _toTimeTemp = (_toTime != null
                                              ? _toTime
                                              : currentDate);
                                        _fromTime = _fromTimeTemp;
                                        _toTime = _toTimeTemp;
                                        _toControler.text =
                                            DateFormat('kk:mm').format(_toTime);
                                        _fromControler.text =
                                            DateFormat('kk:mm')
                                                    .format(_fromTime) +
                                                " - " +
                                                _toControler.text;
                                        checktimes();
                                      });
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
          ),
          //  Text(resultString ?? "")
        ]);

    final fromText = Container(
      child: Stack(children: [
        labelText(text: "Time:"),
        Center(child: generalInfoText(text: _fromControler.text))
      ]),
    );

    final bigTruncText = Container(
      height: 4 * defaultSpace,
      child: Row(
        children: [
          Text(
            'Big trunk: ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
          Theme(
              data: ThemeData(unselectedWidgetColor: secondColor),
              child: Checkbox(
                  value: checkedBigTrunck,
                  onChanged: (bool value) {
                    setState(() {
                      checkedBigTrunck = value;
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
            'Backseat not full: ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
          Theme(
              data: ThemeData(unselectedWidgetColor: secondColor),
              child: Checkbox(
                  value: backSeatNotfull,
                  onChanged: (bool value) {
                    setState(() {
                      backSeatNotfull = value;
                    });
                  })),
        ],
      ),
    );

    final maxDistance = Container(
      height: 4 * defaultSpace,
      child: Row(
        children: [
          Text(
            'Max Distance:  ',
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
                    value: _maxDist,
                    onChanged: (String newValue) {
                      setState(() {
                        _maxDist = newValue;
                      });
                    },
                    items: _distances
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

    ///The container that contains all the preference of the user
    final prefer = Container(
        alignment: Alignment.bottomLeft,
        color: Colors.transparent,
        child: ConfigurableExpansionTile(
          header: Container(
              color: Colors.transparent,
              child: Text("Preferences",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
          animatedWidgetFollowingHeader: const Icon(
            Icons.expand_more,
            color: const Color(0xFF707070),
          ),
          headerBackgroundColorStart: Colors.transparent,
          expandedBackgroundColor: Colors.transparent,
          headerBackgroundColorEnd: Colors.transparent,
          //tilePadding: EdgeInsets.symmetric(horizontal: 0),
          // backgroundColor: Colors.white,
          // trailing: Icon(Icons.arrow_drop_down,color: Colors.black,),
          //title: Text("Passenger info"),
          children: [
            bigTruncText,
            backSeatText,
            maxDistance,
          ],
        ));
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Search Lift",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Form(
            key: _formKey,
            child: Builder(
                builder: (context) => Container(
                      decoration: pageContainerDecoration,
                      margin: pageContainerMargin,
                      child: Column(children: [
                        Expanded(
                            child: Stack(children: [
                          Container(
                              child: Center(
                                  child: Transform.rotate(
                                      angle: 0.8,
                                      child: Icon(
                                        Icons.thumb_up_rounded,
                                        size: 300,
                                        color: Colors.cyan.withOpacity(0.1),
                                      )))),
                          ListView(
                              padding: EdgeInsets.only(
                                  left: defaultSpacewidth,
                                  right: defaultSpacewidth,
                                  bottom: defaultSpacewidth),
                              children: [
                                SizedBox(height: defaultSpace),
                                chooseStartAndDestination,
                                SizedBox(height: 2 * defaultSpace),
                                startPointText,
                                SizedBox(height: 2 * defaultSpace),
                                destinationText,
                                SizedBox(height: 2 * defaultSpace),
                                _validateLocations
                                    ? SizedBox(height: 0 * defaultSpace)
                                    : Center(
                                        child: Text(
                                            "Choose start and destination",
                                            style:
                                                TextStyle(color: Colors.red))),
                            //    SizedBox(height: defaultSpace),
                           //     Divider(
                            //      thickness: 3,
                            //    ),
                             //   SizedBox(height: defaultSpace),
                                chooseDate,
                                SizedBox(height: defaultSpace),
                                chooseTime2,
                                //Center(child:Row(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.start,children: [SizedBox(width: 10*defaultSpace,),Expanded(child:Times)],)),
                               // fromText,
                                SizedBox(height: 0.5 * defaultSpace),
                                _validateTime
                                    ? SizedBox(height: 0 * defaultSpace)
                                    : Center(
                                        child: Text(_errors[_indexError],
                                            style:
                                                TextStyle(color: Colors.red))),
                                SizedBox(height: defaultSpace),
                                SizedBox(height: defaultSpace),
                                Divider(
                                  thickness: 1.5,
                                ),
                                prefer,
                                Divider(
                                  thickness: 1.5,
                                ),
                              ])
                        ])),
                        searchLift,
                        SizedBox(height: 2 * defaultSpace),
                      ]),
                      // searchLift,
                    ))),
      ),
      backgroundColor: mainColor,
    );
  }

  showAlertDialog(BuildContext context, String title) {
    Widget okButton = FlatButton(
      textColor: mainColor,
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );

    Widget cancelButton = FlatButton(
      textColor: mainColor,
      child: Text("Dismiss"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      title: Text(title),
      content: Container(
        height: 200,
        width: 200,
        child: TableCalendar(
          startDay: DateTime.now(),
          initialSelectedDay: DateTime.now(),
          daysOfWeekStyle:
              DaysOfWeekStyle(weekdayStyle: TextStyle(color: secondColor)),
          calendarStyle: CalendarStyle(
              markersColor: secondColor,
              selectedColor: mainColor,
              todayColor: mainColor[100]),
          weekendDays: [5, 6],
          calendarController: _calendarController,
          availableCalendarFormats: {
            CalendarFormat.month: 'Week',
            CalendarFormat.week: 'Month'
          },
        ),
      ),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  void dispose() {
    _fromControler.dispose();
    _toControler.dispose();
    _startPointControler.dispose();
    _destPointControler.dispose();
    _calendarController.dispose();
    super.dispose();
  }
}

class ColoredTabBar extends Container implements PreferredSizeWidget {
  ColoredTabBar(this.color, this.tabBar);

  final Color color;
  final TabBar tabBar;

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        child: tabBar,
      );
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
