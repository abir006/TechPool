import 'dart:ui';

import 'package:configurable_expansion_tile/configurable_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:geocoder/model.dart';
import 'package:tech_pool/Utils.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:dropdown_customizable/dropdown_customizable.dart';
import 'package:f_datetimerangepicker/f_datetimerangepicker.dart';
import 'package:intl/intl.dart';
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
  SearchLiftPage({Key key,@required this.currentdate,this.fromtime,this.totime,this.indexDis, this.startAd, this.destAd, this.bigTrunk, this.backSeat, this.popOrNot}): super(key: key);
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
  List<String> _distances = ["1km","5km","20km","40km"];
  String _maxDist ="20km";
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
    double defaultSpace = MediaQuery.of(context).size.height*0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height*0.016;
    if(widget.currentdate == null) widget.currentdate = DateTime.now();
    DateTime currentDate = DateTime(widget.currentdate.year,widget.currentdate.month,widget.currentdate.day,DateTime.now().hour+2,DateTime.now().minute,DateTime.now().second,DateTime.now().millisecond,DateTime.now().microsecond);
    if( widget.totime!=null) {
      _toTime = widget.totime;
      _toControler.text = DateFormat('kk:mm').format(widget.totime);
      widget.totime=null;
    }
    if(widget.fromtime!=null) {
      _fromTime = widget.fromtime;
      _fromControler.text = DateFormat('dd/MM  kk:mm').format(widget.fromtime)+"-"+_toControler.text;
      widget.fromtime=null;
    }
    if(widget.indexDis!=null){
      _maxDist =_distances[widget.indexDis];
       widget.indexDis = null;
    }
    if(widget.startAd!=null){
      fromAddress=widget.startAd;
      _startPointControler.text = fromAddress.addressLine;
      widget.startAd = null;
    }

    if(widget.destAd!=null){
      destAddress=widget.destAd;
      _destPointControler.text = destAddress.addressLine;
      widget.destAd = null;
    }

    if(widget.backSeat!=null){
      backSeatNotfull = widget.backSeat;
      widget.backSeat = null;
    }

    if(widget.bigTrunk!=null){
      checkedBigTrunck = widget.bigTrunk;
      widget.bigTrunk = null;
    }

    final locationText = Center(
        child: Container(
      child: Text(
        'Locations',
        style:
            TextStyle(fontSize: _lablesTextsSize, fontWeight: FontWeight.bold),
      ),
    ));

    final timeText = Center(
        child: Container(
      child: Text(
        'Times',
        style:
            TextStyle(fontSize: _lablesTextsSize, fontWeight: FontWeight.bold),
      ),
    ));

    final preferenceTexts = Center(
        child: Container(
          child: Text(
            'Preferences',
            style:
            TextStyle(fontSize: _lablesTextsSize, fontWeight: FontWeight.bold),
          ),
        ));


    final startPointText = Stack(children:[
        Container(
      child: Row(
        children: [
          textBoxFieldDisable(
              nameLabel: "Start point : ",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _startPointControler,
              validator: (value) {
                if(checkpoints && (_startPointControler==null || _startPointControler.text=="")){checkPointError=true;return "No start point chosen";}
                else {checkPointError=false;return null;}}),
        ],
      ),
    ),
      InkWell(
          onTap: (){},
          child:Container(color:Colors.transparent,child:SizedBox(width: defaultSpace*8,height:defaultSpace*8,))),
    ]);

    final destinationText =  Stack(children:[Container(
      child: Row(
        children: [
          textBoxFieldDisable(
              nameLabel: "Destination point: ",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _destPointControler,
              validator: (value) {
                if(checkpoints &&(_destPointControler==null || _destPointControler.text=="")){return "No destination chosen";}
                else return null;}),
        ],
      )),
      InkWell(
          onTap: (){},
          child:Container(color:Colors.transparent,child:SizedBox(width: defaultSpace*8,height:defaultSpace*8,))),
    ]);

    final searchLift =
      Container(
          padding: EdgeInsets.only(left: sizeFrameWidth*0.2, right:sizeFrameWidth*0.2) ,
        height: 40,
        child: RaisedButton.icon(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            icon: Icon(Icons.search,color: Colors.white) ,
            label: Text("Search Lift  ",style: TextStyle(color: Colors.white,fontSize: 17)),
            onPressed: () {
              if (_formKey.currentState.validate()) {
                if(widget.popOrNot==false) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LiftSearchReasultsPage(fromTime: _fromTime,
                              toTime: _toTime,
                              indexDist: _distances.indexOf(_maxDist),
                              startAddress: fromAddress,
                              destAddress: destAddress,
                              bigTrunk: checkedBigTrunck,
                              backSeat: backSeatNotfull,),
                      ));
                }else{
                  Navigator.pop<liftRes>(
                      context, liftRes(
                    fromTime: _fromTime,
                    toTime: _toTime,
                    indexDist: _distances.indexOf(_maxDist),
                    startAddress: fromAddress,
                    destAddress: destAddress,
                    bigTrunk: checkedBigTrunck,
                    backSeat: backSeatNotfull,));
                }
              }
            }
        ));

    final clearButton =Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start, children: [ SizedBox(
        width: sizeFrameWidth*0.1,
        child: RaisedButton.icon(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.black)),
        icon: Icon(Icons.delete_outline) ,
        label: Text("Delete"),
        onPressed: () {}
    ))]);

    final chooseStartAndDestination =
    Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                  _startPointControler.text =
                      returnResult.fromAddress.addressLine;
                  _destPointControler.text = returnResult.toAddress.addressLine;
                }
              });

          },
        ),
      ),
    ]);


    final toTimePicker = TimePickerSpinner(
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
      time: _toTime != null
          ? _toTime
          : currentDate,
      isShowSeconds: false,
      onTimeChange: (time) {
        setState(() {
          _toTimeTemp = time;
        });
      },
    );

    final fromTimePicker = TimePickerSpinner(
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
      time: _fromTime != null
          ? _fromTime
          : currentDate,
      isShowSeconds: false,
      onTimeChange: (time) {
        setState(() {
          _fromTimeTemp = time;
        });
      },
    );

    final newChooseTime = DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 23,
          leading: Container(),
          titleSpacing: 0,
          bottom: ColoredTabBar(Colors.white,TabBar(
            tabs: [
              Text("From",style:TextStyle(fontSize: 18, color: mainColor)),
              Text("To",style:TextStyle(fontSize: 18, color: mainColor)),
            ],
          )),
        ),
        body: TabBarView(
          children: [
            fromTimePicker,
            toTimePicker,
          ],
        ),
      ),
    );
/*
    final chooseTime2 = showDialog(
        context: context,
        builder: (_) => new SimpleDialog(
          title: Center(
              child: Text("Choose from and to time",
                  style: TextStyle(fontSize: 21))),
         /* children: [//newChooseTime,
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
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          ],*/
        ));
*/
    final chooseTime =
    Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        backgroundColor:Colors.white,
                       children: [Container(height: defaultSpace*25,width:defaultSpace*30,child:newChooseTime),
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
                       if(_fromTimeTemp==null) _fromTimeTemp=currentDate;
                       if(_toTimeTemp==null) _toTimeTemp =_toTime!=null?_toTime:_fromTimeTemp;
                       _fromTime=_fromTimeTemp;
                       _toTime = _toTimeTemp;
                        _toControler.text = DateFormat('kk:mm').format(_toTime);
                       _fromControler.text = DateFormat('dd/MM  kk:mm').format(_fromTime)+" - "+ _toControler.text;
                        if(_fromTime==null || ((_fromTime.hour >_toTime.hour) || (_toTime.hour == _fromTime.hour && _toTime.minute < _fromTime.minute )) ||
                         (_fromTime.hour ==_toTime.hour && _toTime.minute == _fromTime.minute)){
                        hasSpace=2;
                        }else{
                          hasSpace=0;
                        }
                        if(!checkPointError) checkpoints = false;
                        _formKey.currentState.validate();
                        checkpoints = true;
                      });
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            ],
                    ));
                /*
                DateTimeRangePicker(
                    startText: "From",
                    endText: "To",
                    doneText: "Yes",
                    cancelText: "Cancel",
                    interval: 5,
                    initialStartTime: (_fromTime!=null)?_fromTime:widget.currentdate,
                    initialEndTime: (_fromTime!=null)?_toTime:widget.currentdate.add(Duration(days: 0,hours: 0,minutes: 0,microseconds: 0)),
                    mode: DateTimeRangePickerMode.time,
                    minimumTime: DateTime.now().subtract(Duration(days: 2,hours: 1,minutes: 0,microseconds: 0)),
                    maximumTime: DateTime.now().add(Duration(days: 7)),
                    use24hFormat: true,
                    onConfirm: (start, end) {
                      setState(() {
                      _fromTime=start;
                      _fromMinutes =start.minute.toString();
                      if(_fromTime.minute<10){
                        _fromMinutes ="0"+start.minute.toString();
                      }
                      _toTime=end;
                      _fromControler.text = DateFormat('dd-MM – kk:mm').format(start);
                      _toControler.text = DateFormat('dd-MM – kk:mm').format(end);
                      _formKey.currentState.validate();
                      });
                    }).showPicker(context);*/
              },
            ),
          ),
        ),
      //  Text(resultString ?? "")
      ]);

    final fromText = Container(
      child: textBoxFieldDisableCentered(
              nameLabel: "",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _fromControler,
              validator: (value) {
                if(_fromTime==null ||  _toTime==null){return '                                      No of time selected';}
                else  if ((_fromTime.hour >_toTime.hour) || (_toTime.hour == _fromTime.hour && _toTime.minute < _fromTime.minute )) {return '                             The from time is after the to Time';}
                else if(_fromTime.hour ==_toTime.hour && _toTime.minute == _fromTime.minute ){return '                                 From time equal to to time';}
                else return null;}),
    );


    final toText = Container(
          child:textBoxFieldDisable(
              nameLabel: "hi",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _toControler,
              validator: (value) {
                if(_fromTime==null ){return 'No to time selected';}
              else  if ((_fromTime.hour >_toTime.hour) || (_toTime.hour == _fromTime.hour && _toTime.minute < _fromTime.minute )) {return 'The to time is before the from time ';}
              else if(_fromTime.hour ==_toTime.hour && _toTime.minute == _fromTime.minute ){return 'To time equal from time ';}
              else return null;}),
        );

    final bigTruncText = Container(
      height:4*defaultSpace,
      child: Row(
        children: [
          Text(
            'Big trunk: ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
      Theme(
        data: ThemeData(unselectedWidgetColor: secondColor),
         child: Checkbox(value: checkedBigTrunck, onChanged: (bool value){
    setState(() {checkedBigTrunck = value;});})),
        ],
      ),
    );

    final backSeatText = Container(
      height:4*defaultSpace,
      child: Row(
        children: [
          Text(
            'Backseat not full: ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
      Theme(
        data: ThemeData(unselectedWidgetColor: secondColor),
          child:Checkbox(value: backSeatNotfull, onChanged: (bool value) {
            setState(() {backSeatNotfull = value;});})),
        ],
      ),
    );

    final maxDistance = Container(
      height:4*defaultSpace,
      child: Row(
        children: [
          Text(
            'Max Distance:  ',
            style: TextStyle(
                fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
          ),
      Container(
        color: Colors.transparent,
      child:Theme(
          data: Theme.of(context).copyWith(
              canvasColor: Colors.white, // background color for the dropdown items
              buttonTheme: ButtonTheme.of(context).copyWith(
                alignedDropdown: true,  //If false (the default), then the dropdown's menu will be wider than its button.
              )
          ),
          child:DropdownButton<String>(
            dropdownColor: Colors.white,
        elevation: 0,
        value: _maxDist,
        onChanged: (String newValue) {
          setState(() {
            _maxDist = newValue;
          });
        },
        items: _distances.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList())),
      )],
      ),
    );
    final prefer = Container(
        alignment: Alignment.bottomLeft,
        color:Colors.transparent,
        child:ConfigurableExpansionTile(
          header: Container(color: Colors.transparent,child: Text("Preferences",style:TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
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
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Search Lift",style: TextStyle(color:Colors.white),),
      ),
      body:  Form(
        key: _formKey,
        child: Builder(
          builder: (context) => Container(
              color: Colors.white,
              margin: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth, bottom: defaultSpacewidth),
              child: Column( children: [ Expanded(child: Stack(children:[Container( child:Center(child:Transform.rotate(angle: 0.8,child:Icon(Icons.thumb_up_rounded,size:300,color:  Colors.cyan.withOpacity(0.1),)))),
                ListView(
                  padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth, bottom: defaultSpacewidth),
                  children: [
                    //SizedBox(height: defaultSpace),
                   // locationText,
                    SizedBox(height: defaultSpace),
                    chooseStartAndDestination,
                    SizedBox(height: defaultSpace),
                    startPointText,
                    destinationText,
                    //SizedBox(height: 2*defaultSpace),
                    //timeText,
                    SizedBox(height: defaultSpace),
                    chooseTime,
                    SizedBox(height: hasSpace*defaultSpace),
                    //Center(child:Row(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.start,children: [SizedBox(width: 10*defaultSpace,),Expanded(child:Times)],)),
                    fromText,
                    //fromText,
                    //SizedBox(height: defaultSpace),
                    //toText,
                    SizedBox(height: defaultSpace),
                    //SizedBox(height: defaultSpace),
                    //preferenceTexts,
                    SizedBox(height: defaultSpace),
                    Divider(thickness: 3,),
                    prefer,
                    Divider(thickness: 3,),
                    //SizedBox(height:2*defaultSpace),
                  ])])),
                searchLift,
                SizedBox(height: 2*defaultSpace),
              ]),
           // searchLift,
    )) ),
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
/*
  Widget dropDownButtonsColumn(List<String> list, String hint){
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40 , bottom: 24,top:12),
      child: Container(//gives the height of the dropdown button
        height: 55,
        width: MediaQuery.of(context).size.width*0.4, //gives the width of the dropdown button
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(3)),
            color: Color(0xFFF2F2F2)
        ),
         padding:  const EdgeInsets.only(bottom: 24,top:12), //you can include padding to control the menu items
        child: Theme(
            data: Theme.of(context).copyWith(
                canvasColor: Colors.yellowAccent, // background color for the dropdown items
                buttonTheme: ButtonTheme.of(context).copyWith(
                  alignedDropdown: true,  //If false (the default), then the dropdown's menu will be wider than its button.
                )
            ),
            child: DropdownButtonHideUnderline(  // to hide the default underline of the dropdown button
              child: DropdownButton<String>(
                isExpanded: true,
                iconEnabledColor: Color(0xFF595959),  // icon color of the dropdown button
                items: list.map((String value){
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                      style: TextStyle(
                          fontSize: 15
                      ),
                    ),
                  );
                }).toList(),
                hint: Text(hint,style: TextStyle(color: Color(0xFF8B8B8B),fontSize: 15),),  // setting hint
                onChanged: (String value){
                  setState(() {
                    _fromTimec = value;  // saving the selected value
                  });
                },
                value: _fromTimec,  // displaying the selected value
              ),
            )
        ),
      ),
    );
  }
*/
/*
class _SearchLiftForm extends StatefulWidget {
  @override
  _SearchLiftFormState createState() => _SearchLiftState();
}

class _MyForm extends State<SearchLift> {
  final _formKey = GlobalKey<FormState>();
  static double _fontTextsSize = 17;
  static double _lablesTextsSize = 19;
  static String _fromTime = "";

  static List<String> country = [
    "America",
    "Brazil",
    "Canada",
    "India",
    "Mongalia",
    "USA",
    "China",
    "Russia",
    "Germany"
  ];

  final locationText = Center(
      child: Container(
    child: Text(
      'Locations',
      style: TextStyle(fontSize: _lablesTextsSize, fontWeight: FontWeight.bold),
    ),
  ));

  final timeText = Center(
      child: Container(
    child: Text(
      'Times',
      style: TextStyle(fontSize: _lablesTextsSize, fontWeight: FontWeight.bold),
    ),
  ));

  final startPointText = Container(
    child: TextFormField(
      decoration: InputDecoration(
        labelText: 'Starting point',
        labelStyle: TextStyle(fontSize: _fontTextsSize),
      ),
    ),
  );

  final destinationText = Container(
    child: TextFormField(
      decoration: InputDecoration(
        labelText: 'Destination point',
        labelStyle: TextStyle(fontSize: _fontTextsSize),
      ),
    ),
  );

  final fromText = Container(
    child: Row(
      children: [
        Text(
          'From:',
          style: TextStyle(
              fontSize: _fontTextsSize, color: Colors.black.withOpacity(0.6)),
        ),
        SizedBox(width: 10),
        SizedBox(
          width:150,
          child:  DropdownButton(
            value: '_fromTime',
            onChanged: (String newValue) {
              setState(() {
                dropdownValue = newValue;
              });
            },
            required: false,
            hintText: 'Choose a time',
            items: country,
          ),
          )),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Builder(
        builder: (context) => Container(
            color: Colors.white,
            margin: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10),
            child: ListView(
                padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10),
                children: [
                  SizedBox(height: 10),
                  locationText,
                  SizedBox(height: 10),
                  startPointText,
                  SizedBox(height: 10),
                  destinationText,
                  SizedBox(height: 20),
                  timeText,
                  SizedBox(height: 10),
                  fromText,
                ])),
      ),
    );
  }
}


*/
/*
          CustomDropdownButton<String>(
            elevation: 0,
            value: _fromTime,
            onChanged: (String newValue) {
              setState(() {
                _fromTime = newValue;
              });
            },
              items:time.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          ),*/
//  dropDownButtonsColumn(time,"Choose time"),
/*
          SizedBox(
            height: 30,
            width: 200,
            child: Container(
                height: 20,
                child:ButtonTheme(
                    alignedDropdown: true,
                    child: DropdownButton<String>(
                      elevation: 0,
                      value: _fromTime,
                      onChanged: (String newValue) {
                        setState(() {
                          _fromTime = newValue;
                        });
                      },
                      items: time.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ))),
          ),*/