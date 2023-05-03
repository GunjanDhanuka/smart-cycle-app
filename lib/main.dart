// @dart=2.9
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:smart_cycle_app/pages/location.dart';
import 'package:smart_cycle_app/pages/lock.dart';
import 'package:smart_cycle_app/pages/splash.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';


void main() {
  runApp(MaterialApp(
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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      // home: const MyHomePage(title: 'Smart Cycle App'),
      // home: Splash(),
      home: AnimatedSplashScreen(
        // splash: Icons.motorcycle_rounded,
        // splashIconSize: 100,
        backgroundColor: Colors.orangeAccent,
        duration:1500,
        splashTransition: SplashTransition.fadeTransition,
        splash: Center(
          child: Column(
            children: [
              // cycle icon
              Icon(Icons.motorcycle_rounded, color: Colors.white, size: 30,),
              Container(
                  child: Text(
                    "Smart Cycle App",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  )
              ),
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

  @override  State<MyHomePage> createState() => _MyHomePageState();
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
  double latitude = 26.1113;
  double longitude = 91.4133;

  List<String> topics = ['gunjan/movement', 'gunjan/lock', 'gunjan/longitude', 'gunjan/latitude'];

  double _temp = 20;

  mqtt.MqttClient client;
  mqtt.MqttConnectionState connectionState;

  StreamSubscription subscription;

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
    }
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
        .withWillQos(mqtt.MqttQos.atMostOnce);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: Center(
          child:
              // wrap the text field in a container to set the width
              Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                child: Text("Value received from MQTT is: " + _temp.toString()),
              ),
              Container(
                width: 200,
                child: TextField(
                  // set the hint text
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
                child: TextField(
                  // set the hint text
                  decoration: InputDecoration(hintText: 'Enter the port'),
                  onChanged: (value) {
                    setState(() {
                      port = int.parse(value);
                    });
                  },
                ),
              ),
              Container(
                // textfield to ask for the topic to listen to
                width: 200,
                child: TextField(
                  // set the hint text
                  decoration:
                      InputDecoration(hintText: 'Enter the topic to subscribe'),
                  onChanged: (value) {
                    setState(() {
                      _subscribeToTopic(value);
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    // Add a
                    child: TextField(
                      // set the hint text
                      decoration: InputDecoration(
                          hintText: 'Enter the message to send on MQTT'),
                      onChanged: (value) {
                        setState(() {
                          message = value;
                        });
                      },
                    ),
                    width: 200,
                  ),
                  // add a gap of 10 pixels
                  SizedBox(
                    width: 10,
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      final mqtt.MqttClientPayloadBuilder builder =
                          mqtt.MqttClientPayloadBuilder();
                      builder.addString(message);
                      client.publishMessage("gunjan/node2phone",
                          mqtt.MqttQos.exactlyOnce, builder.payload);
                    },
                    tooltip: 'Publish',
                    child: Icon(Icons.publish),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FloatingActionButton(
                      onPressed: _connect,
                      tooltip: 'Play',
                      child: Icon(Icons.play_arrow),
                    ),
                    FloatingActionButton(
                      onPressed: _disconnect,
                      tooltip: 'Disconnect',
                      child: Icon(Icons.stop),
                    ),
                    // add a button with lock icon which will navigate to the lock page
                    FloatingActionButton(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/lock');
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
                    // add a button with map icon which will navigate to the map page
                    FloatingActionButton(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/location');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MapWidget(client: client, latitude: latitude, longitude: longitude,)),
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
      // bottomNavigationBar: BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   items: const <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.lock),
      //       label: 'Lock',
      //       backgroundColor: Colors.blue,
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.map),
      //       label: 'Map',
      //       backgroundColor: Colors.green,
      //     ),
      //     BottomNavigationBarItem(
      //         icon: Icon(Icons.settings),
      //         label: 'Settings',
      //       backgroundColor: Colors.yellow,
      //     ),
      //
      //   ],
      //   currentIndex: _selectedIndex,
      //   selectedItemColor: Colors.white,
      //   backgroundColor: Colors.orange,
      //   onTap: _onItemTapped,
      //   showUnselectedLabels: false,
      //
      // ),
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

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');
    setState(() {
      //topics.clear();
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
    if(topic == "gunjan/movement"){
      // show an alert dialog to the user
      print("ALERTTTT!");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Movement Detected"),
            content: Text("Movement has been detected in the cycle. Click OK to see the location of the cycle."),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MapWidget(client: client, latitude: latitude, longitude: longitude,)));
                },
              )
            ],
          );
        },
      );
    }

    if(topic == "gunjan/latitude"){
        latitude = double.parse(message);
        print("Changed the value of the latitude");
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapWidget(client: client, latitude: latitude, longitude: longitude,)),
        );
    }

    if(topic == "gunjan/longitude"){
        longitude = double.parse(message);
        print("Changed the value of the latitude");
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapWidget(client: client, latitude: latitude, longitude: longitude,)),
        );
    }

    // setState(() {
    //   _temp = double.parse(message);
    // });
  }
}

// TODO: Make navbar usable
// TODO: