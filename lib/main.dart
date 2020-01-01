import 'package:android_intent/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

void main() {
  runApp(new MapsAed());
}

class MapsAed extends StatefulWidget {
  MapsAed() : super();

  final String title = "Lokasi Saat Ini";

  @override
  MapsAedState createState() => MapsAedState();
}

class MapsAedState extends State<MapsAed> {
  Completer<GoogleMapController> _controler = Completer();
  static const LatLng _center = const LatLng(-6.3634789, 106.81995);
  Set<Marker> _markers = {};
  LatLng _lastMapPosition = _center;
  MapType _currentMapType = MapType.normal;

  final _collectionReference = Firestore.instance.collection("Posisi");
  final _controllerText = TextEditingController();

  static final CameraPosition _position1 = CameraPosition(
    bearing: 192.999,
    target: LatLng(-6.3634789, 106.81995),
    tilt: 59,
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _loadFirstMarker().then((value) {
      _markers.addAll(value);
    });
  }

  Future<void> _goToPosition1() async {
    final GoogleMapController controller = await _controler.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_position1));
  }

  _onMapCreated(GoogleMapController controller) {
    _controler.complete(controller);
  }

  _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  _onAddMarkerButtonPressed(String id, String title) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: _lastMapPosition,
          infoWindow: InfoWindow(
            onTap: () {
              _loadNavigation(_lastMapPosition);
            },
            title: title,
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  Widget button(Function function, IconData icon) {
    return FloatingActionButton(
        onPressed: function,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: Colors.blue,
        child: Icon(
          icon,
          size: 36.0,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.blue,
        ),
        body: StreamBuilder(
            stream: _collectionReference.snapshots(),
            builder: (context, snapshot) {
              return Stack(
                children: <Widget>[
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 11.0,
                    ),
                    mapType: _currentMapType,
                    markers: _markers,
                    onCameraMove: _onCameraMove,
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Column(
                        children: <Widget>[
                          button(_onMapTypeButtonPressed, Icons.map),
                          SizedBox(
                            height: 16.0,
                          ),
                          button(() async {
                            // generate new id for firebase document
                            String newid =
                                _collectionReference.document().documentID;
                            // open dialog for location name
                            await _setNewMarker(context, newid);
                            // add new marker location on map
                            _onAddMarkerButtonPressed(
                                newid, _controllerText.text);
                          }, Icons.add_location),
                          SizedBox(
                            height: 16.0,
                          ),
                          button(_goToPosition1, Icons.location_searching),
                        ],
                      ),
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }

  Future _setNewMarker(BuildContext context, String newid) {
    _controllerText.clear();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Masukan Lokasi"),
            content: TextField(
              controller: _controllerText,
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Simpan"),
                onPressed: () {
                  // save new map location to firebase
                  _collectionReference.document(newid).setData({
                    'id': newid,
                    'name': _controllerText.text,
                    'location': GeoPoint(
                        _lastMapPosition.latitude, _lastMapPosition.longitude),
                  });
                  // close the dialog
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  // Method to load marker when first load
  Future<Iterable<Marker>> _loadFirstMarker() async {
    return await _collectionReference.getDocuments().then((stream) {
      return stream.documents.map((snapshot) {
        GeoPoint loc = snapshot['Lokasi'];
        return Marker(
          markerId: MarkerId(snapshot['id']),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(
            onTap: () {
              _loadNavigation(LatLng(loc.latitude, loc.longitude));
            },
            title: snapshot['Nama'],
          ),
          icon: BitmapDescriptor.defaultMarker,
        );
      }).toList();
    });
  }

  // Method to open google map navigation
  _loadNavigation(LatLng latLng) {
    final AndroidIntent intent = new AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull("https://www.google.com/maps/dir/?api=1&origin=" +
            _generateStringlatLang(_center) +
            "&destination=" +
            _generateStringlatLang(latLng) +
            "&travelmode=driving&dir_action=navigate"),
        package: 'com.google.android.apps.maps');
    intent.launch();
  }

  String _generateStringlatLang(LatLng latLng) {
    return latLng.latitude.toString() + "," + latLng.longitude.toString();
  }
}
