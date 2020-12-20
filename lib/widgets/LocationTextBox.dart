import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoding/geocoding.dart';
import '../Utils.dart';

class LocationTextBoxes2 extends StatefulWidget {
  final GlobalKey<ScaffoldState> _key;
  final Size size;
  final Function performOnPress;
  final Function updateAddress;
  final double locationNumber;
  final String leadingText;
  final Color leadingTextColor;

  LocationTextBoxes2(this.updateAddress,this.size, this.performOnPress, this._key,
      this.locationNumber, this.leadingText, this.leadingTextColor);

  @override
  _LocationTextBoxes2State createState() => _LocationTextBoxes2State();
}

class _LocationTextBoxes2State extends State<LocationTextBoxes2> {
  TextEditingController city;
  TextEditingController street;
  var address;
  bool _pressed;

  @override
  void initState() {
    super.initState();
    city = TextEditingController(text: "");
    street = TextEditingController(text: "");
    _pressed = false;
  }

  Future<bool> validateLegalCity(String city) async {
    try {
      var cc = await locationFromAddress(city,localeIdentifier: "en");
      var cityAddress = await placemarkFromCoordinates(cc[0].latitude, cc[0].longitude,localeIdentifier: "en");
      if (cityAddress.first.country.toLowerCase() == "israel") {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return true;
    }
  }

  Future<bool> validateLegalStreet(String city, String street) async {
    try {
      var cc = await locationFromAddress(city,localeIdentifier: "en");
      var cityAddress = await placemarkFromCoordinates(cc[0].latitude, cc[0].longitude,localeIdentifier: "en");
      var cc2 = await locationFromAddress(city+ ", " + street);
      var ccA = await placemarkFromCoordinates(cc2[0].latitude, cc2[0].longitude,localeIdentifier: "en");
      address = [Address(coordinates: Coordinates(cc2[0].latitude,cc2[0].longitude),addressLine: (ccA[0].locality+", "+ccA[0].street),
          countryName: ccA[0].country,countryCode: ccA[0].isoCountryCode, featureName: ccA[0].name,postalCode: ccA[0].postalCode, adminArea: ccA[0].administrativeArea,
          subAdminArea: ccA[0].subAdministrativeArea, locality: ccA[0].locality, subLocality: ccA[0].subLocality, thoroughfare: ccA[0].thoroughfare, subThoroughfare: ccA[0].subThoroughfare )];
      if (address.first.countryName.toLowerCase() == "israel") {
        if ((cc2.first.latitude !=
            cc.first.latitude ||
            cc2.first.longitude !=
                cc.first.longitude) &&
            ((address.first.locality == cityAddress.first.locality) ||
                (address.first.locality == cityAddress.first.subLocality))) {
          return false;
        } else {
          return true;
        }
      } else {
        return true;
      }
    } catch (e) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
            color: Colors.white),
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
        height: 40,
        width: widget.size.width,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(width: 46,
                child: Text(
                      widget.leadingText + ":",
                      style:
                      TextStyle(fontSize: 16, color: widget.leadingTextColor),
                    ),
              ),
              Flexible(
                fit: FlexFit.loose,
                  flex: 3,
                  child: TextFormField(
                      controller: city,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: "City"))),
              VerticalDivider(width: 6),
              Flexible(
                  fit: FlexFit.loose,
                  flex: 5,
                  child: TextFormField(
                      controller: street,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Street\\place"))),
                  TextButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _pressed = true;
                        });
                        try {
                          var _streetError = await validateLegalCity(city.text);
                          var _cityError =
                          await validateLegalStreet(city.text, street.text);
                          if (!_streetError && !_cityError) {
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
                      child: Container(
                          width: 80,
                          child: !_pressed ? Row(mainAxisAlignment: MainAxisAlignment.center,children: [Flexible(child: Icon(Icons.add_location_alt,color: secondColor,)),Flexible(
                            child: Text(
                              "Select",
                              style: TextStyle(fontSize: 14, color: secondColor),
                            ),
                          ),]) : Center(child: CircularProgressIndicator())))
            ]));
  }

  @override
  void dispose() {
    city.dispose();
    street.dispose();
    super.dispose();
  }
}
