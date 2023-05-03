// // @dart=2.9
// import 'package:flutter/material.dart';
// import 'package:mqtt_client/mqtt_client.dart' as mqtt;
// import 'dart:async';

// class MQTTUtility extends StatefulWidget {
//   const MQTTUtility({Key key, this.title}) : super(key: key);

//   final String title;

//   @override
//   State<MQTTUtility> createState() => _MQTTUtilityState();
// }

// class _MQTTUtilityState extends State<MQTTUtility> {
//   String broker = '91.121.93.94';
//   int port = 1883;
//   String username = 'seu_username';
//   String password = 'seu_password';
//   String clientIdentifier = 'android';
//   String message = "Hello from flutter";

//   mqtt.MqttClient client;
//   mqtt.MqttConnectionState connectionState;

//   StreamSubscription subscription;

//   void _subscribeToTopic(String topic) {
//     if (connectionState == mqtt.MqttConnectionState.connected) {
//       client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
//     }
//   }

//   void _connect() async {
//     client = mqtt.MqttClient(broker, '');
//     client.port = port;
//     client.logging(on: true);
//     client.keepAlivePeriod = 30;
//     client.onDisconnected = _onDisconnected;

//     final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
//         .withClientIdentifier(clientIdentifier)
//         .startClean() // Non persistent session for testing
//         .withWillQos(mqtt.MqttQos.atMostOnce);
//     client.connectionMessage = connMess;

//     try {
//       await client.connect();
//     } catch (e) {
//       print(e);
//       _disconnect();
//     }

//     if (client.connectionStatus.state == mqtt.MqttConnectionState.connected) {
//       setState(() {
//         connectionState = client.connectionStatus.state;
//       });
//     } else {
//       _disconnect();
//     }
//     print("MQTT Client connected");

//     subscription = client.updates.listen(_onMessage);

//     _subscribeToTopic("esp/test1");
//   }

//   void _disconnect() {
//     print('[MQTT client] _disconnect()');
//     client.disconnect();
//     _onDisconnected();
//   }

//   void _onDisconnected() {
//     print('[MQTT client] _onDisconnected');
//     setState(() {
//       //topics.clear();
//       connectionState = client.connectionState;
//       client = null;
//       subscription.cancel();
//       subscription = null;
//     });
//     print('[MQTT client] MQTT client disconnected');
//   }

//   void _onMessage(List<mqtt.MqttReceivedMessage> event) {
//     print(event.length);
//     final mqtt.MqttPublishMessage recMess =
//         event[0].payload as mqtt.MqttPublishMessage;
//     final String message =
//         mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

//     print('[MQTT client] MQTT message: topic is <${event[0].topic}>, '
//         'payload is <-- ${message} -->');
//     print(client.connectionState);
//     print("[MQTT client] message with topic: ${event[0].topic}");
//     print("[MQTT client] message with message: ${message}");
//     setState(() {
//       _temp = double.parse(message);
//     });
//   }
// }
