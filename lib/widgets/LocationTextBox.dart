import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import '../Utils.dart';

class LocationTextBoxes2 extends StatefulWidget {
  final GlobalKey<ScaffoldState> _key;
  final Size size;
  final Function performOnPress;
  final Function updateAddress;
  final double locationNumber;
  final String leadingText;
  final Color leadingTextColor;
  final String myEmail;

  LocationTextBoxes2(this.updateAddress,this.size, this.performOnPress, this._key,
      this.locationNumber, this.leadingText, this.leadingTextColor,this.myEmail);

  @override
  _LocationTextBoxes2State createState() => _LocationTextBoxes2State();
}

class _LocationTextBoxes2State extends State<LocationTextBoxes2> {
  TextEditingController city;
  TextEditingController street;
  var address;
  bool _pressed;
  List<PopupMenuItem> myFavorites = [];

  @override
  void initState() {
    super.initState();
    city = TextEditingController(text: "");
    street = TextEditingController(text: "");
    _pressed = false;
  }

  /// validates the city input is legal.
  Future<bool> validateLegalAddress(String address) async {
    try {
      var cc = await locationFromAddress(address,localeIdentifier: "en");
      var cityAddress = await placemarkFromCoordinates(cc[0].latitude, cc[0].longitude,localeIdentifier: "en");
      if (cityAddress.first.country.toLowerCase() == "israel") {
        this.address = [
          Address(coordinates: Coordinates(cc[0].latitude, cc[0].longitude),
              addressLine: (cityAddress[0].locality + ", " + cityAddress[0].street),
              countryName: cityAddress[0].country,
              countryCode: cityAddress[0].isoCountryCode,
              featureName: cityAddress[0].name,
              postalCode: cityAddress[0].postalCode,
              adminArea: cityAddress[0].administrativeArea,
              subAdminArea: cityAddress[0].subAdministrativeArea,
              locality: cityAddress[0].locality,
              subLocality: cityAddress[0].subLocality,
              thoroughfare: cityAddress[0].thoroughfare,
              subThoroughfare: cityAddress[0].subThoroughfare)
        ];
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return true;
    }
  }

/*  /// validates the "city, street" input is legal.
  Future<bool> validateLegalStreet(String city, String street) async {
    try {
        if (city.toLowerCase().contains("haifa") || city.contains("חיפה")) {
          var cc2 = await locationFromAddress(city + ", " + street);
          var ccA = await placemarkFromCoordinates(
              cc2[0].latitude, cc2[0].longitude, localeIdentifier: "en");
          address = [
            Address(coordinates: Coordinates(cc2[0].latitude, cc2[0].longitude),
                addressLine: (ccA[0].locality + ", " + ccA[0].street),
                countryName: ccA[0].country,
                countryCode: ccA[0].isoCountryCode,
                featureName: ccA[0].name,
                postalCode: ccA[0].postalCode,
                adminArea: ccA[0].administrativeArea,
                subAdminArea: ccA[0].subAdministrativeArea,
                locality: ccA[0].locality,
                subLocality: ccA[0].subLocality,
                thoroughfare: ccA[0].thoroughfare,
                subThoroughfare: ccA[0].subThoroughfare)
          ];
          return false;
      } else {
        var cc = await locationFromAddress(city, localeIdentifier: "en");
        var cityAddress = await placemarkFromCoordinates(cc[0].latitude, cc[0].longitude, localeIdentifier: "en");
        var cc2 = await locationFromAddress(city + ", " + street);
        var ccA = await placemarkFromCoordinates(cc2[0].latitude, cc2[0].longitude, localeIdentifier: "en");
        address = [
          Address(coordinates: Coordinates(cc2[0].latitude, cc2[0].longitude),
              addressLine: (ccA[0].locality + ", " + ccA[0].street),
              countryName: ccA[0].country,
              countryCode: ccA[0].isoCountryCode,
              featureName: ccA[0].name,
              postalCode: ccA[0].postalCode,
              adminArea: ccA[0].administrativeArea,
              subAdminArea: ccA[0].subAdministrativeArea,
              locality: ccA[0].locality,
              subLocality: ccA[0].subLocality,
              thoroughfare: ccA[0].thoroughfare,
              subThoroughfare: ccA[0].subThoroughfare)
        ];
        if (address.first.countryName.toLowerCase() == "israel") {
          if ((cc2.first.latitude !=
              cc.first.latitude ||
              cc2.first.longitude !=
                  cc.first.longitude)) {
            return false;
          } else {
            return true;
          }
        } else {
          return true;
        }
      }
      } catch (e) {
      return true;
    }
  }*/

  String val="";
  bool selected = true;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
            color: Colors.white),
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
        width: widget.size.width,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(width: 50,
                child: Text(
                      widget.leadingText + ":",
                      style:
                      TextStyle(fontSize: 16, color: widget.leadingTextColor),
                    ),
              ),
        ///first attempt.
        /*      Flexible(child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      items: [DropdownMenuItem(value: "asd",child: Container(height: 100,
        width: 100,
        child: TextField(
            controller: city,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
                border: InputBorder.none, hintText: "City")),
      )),DropdownMenuItem(value: "bbb",child: Text("bbb"))],
    value: "asd",
    isDense: true,
    onChanged: (s) => print("s"))))*/
              ///second attempt.
     /*         Flexible(
                child: DropdownButton(onTap: () {setState(() {
                  selected = false;
                  print("clicked");
                });},isDense: true,isExpanded: true,value: val, items: [(selected? DropdownMenuItem(value: "",child: TextFormField(
                    controller: city,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                        border: InputBorder.none, hintText: "Enter address/place"))) : DropdownMenuItem(value: "",child: Text("Enter Address"))),DropdownMenuItem(value: "Netanya admonit 12",child: Text("Home")),DropdownMenuItem(value: "Haifa technion",child: Text("Work"))], onChanged: (newVal) {city.text = newVal; setState(() {
                  print("selected");
                  val = newVal;
                  if(newVal == null || newVal == "") {
                    selected = true;
                  }
                        });}),
              ),*/
    FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection("Favorites").doc(widget.myEmail).get(),
    builder: (context, snapshot) {
      if(snapshot.hasData){
        if(snapshot.data.data() != null) {
          myFavorites = [];
          if(snapshot.data.data().containsKey("Home")){
            myFavorites.add(PopupMenuItem(value: snapshot.data.data()["Home"]["Address"],child: Row(children: [Icon(Icons.home),Text("Home")])));
          }
          if(snapshot.data.data().containsKey("Work")){
            myFavorites.add(PopupMenuItem(value: snapshot.data.data()["Work"]["Address"],child: Row(children: [Icon(Icons.work),Text("Work")])));
          }
          snapshot.data.data().forEach((key, value) {
            if(key != "Home" && key != "Work") {
              myFavorites.add(PopupMenuItem(value: value["Address"], child: Row(
                  children: [Icon(Icons.favorite), Text(key)])));
            }
          });
        }else{
          myFavorites = [];
        }
      }else if (snapshot.hasError){
        myFavorites = [];
    }else{
        myFavorites = [PopupMenuItem(child: CircularProgressIndicator())];
      }
      return PopupMenuButton(
          offset: Offset(0, 40), icon: Icon(Icons.arrow_drop_down_sharp),
          itemBuilder: (BuildContext context) =>
          [
            PopupMenuItem(value: "my location", child: Row(children: [Icon(
                Icons.my_location), Text("My location")],)),
            ...myFavorites
          ],
          onSelected: (value) async {
            setState(() {
              FocusScope.of(context).unfocus();
              _pressed = true;
            });
            if (value != "my location") {
              city.text = value;
              try {
                if (!await validateLegalAddress(city.text)) {
                  widget.updateAddress(address.first);
                  await widget.performOnPress(
                      address: address.first,
                      locationNumber: widget.locationNumber,
                      stopText: "\"" + widget.leadingText + "\"");
                } else {
                  widget._key.currentState.showSnackBar(SnackBar(
                    content: Text("Address not found"),
                  ));
                }
              } catch (e) {
                widget._key.currentState.showSnackBar(SnackBar(
                  content: Text("Address not found"),
                ));
              }
              setState(() {
                _pressed = false;
              });
            } else {
              loc.Location location = loc.Location();
              bool _serviceEnabled;
              loc.PermissionStatus _permissionGranted;
              _serviceEnabled = await location.serviceEnabled();
              if (!_serviceEnabled) {
                _serviceEnabled = await location.requestService();
                if (!_serviceEnabled) {
                  widget._key.currentState.showSnackBar(SnackBar(
                    content: Text("Please enable location services"),
                  ));
                  setState(() {
                    _pressed = false;
                    FocusScope.of(context).unfocus();
                  });
                  return;
                }
              }
              _permissionGranted = await location.hasPermission();
              if (_permissionGranted == loc.PermissionStatus.denied) {
                _permissionGranted = await location.requestPermission();
                if (_permissionGranted != loc.PermissionStatus.granted) {
                  widget._key.currentState.showSnackBar(SnackBar(
                    content: Text(
                        "Cannot use location service without permission"),
                  ));
                  setState(() {
                    _pressed = false;
                    FocusScope.of(context).unfocus();
                  });
                  return;
                }
              }
              location.changeSettings(accuracy: loc.LocationAccuracy.high);
              var currentLocation = await location.getLocation();
              var cityAddress = await placemarkFromCoordinates(
                  currentLocation.latitude, currentLocation.longitude,
                  localeIdentifier: "en");
              if (cityAddress.first.country.toLowerCase() == "israel") {
                this.address = [
                  Address(coordinates: Coordinates(
                      currentLocation.latitude, currentLocation.longitude),
                      addressLine: (cityAddress[0].locality + ", " +
                          cityAddress[0].street),
                      countryName: cityAddress[0].country,
                      countryCode: cityAddress[0].isoCountryCode,
                      featureName: cityAddress[0].name,
                      postalCode: cityAddress[0].postalCode,
                      adminArea: cityAddress[0].administrativeArea,
                      subAdminArea: cityAddress[0].subAdministrativeArea,
                      locality: cityAddress[0].locality,
                      subLocality: cityAddress[0].subLocality,
                      thoroughfare: cityAddress[0].thoroughfare,
                      subThoroughfare: cityAddress[0].subThoroughfare)
                ];
                city.text = address.first.addressLine;
                widget.updateAddress(address.first);
                await widget.performOnPress(
                    address: address.first,
                    locationNumber: widget.locationNumber,
                    stopText: "\"" + widget.leadingText + "\"");
              }
            }
            setState(() {
              _pressed = false;
              FocusScope.of(context).unfocus();
            });
          });
    }),
              Flexible(
                  fit: FlexFit.loose,
                  flex: 3,
                  child: TextFormField(
                      controller: city,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: "Address/Place"))),
              VerticalDivider(width: 6),
                  Container(
                    width: 100,
                    child: TextButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _pressed = true;
                          });
                          try {
                            if (!await validateLegalAddress(city.text)) {
                              widget.updateAddress(address.first);
                              await widget.performOnPress(
                                  address: address.first,
                                  locationNumber: widget.locationNumber,
                                  stopText: "\"" + widget.leadingText + "\"");
                            } else {
                              widget._key.currentState.showSnackBar(SnackBar(
                                content: Text("Address not found"),
                              ));
                            }
                          } catch (e) {
                            widget._key.currentState.showSnackBar(SnackBar(
                              content: Text("Address not found"),
                            ));
                          }
                          setState(() {
                            _pressed = false;
                          });
                        },
                        child: !_pressed ? Row(mainAxisAlignment: MainAxisAlignment.center,children: [Flexible(child: Icon(Icons.add_location_alt,color: secondColor,)),Flexible(
                          child: Text(
                            "Select",
                            style: TextStyle(fontSize: 14, color: secondColor),
                          ),
                        ),]) : Center(child: CircularProgressIndicator())),
                  )
            ]));
  }

  @override
  void dispose() {
    city.dispose();
    street.dispose();
    super.dispose();
  }
}
