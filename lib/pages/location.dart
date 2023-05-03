// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

// import 'package:mapbox_gl/mapbox_gl.dart';

void main() => runApp(MaterialApp(home: MapWidget()));

class MapMarker {
  final String title;
  final String address;
  final LatLng location;

  MapMarker({
    this.title,
    this.address,
    this.location,
  });
}

class AppConstants {
  static const String mapBoxAccessToken =
      'pk.eyJ1IjoiZ2RoYW51a2ExOTIiLCJhIjoiY2xneGdsbzBrMDFxdTNmbDltMXl5bjQ2NyJ9.S48098IxH7Cc1iJe1hRLUg';

  static const String mapBoxStyleId = 'mapbox://styles/gdhanuka192/clgy1ufi000ei01qu2ddvc1yo';

  static final myLocation = LatLng(26.1113, 91.4133);
}



class MapWidget extends StatefulWidget {

  const MapWidget({Key key, this.client, this.latitude, this.longitude}) : super(key: key);

  final mqtt.MqttClient client;
  final double longitude, latitude;

  @override
  State<MapWidget> createState() => MapWidgetState(this.client, this.latitude, this.longitude);
}

class MapWidgetState extends State<MapWidget> {

  mqtt.MqttClient client;
  double longitude, latitude;
  mqtt.MqttConnectionState connectionState;
  String message = '';
  LatLng myLocation;
  // final myLocation = LatLng(26.1113, 91.4133);

  MapWidgetState(this.client, this.latitude, this.longitude);

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: const Color.fromARGB(255, 33, 32, 32),
  //       title: const Text('Flutter MapBox'),
  //     ),
  //     body: Stack(
  //       children: [
  //         // FlutterMap(
  //         //   options: MapOptions(
  //         //     minZoom: 5,
  //         //     maxZoom: 18,
  //         //     zoom: 13,
  //         //     center: AppConstants.myLocation,
  //         //   ),
  //         //   layers: [
  //         //     TileLayerOptions(
  //         //       urlTemplate:
  //         //           "https://api.mapbox.com/styles/v1/gdhanuka192/clgy1ufi000ei01qu2ddvc1yo/wmts?access_token=${AppConstants.mapBoxAccessToken}",
  //         //       additionalOptions: {
  //         //         'mapStyleId': AppConstants.mapBoxStyleId,
  //         //         'accessToken': AppConstants.mapBoxAccessToken,
  //         //       },
  //         //     ),
  //         //   ],
  //         // ),
  //         MapboxMap(
  //           initialCameraPosition:
  //               CameraPosition(target: AppConstants.myLocation),
  //           accessToken: AppConstants.mapBoxAccessToken,
  //           styleString:
  //               "mapbox://styles/gdhanuka192/clgy1ufi000ei01qu2ddvc1yo",
  //           onMapCreated: (MapboxMapController controller) {},
  //         )
  //       ],
  //     ),
  //   );
  // }
  var currentLocation = AppConstants.myLocation;
  MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

    @override
  Widget build(BuildContext context) {
    print("Refreshed again!");
    myLocation = LatLng(latitude, longitude);
    final mapMarkers = [
      MapMarker(
        title: 'My Location',
        address: 'IIT Guwahati',
        location: LatLng(latitude, longitude),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Flutter MapBox'),
      ),
      body: 
      Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              minZoom: 5,
              maxZoom: 18,
              zoom: 10,
              center: LatLng(latitude, longitude),
            ),
            layers: [
              TileLayerOptions(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/gdhanuka192/clgy1ufi000ei01qu2ddvc1yo/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZ2RoYW51a2ExOTIiLCJhIjoiY2xneGdsbzBrMDFxdTNmbDltMXl5bjQ2NyJ9.S48098IxH7Cc1iJe1hRLUg",
                additionalOptions: {
                  'mapStyleId': AppConstants.mapBoxStyleId,
                  'accessToken': AppConstants.mapBoxAccessToken,
                },
              ),
              MarkerLayerOptions(
                markers: [
                  for (final marker in mapMarkers)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: marker.location ?? myLocation,
                      // builder: (ctx) => Container(
                      //   child: Column(
                      //     children: [
                      //       Text(marker.title),
                      //       Text(marker.address),
                      //     ],
                      //   ),
                      // ),
                      builder: (_) {
                        return GestureDetector(
                          onTap: () {
                            print('Marker tapped');
                          },
                          child: Container(
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40.0,
                            ),
                          ),
                        );
                      }
                    ),
                ]
              ),

            ],
          ),
        ],
      ),
    );
  }

}
