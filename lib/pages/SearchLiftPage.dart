import 'dart:ui';

import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:geocoder/model.dart';
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
    _fromControler = TextEditingController(text: "");
    _toControler = TextEditingController(text: "");
    _startPointControler = TextEditingController(text: "");
    _destPointControler = TextEditingController(text: "");
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
        (DateTime.now().minute~/5)*5,
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
      _fromControler.text = DateFormat('dd/MM  kk:mm').format(widget.fromtime) +
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

    void checklocations(){
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
        }
        else {
          if (_fromTime.hour == _toTime.hour &&
              _toTime.minute == _fromTime.minute) {
            _validateTime = false;
            _indexError = 1;
          }
          else if ((currentDate.compareTo(DateTime.now())<=0) && (_fromTime.hour<DateTime.now().hour || (_fromTime.hour==DateTime.now().hour && _fromTime.minute<DateTime.now().minute)) ) {
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

    ///Contains the two widgets from and to timer pickers
    final newChooseTime = DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: defaultSpace * 2.8,
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
                                            DateFormat('dd/MM  kk:mm')
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
          child:Stack(
            children:[labelText(text:"Time:"), Center(child:generalInfoText(text: _fromControler.text))
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
      body: Form(
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
                              SizedBox(height: 2* defaultSpace),
                              startPointText,
                              SizedBox(height: 2 * defaultSpace),
                              destinationText,
                              SizedBox(height: 2*defaultSpace),
                              _validateLocations
                                  ? SizedBox(height: 0 * defaultSpace)
                                  : Center(
                                      child: Text(
                                          "Choose start and destination",
                                          style: TextStyle(color: Colors.red))),
                              SizedBox(height: defaultSpace),
                              Divider(
                                thickness: 3,
                              ),
                              SizedBox(height:  defaultSpace),
                              chooseTime,
                              //Center(child:Row(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.start,children: [SizedBox(width: 10*defaultSpace,),Expanded(child:Times)],)),
                              fromText,
                              SizedBox(height: 0.5 * defaultSpace),
                              _validateTime
                                  ? SizedBox(height: 0 * defaultSpace)
                                  : Center(
                                      child: Text(_errors[_indexError],
                                          style: TextStyle(color: Colors.red))),
                              SizedBox(height: defaultSpace),
                              SizedBox(height: defaultSpace),
                              Divider(
                                thickness: 3,
                              ),
                              prefer,
                              Divider(
                                thickness: 3,
                              ),
                            ])
                      ])),
                      searchLift,
                      SizedBox(height: 2 * defaultSpace),
                    ]),
                    // searchLift,
                  ))),
      backgroundColor: mainColor,
    );
  }

  @override
  void dispose() {
    _fromControler.dispose();
    _toControler.dispose();
    _startPointControler.dispose();
    _destPointControler.dispose();
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
