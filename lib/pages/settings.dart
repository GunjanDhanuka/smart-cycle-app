import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    double _temp = 0.0;
    return Center(
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
                // FloatingActionButton(
                //   onPressed: () {
                //     // Navigator.pushNamed(context, '/location');
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => MapWidget()),
                //     );
                //   },
                //   tooltip: 'Map',
                //   child: Icon(Icons.map),
                // ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
