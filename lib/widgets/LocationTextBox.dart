import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
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

  @override
  void initState() {
    super.initState();
    city = TextEditingController(text: "");
    street = TextEditingController(text: "");
  }

  Future<bool> validateLegalCity(String city) async {
    try {
      var cityAddress = await Geocoder.local.findAddressesFromQuery(city);
      if (cityAddress.first.countryName.toLowerCase() == "israel") {
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
      var cityAddress = await Geocoder.local.findAddressesFromQuery(city);
      address =
          await Geocoder.local.findAddressesFromQuery(city + ", " + street);
      if (address.first.countryName.toLowerCase() == "israel") {
        if ((address.first.coordinates.latitude !=
                    cityAddress.first.coordinates.latitude ||
                address.first.coordinates.longitude !=
                    cityAddress.first.coordinates.longitude) &&
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
            color: Colors.white, borderRadius: containerBorderRadius),
        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        width: widget.size.width,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                  fit: FlexFit.tight,
                  flex: 2,
                  child: Text(
                    widget.leadingText + ":",
                    style:
                        TextStyle(fontSize: 16, color: widget.leadingTextColor),
                  )),
              Flexible(
                  fit: FlexFit.tight,
                  flex: 2,
                  child: TextFormField(
                      controller: city,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: "City"))),
              VerticalDivider(width: 6),
              Flexible(
                  fit: FlexFit.tight,
                  flex: 5,
                  child: TextFormField(
                      controller: street,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Street\\place"))),
              Flexible(
                  fit: FlexFit.tight,
                  flex: 3,
                  child: TextButton(
                      onPressed: () async {
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
                      },
                      child: Container(
                          width: 50,
                          child: Text(
                            "Search",
                            style: TextStyle(fontSize: 16, color: secondColor),
                          ))))
            ]));
  }

  @override
  void dispose() {
    city.dispose();
    street.dispose();
    super.dispose();
  }
}
