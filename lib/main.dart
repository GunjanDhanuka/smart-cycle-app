// @dart=2.9

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:smart_cycle_app/pages/location.dart';
import 'package:smart_cycle_app/pages/lock.dart';
import 'package:smart_cycle_app/pages/splash.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const MyApp(),
        '/lock': (context) => const Lock(),
        '/location': (context) => const MapWidget(),
      },
      debugShowCheckedModeBanner: false,
    ),
  ); //
  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Cycle App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: AnimatedSplashScreen(
        backgroundColor: Colors.orangeAccent,
        duration: 1500,
        splashTransition: SplashTransition.fadeTransition,
        splash: Center(
          child: Column(
            children: [
              // cycle icon
              Icon(
                Icons.motorcycle_rounded,
                color: Colors.white,
                size: 30,
              ),
              Container(
                  child: Text(
                "Smart Cycle App",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ],
          ),
        ),
        nextScreen: MyHomePage(title: 'Smart Cycle App'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _selectedIndex = 0;
  String broker = '91.121.93.94';
  int port = 1883;
  String username = 'seu_username';
  String password = 'seu_password';
  String clientIdentifier = 'android';
  String message = "Hello from flutter";
  // LatLng myLocation = LatLng(26.1113, 91.4133);
  double latitude = 26.1906;
  double longitude = 91.6946;
  Position _currentPosition;
  bool _isAlive = false;
  Timer timer;
  DateTime lastTime;

  List<String> topics = [
    'gunjan/movement',
    'gunjan/lock',
    'gunjan/longitude',
    'gunjan/latitude',
    'gunjan/lux',
    'gunjan/alive'
  ];

  String msg = "";

  mqtt.MqttClient client;
  mqtt.MqttConnectionState connectionState;

  StreamSubscription subscription;

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      client.subscribe(topic, mqtt.MqttQos.atLeastOnce);
    }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 3), (Timer t) => getCycleStatus());
    lastTime = DateTime.now();
  }

  void _connect() async {
    client = mqtt.MqttClient(broker, '');
    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;

    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean() // Non persistent session for testing
        .withWillQos(mqtt.MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      print(e);
      _disconnect();
    }

    if (client.connectionStatus.state == mqtt.MqttConnectionState.connected) {
      setState(() {
        connectionState = client.connectionStatus.state;
      });
    } else {
      _disconnect();
    }
    print("MQTT Client connected");

    subscription = client.updates.listen(_onMessage);

    for (String topic in topics) {
      _subscribeToTopic(topic);
    }

    // show alert dialog that connection is established
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Connection Established"),
          content: Text("MQTT Client connected"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
    // Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child:
              // wrap the text field in a container to set the width
              Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                // add rounded corners and a border to the container with a solid fill with a padding
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.all(10),
                child: Text("Value received from MQTT is: " + msg),
              ),
              // add an icon to show if the cycle is connected to MQTT or not based on the data from "gunjan/alive" channel
              // if the value is 1 then the cycle is connected to MQTT else it is not connected
              // check the value of _isAlive every 5 seconds and update the icon accordingly

              Container(
                child: getCycleStatus()
                    ? Icon(
                        Icons.motorcycle_rounded,
                        color: Colors.green,
                        size: 30,
                      )
                    : Icon(
                        Icons.motorcycle_rounded,
                        color: Colors.red,
                        size: 30,
                      ),
              ),
              Container(
                width: 200,
                child: TextFormField(
                  // set the hint text
                  initialValue: broker,
                  decoration: InputDecoration(hintText: 'Enter the broker'),
                  onChanged: (value) {
                    setState(() {
                      broker = value;
                    });
                  },
                ),
              ),
              Container(
                width: 200,
                child: TextFormField(
                  // set the hint text
                  decoration: InputDecoration(hintText: 'Enter the port'),
                  initialValue: port.toString(),
                  onChanged: (value) {
                    setState(() {
                      port = int.parse(value);
                    });
                  },
                ),
              ),
              // a field to connect to a new topic. process only when user presses enter
              Container(
                width: 200,
                child: TextFormField(
                  // set the hint text
                  decoration: InputDecoration(
                      hintText: 'Enter new topic to subscribe to'),
                  onFieldSubmitted: (value) {
                    setState(() {
                      topics.add(value);
                      _subscribeToTopic(value);
                    });
                  },
                ),
              ),
              // add a heading for the list
              Text(
                "Subscribed Topics",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // show list of topics currently subscribed to and a button to unsubscribe
              Container(
                width: 200,
                child: Column(
                  children: [
                    for (String topic in topics)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(topic),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                topics.remove(topic);
                              });
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FloatingActionButton(
                      onPressed: _connect,
                      tooltip: 'Connect to MQTT',
                      child: Icon(Icons.wifi),
                    ),
                    FloatingActionButton(
                      onPressed: _disconnect,
                      tooltip: 'Disconnect from MQTT',
                      child: Icon(Icons.wifi_off),
                    ),
                    // add a button with lock icon which will navigate to the lock page
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Lock(
                                    client: client,
                                  )),
                        );
                      },
                      tooltip: 'Lock',
                      child: Icon(Icons.lock),
                    ),
                    // add a button with a marker icon that will fetch the current location of the user
                    FloatingActionButton(
                      onPressed: () {
                        // show a spinner while the location is being fetched
                        _getCurrentPosition();
                        setState(() {
                          latitude = _currentPosition?.latitude;
                          longitude = _currentPosition?.longitude;
                        });
                      },
                      tooltip: 'Get Location',
                      child: Icon(Icons.location_on),
                    ),
                    // add a button with map icon which will navigate to the map page
                    FloatingActionButton(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/location');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MapWidget(
                                    client: client,
                                    latitude: latitude,
                                    longitude: longitude,
                                  )),
                        );
                      },
                      tooltip: 'Map',
                      child: Icon(Icons.map),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _disconnect() {
    print('[MQTT client] _disconnect()');
    client.disconnect();
    _onDisconnected();
  }

  bool getCycleStatus() {
    print("getCycleStatus called");
    DateTime now = DateTime.now();
    print("currentTime: $now");
    print("lastTime: $lastTime");
    // if difference between now and last time is greater than 1 minute, then set cycleStatus to false
    if (now.difference(lastTime).inSeconds > 3) {
      setState(() {
        _isAlive = false;
        // show an alert snackbar
      });
      final snackBar = SnackBar(
        content: Text('Device is not connected'),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      );

      return false;
    }
    setState(() {
      _isAlive = true;
    });
    return true;
  }

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');
    setState(() {
      connectionState = client.connectionState;
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('[MQTT client] MQTT client disconnected');
  }

  void _onMessage(List<mqtt.MqttReceivedMessage> event) {
    print(event.length);
    final mqtt.MqttPublishMessage recMess =
        event[0].payload as mqtt.MqttPublishMessage;
    final String message =
        mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print('[MQTT client] MQTT message: topic is <${event[0].topic}>, '
        'payload is <-- ${message} -->');
    print(client.connectionState);
    print("[MQTT client] message with topic: ${event[0].topic}");
    print("[MQTT client] message with message: ${message}");

    String topic = event[0].topic;
    if (topic == "gunjan/movement") {
      // show an alert dialog to the user
      print("ALERTTTT!");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Movement Detected"),
            content: Text(
                "Movement has been detected in the cycle. Click OK to see the location of the cycle."),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MapWidget(
                                client: client,
                                latitude: latitude,
                                longitude: longitude,
                              )));
                },
              )
            ],
          );
        },
      );
    }

    if (topic == "gunjan/latitude") {
      latitude = double.parse(message);
      print("Changed the value of the latitude");
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MapWidget(
                  client: client,
                  latitude: latitude,
                  longitude: longitude,
                )),
      );
    }

    if (topic == "gunjan/alive") {
      _isAlive = true;
      lastTime = DateTime.now();
    }

    if (topic == "gunjan/longitude") {
      longitude = double.parse(message);
      print("Changed the value of the latitude");
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MapWidget(
                  client: client,
                  latitude: latitude,
                  longitude: longitude,
                )),
      );
    }

    if (topic == "gunjan/lux") {
      double lux = double.parse(message);
      if (lux > 0.01) {
        FirebaseFirestore.instance
            .collection('lux')
            .add({'lux': lux, 'time': DateTime.now()}).then(
                (DocumentReference doc) =>
                    print("DocumentSnapshot added with ID ${doc.id}"));
      }
      // send data to firestore

    }

    setState(() {
      msg = message;
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
      print(e);
    });
    latitude = _currentPosition.latitude;
    longitude = _currentPosition.longitude;
    print("GOT LOCATION");
    // show an alert dialog to the user that location has been obtained
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Location Obtained"),
          content: Text(
              "Location has been obtained. Click OK to see the location of the cycle."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MapWidget(
                              client: client,
                              latitude: latitude,
                              longitude: longitude,
                            )));
              },
            )
          ],
        );
      },
    );
  }
}
