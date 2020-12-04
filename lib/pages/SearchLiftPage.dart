import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:tech_pool/Utils.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:dropdown_customizable/dropdown_customizable.dart';
import 'package:f_datetimerangepicker/f_datetimerangepicker.dart';
import 'package:intl/intl.dart';
import 'package:tech_pool/widgets/TextBoxField.dart';
import 'package:tech_pool/pages/LiftSearchReasultsPage.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';


class SearchLiftPage extends StatefulWidget {
  DateTime cuurentdate;
  DateTime fromtime;
  DateTime totime;
  int indexDis;
  SearchLiftPage({Key key,@required this.cuurentdate,this.fromtime,this.totime,this.indexDis}): super(key: key);
  @override
  _SearchLiftPageState createState() => _SearchLiftPageState();
}

class _SearchLiftPageState extends State<SearchLiftPage> {
  final _formKey = GlobalKey<FormState>();
  double _fontTextsSize = 17;
  double _lablesTextsSize = 19;
  String _fromTimec = "00:00";
  String resultString;
  DateTime _fromTime = null;
  String _fromMinutes="";
  DateTime _toTime = null;
  bool checkedBigTrunck = false;
  bool backSeatNotfull = false;
  List<String> _distances = ["1km","5km","20km","40km"];
  String _maxDist ="20km";
  TextEditingController _fromControler;
  TextEditingController _toControler;
  double _spaces = 0;


  @override
  void initState() {
    super.initState();
    _fromControler = TextEditingController(text: "");
    _toControler = TextEditingController(text: "");
  }

  @override
  Widget build(BuildContext context) {
    var sizeFrameWidth = MediaQuery.of(context).size.width;
    double defaultSpace = MediaQuery.of(context).size.height*0.013;
    double defaultSpacewidth = MediaQuery.of(context).size.height*0.016;
    if(widget.fromtime!=null) {
      _fromTime = widget.fromtime;
      _fromControler.text = DateFormat('dd-MM – kk:mm').format(widget.fromtime);
       widget.fromtime=null;
    }
    if( widget.totime!=null) {
      _toTime = widget.totime;
      _toControler.text = DateFormat('dd-MM – kk:mm').format(widget.totime);
      widget.totime=null;
    }
    if(widget.indexDis!=null){
      _maxDist =_distances[widget.indexDis];
       widget.indexDis = null;
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
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                    builder: (context) => LiftSearchReasultsPage(fromTime: _fromTime,toTime: _toTime, indexDist: _distances.indexOf(_maxDist)),
                    ));
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

    final chooseTime =
    Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          child: RaisedButton.icon(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.black)),
            label: Text("Choose time"),
            icon: Icon(Icons.timer),
            onPressed: () {
              DateTimeRangePicker(
                  startText: "From",
                  endText: "To",
                  doneText: "Yes",
                  cancelText: "Cancel",
                  interval: 5,
                  initialStartTime: (_fromTime!=null)?_fromTime:DateTime.now().add(Duration(days: 0,hours: 0,minutes: 0,microseconds: 0)),
                  initialEndTime: (_fromTime!=null)?_toTime:DateTime.now().add(Duration(days: 0,hours: 0,minutes: 0,microseconds: 0)),
                  mode: DateTimeRangePickerMode.time,
                  minimumTime: DateTime.now().subtract(Duration(days: 1,hours: 1,minutes: 0,microseconds: 0)),
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
                  }).showPicker(context);
            },
          ),
        ),
        Text(resultString ?? "")
      ]);

    final fromText = Container(
      child: Row(
        children: [
          textBoxFieldDisable(
              nameLable: "From: ",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _fromControler,
              validator: (value) {
                if(_fromTime==null ){return '';}
                else  if ((_fromTime.hour >_toTime.hour) || (_toTime.hour == _fromTime.hour && _toTime.minute < _fromTime.minute )) {return '';}
                else if(_fromTime.hour ==_toTime.hour && _toTime.minute == _fromTime.minute ){return '';}
                else return null;}),
        ],
      ),
    );

    final toText = Container(
          child:textBoxFieldDisable(
              nameLable: "To: ",
              size: MediaQuery.of(context).size,
              hintText: "",
              textFieldController: _toControler,
              validator: (value) {
                if(_fromTime==null ){return 'Time not chosen';}
              else  if ((_fromTime.hour >_toTime.hour) || (_toTime.hour == _fromTime.hour && _toTime.minute < _fromTime.minute )) {return 'The from time is older than the to';}
              else if(_fromTime.hour ==_toTime.hour && _toTime.minute == _fromTime.minute ){return 'The from time is equal to the to';}
              else return null;}),
            //  : SizedBox(width: sizeFrameWidth*0.1),
          //SizedBox(width:  sizeFrameWidth*0.1),
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
              canvasColor: mainColor, // background color for the dropdown items
              buttonTheme: ButtonTheme.of(context).copyWith(
                alignedDropdown: true,  //If false (the default), then the dropdown's menu will be wider than its button.
              )
          ),
          child:DropdownButton<String>(
            dropdownColor: mainColor,
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

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Search Lift"),
      ),
      body:  Form(
        key: _formKey,
        child: Builder(
          builder: (context) => Container(
              color: Colors.white,
              margin: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth, bottom: 10),
              child: Stack(children:[Container( child:Center(child:Transform.rotate(angle: 0.8,child:Icon(Icons.thumb_up_rounded,size:300,color:  Colors.cyan.withOpacity(0.1),)))),
                ListView(
                  padding: EdgeInsets.only(left: defaultSpacewidth, right: defaultSpacewidth, bottom: 10),
                  children: [
                    //SizedBox(height: defaultSpace),
                   // locationText,
                    SizedBox(height: defaultSpace),
                    startPointText,
                    SizedBox(height: defaultSpace),
                    destinationText,
                    //SizedBox(height: 2*defaultSpace),
                    //timeText,
                    SizedBox(height: 2*defaultSpace),
                    fromText,
                    //SizedBox(height: defaultSpace),
                    toText,
                    SizedBox(height: defaultSpace),
                    chooseTime,
                    //SizedBox(height: defaultSpace),
                    //preferenceTexts,
                    SizedBox(height: defaultSpace),
                    bigTruncText,
                    backSeatText,
                    maxDistance,
                    SizedBox(height:4*defaultSpace),
                    searchLift,
                  ])])),
        ),
      ),
      backgroundColor: mainColor,
    );
  }

  @override
  void dispose() {
    _fromControler.dispose();
    _toControler.dispose();
    super.dispose();
  }
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