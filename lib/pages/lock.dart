// @dart=2.9
// A page that has a toggle button to lock and unlock the cycle
// the toggle button is connected to the mqtt broker
// When the button is turned on, it sends a message to the broker and changes the state of the button
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class Lock extends StatefulWidget {
  const Lock({Key key, this.title, this.client}) : super(key: key);

  final String title;
  final mqtt.MqttClient client;
  

  @override
  State<Lock> createState() => _LockState(this.client);
}

class _LockState extends State<Lock> {
  bool _isLocked = false;
  mqtt.MqttClient client;
  mqtt.MqttConnectionState connectionState;
  String message = '';

  _LockState(this.client);


  Widget _lockButton() {
    return Switch(
      value: _isLocked,
      onChanged: (value) {
        setState(() {
          _isLocked = value;
        });
        // send a message to the broker when the button is turned on
        if (_isLocked) {
          print(client.connectionStatus);
          message = 'lock';
          final mqtt.MqttClientPayloadBuilder builder =
              mqtt.MqttClientPayloadBuilder();
          builder.addString(message);
          client.publishMessage('gunjan/lock', mqtt.MqttQos.exactlyOnce, builder.payload);
          print("Lock lock");
        }
        // send a message to the broker when the button is turned off
        else {
          message = 'unlock';
          final mqtt.MqttClientPayloadBuilder builder =
              mqtt.MqttClientPayloadBuilder();
          builder.addString(message);
          client.publishMessage('gunjan/lock', mqtt.MqttQos.exactlyOnce, builder.payload);
          print("unlock unlock");
        }
      },
      activeTrackColor: Colors.lightGreenAccent,
      activeColor: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lock'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _isLocked ? const Text('Locked') : const Text('Unlocked'),
            _isLocked ? const Icon(Icons.lock) : const Icon(Icons.lock_open),
            _lockButton(),
          ],
        ),
      ),
    );
  }


}
