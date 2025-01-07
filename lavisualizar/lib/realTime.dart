import 'dart:async';

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
      print("Recebi: ${data}");
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Aceleração X"),
                        Text("Aceleração Y"),
                        Text("Aceleração Z"),
                      ],
                    ),
                  ),

                ),
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
                        Text("Velocidade X"),
                        Text("Velocidade Y"),
                        Text("Velocidade Z"),
                      ],
                    ),
                  ),

                ),
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
