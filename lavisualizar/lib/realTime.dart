import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class RealTime extends StatefulWidget {
  const RealTime({super.key});

  @override
  State<RealTime> createState() => _RealTimeState();
}

class _RealTimeState extends State<RealTime> {

  late IO.Socket socket;
  late Timer? _timer;
  Map<String, dynamic> bikeInfo = initMap();

  @override
  void dispose() {
    _timer?.cancel();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  initSocket() {
    String api_url_socket = "wss://doc4981u1tzc.share.zrok.io"; // IF IT'S IN LOCALHOST, PLEASE CHANGE IT TO 'http' INSTEAD OF 'https'
    socket = IO.io(api_url_socket, <String, dynamic>{
      'autoConnect': false,
      'transports': ['websocket'],
    });
    socket.connect();
    socket.onConnect((_) {
      print('Connection established');
    });
    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
    socket.on('send',(data){
      setState(() {
        bikeInfo = jsonDecode(data);
      });
      print("bikeInfo: ${bikeInfo}\nVALOR DA ACELERAÇÃO: ${bikeInfo["acel_x"]}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: ListView(
        children: [
          SizedBox(height: 30,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 300,
                height: 300,
                child: buildXYZCard("ACELERAÇÃO",
                    {"title": "Aceleração X", "value": "${bikeInfo["acel_x"]} m/s²"},
                    {"title": "Aceleração Y", "value": "${bikeInfo["acel_y"]} m/s²"},
                    {"title": "Aceleração Z", "value": "${bikeInfo["acel_z"]} m/s²"})
              ),
              Container(
                width: 300,
                height: 300,
                child: buildXYZCard("ACELERAÇÃO",
                    {"title": "Aceleração X", "value": "${bikeInfo["acel_x"]} m/s²"},
                    {"title": "Aceleração Y", "value": "${bikeInfo["acel_y"]} m/s²"},
                    {"title": "Aceleração Z", "value": "${bikeInfo["acel_z"]} m/s²"})
              ),
              Container(
                width: 300,
                height: 300,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Roll"),
                        Text("Pitch"),
                        Text("Yaw"),
                      ],
                    ),
                  ),

                ),
              ),
            ],
          )
        ],
      )
    );
  }
}

Card buildXYZCard(String cardTitle, Map<String, String> dataX, Map<String, String> dataY, Map<String, String> dataZ) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            child: Text(cardTitle),
          ),
          SizedBox(height: 30,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(dataX["title"] ?? ""),
                  Text(dataX["value"] ?? ""),
                ],
              ),
              Column(
                children: [
                  Text(dataY["title"] ?? ""),
                  Text(dataY["value"] ?? ""),
                ],
              ),
              Column(
                children: [
                  Text(dataZ["title"] ?? ""),
                  Text(dataZ["value"] ?? ""),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Map<String, dynamic> initMap() {
  Map<String, dynamic> newMap = {
    "id": "",
    "acel_x": "",
    "acel_y": "",
    "acel_z": "",
    "vel_x": "",
    "vel_y": "",
    "vel_z": "",
    "roll": "",
    "pitch": "",
    "yaw": "",
    "esterc": "",
    "long": "",
    "lat": "",
    "veloc": "",
  };
  return newMap;
}
