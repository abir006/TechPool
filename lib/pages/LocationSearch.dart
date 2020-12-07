import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tech_pool/widgets/LocationTextBox.dart';
import 'package:tech_pool/Utils.dart';
import 'dart:async';

class LocationSearch extends StatefulWidget {
  final bool showAddStops;

  LocationSearch({@required this.showAddStops});
  @override
  _LocationSearchState createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  Address fromAddress;
  Address toAddress;
  var stopFunctions;
  var stopAddresses;

  @override
  void initState() {
    stopFunctions = [updateStop1Address,updateStop2Address,updateStop3Address];
    stopAddresses = [Address(),Address(),Address()];
    super.initState();
  }

  void updateFromAddress(Address address){
    fromAddress = address;
  }
  void updateToAddress(Address address){
    toAddress = address;
  }
  void updateStop1Address(Address address){
    stopAddresses[0] = address;
  }
  void updateStop2Address(Address address){
    stopAddresses[1] = address;
  }
  void updateStop3Address(Address address){
    stopAddresses[2] = address;
  }

  var stopTextBoxes = [];
  var stopNumber = 0;

  final stopColor = [30.0, 240.0, 300.0];
  final stopTextColor = [
    Colors.orange,
    Colors.blue[800],
    Colors.pinkAccent[100]
  ];
  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _kTechnion = CameraPosition(
      bearing: 0.0,
      target: LatLng(32.7767783, 35.02312710000001),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);
  final _key = GlobalKey<ScaffoldState>();

  Map<MarkerId, Marker> markers =
      <MarkerId, Marker>{}; // CLASS MEMBER, MAP OF MARKS

  void _addMarker(
      String address, LatLng latlng, double locationNumber, String stopText) {
    final MarkerId markerId = MarkerId(address);
    // creating a new MARKER
    final Marker marker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(locationNumber),
      markerId: markerId,
      position: latlng,
      infoWindow: InfoWindow(
          title: address,
          snippet: 'Searched as $stopText',
        ),
    );

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var textBoxes = LocationTextBoxes2(updateFromAddress,
        size, _goToAddress, _key, 120.0, "From", Colors.green);
    var textBoxes2 =
        LocationTextBoxes2(updateToAddress,size, _goToAddress, _key, 0.0, "To", Colors.red);
    return Scaffold(
      key: _key,
      appBar: AppBar(
          title: Text(
        "Address Search",
        style: TextStyle(color: Colors.white),
      )),
      body: Column(children: [
        textBoxes,
        ...stopTextBoxes,
        (stopNumber < 3 && widget.showAddStops)
            ? Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                width: 120,
                height: 26,
                child: RaisedButton(
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        stopTextBoxes.insert(
                            stopNumber,
                            Row(children: [
                              SizedBox(
                                  width: 28,
                                  child: IconButton(
                                      alignment: Alignment.centerLeft,
                                      iconSize: 20,
                                      icon: Icon(Icons.delete,
                                          color: Colors.black),
                                      onPressed: () {
                                        setState(() {
                                          stopAddresses[stopNumber-1] = null;
                                          stopTextBoxes
                                              .removeAt(stopNumber - 1);
                                          stopNumber = stopNumber - 1;
                                        });
                                      })),
                              Flexible(
                                  child: LocationTextBoxes2(stopFunctions[stopNumber],
                                      size,
                                      _goToAddress,
                                      _key,
                                      stopColor[stopNumber],
                                      "Stop${stopNumber+1}",
                                      stopTextColor[stopNumber]))
                            ]));
                        stopNumber = stopNumber + 1;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add_location_alt),
                        Text("Add stop")
                      ],
                    )))
            : Container(),
        textBoxes2,
        Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
            ),
            width: 160,
            height: 26,
            child: RaisedButton(color: Colors.black,onPressed: () {
              if(fromAddress != null && toAddress != null) {
                if (stopNumber == 0 ||
                    (stopNumber == 1 && stopAddresses[0] != null) ||
                    (stopNumber == 2 && stopAddresses[0] != null &&
                        stopAddresses[1] != null) ||
                    (stopNumber == 3 && stopAddresses[0] != null &&
                        stopAddresses[1] != null && stopAddresses[2] != null)) {
                  Navigator.pop<LocationsResult>(
                      context, LocationsResult(
                      fromAddress, toAddress, stopAddresses));
                } else {
                  _key.currentState.showSnackBar(SnackBar(content: Text(
                    "Please select addresses before submitting",
                    style: TextStyle(fontSize: 16),),));
                }
              }
              else {
                _key.currentState.showSnackBar(SnackBar(content: Text(
                  "Please select addresses before submitting",
                  style: TextStyle(fontSize: 16),),));
              }
            },child: Text("Submit locations",style: TextStyle(color: Colors.white),),)),
        
        Flexible(
            child: GoogleMap(
          mapType: MapType.normal,
          compassEnabled: false,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          markers: Set<Marker>.of(markers.values),
          mapToolbarEnabled: false,
          initialCameraPosition: _kTechnion,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        )),
      ],
      ),
    );
  }

  Future<void> _goToAddress(
      {@required Address address,
      double locationNumber,
      String stopText}) async {
    final GoogleMapController controller = await _controller.future;
    var position = CameraPosition(
        target:
            LatLng(address.coordinates.latitude, address.coordinates.longitude),
        tilt: 59.440717697143555,
        zoom: 17.6);
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
    _addMarker(
        address.addressLine,
        LatLng(address.coordinates.latitude, address.coordinates.longitude),
        locationNumber,
        stopText);
  }

  @override
  void dispose() {
    super.dispose();
  }

}
