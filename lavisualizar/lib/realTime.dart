import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:syncfusion_flutter_charts/charts.dart';

class RealTime extends StatefulWidget {
  const RealTime({super.key});

  @override
  State<RealTime> createState() => _RealTimeState();
}

class _RealTimeState extends State<RealTime> {

  late IO.Socket socket;
  late Timer? _timer;
  Map<String, dynamic> bikeInfo = initMap();

  Map<String, List<dynamic>> listOfBikeInfo = initListOfBikeInfo();
  Map<String, ChartSeriesController?> _chartSeriesController = {
    "acel_x": null,
    "acel_y": null,
    "acel_z": null,
    "vel_x": null,
    "vel_y": null,
    "vel_z": null,
};

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
      bikeInfo = jsonDecode(data);
      updateBikeInfoList(bikeInfo, listOfBikeInfo, _chartSeriesController);
      setState(() {
        bikeInfo = jsonDecode(data);
        listOfBikeInfo = listOfBikeInfo;
        _chartSeriesController = _chartSeriesController;
      });
      log("listOfBikeInfo: $listOfBikeInfo");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly ,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: 450,
                height: 300,
                child: buildXYZCard("ACELERAÇÃO",
                    {"title": "Aceleração X", "value": "${bikeInfo["acel_x"]} m/s²"},
                    {"title": "Aceleração Y", "value": "${bikeInfo["acel_y"]} m/s²"},
                    {"title": "Aceleração Z", "value": "${bikeInfo["acel_z"]} m/s²"},
                    _chartSeriesController["acel_x"]!, listOfBikeInfo)
              ),
              /*
              Container(
                width: 450,
                height: 300,
                child: buildXYZCard("VELOCIDADE",
                    {"title": "Velocidade X", "value": "${bikeInfo["vel_x"]} rad/s"},
                    {"title": "Velocidade Y", "value": "${bikeInfo["vel_y"]} rad/s"},
                    {"title": "Velocidade Z", "value": "${bikeInfo["vel_z"]} rad/s"})
              ),
              Container(
                  width: 450,
                  height: 300,
                  child: buildXYZCard("EIXO",
                      {"title": "Roll", "value": "${bikeInfo["roll"]} º"},
                      {"title": "Pitch", "value": "${bikeInfo["pitch"]} º"},
                      {"title": "Yaw", "value": "${bikeInfo["yaw"]} º"})
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                  width: 450,
                  height: 300,
                  child: buildXYZCard("ACELERAÇÃO",
                      {"title": "Aceleração X", "value": "${bikeInfo["acel_x"]} m/s²"},
                      {"title": "Aceleração Y", "value": "${bikeInfo["acel_y"]} m/s²"},
                      {"title": "Aceleração Z", "value": "${bikeInfo["acel_z"]} m/s²"},
                      )
              ),
              Container(
                  width: 450,
                  height: 300,
                  child: buildXYZCard("VELOCIDADE",
                      {"title": "Velocidade X", "value": "${bikeInfo["vel_x"]} rad/s"},
                      {"title": "Velocidade Y", "value": "${bikeInfo["vel_y"]} rad/s"},
                      {"title": "Velocidade Z", "value": "${bikeInfo["vel_z"]} rad/s"})
              ),
              Container(
                  width: 450,
                  height: 300,
                  child: buildXYZCard("EIXO",
                      {"title": "Roll", "value": "${bikeInfo["roll"]} º"},
                      {"title": "Pitch", "value": "${bikeInfo["pitch"]} º"},
                      {"title": "Yaw", "value": "${bikeInfo["yaw"]} º"})
              ),*/
            ],
          )
        ],
      )
    );
  }
}

Widget buildXYZCard(String cardTitle, Map<String, String> dataX, Map<String, String> dataY, Map<String, String> dataZ, ChartSeriesController _controller, Map<String, List<dynamic>> _listOfBikeInfo) {
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
          buildXYZChart(cardTitle, "acel_x", _controller, _listOfBikeInfo)
        ],
      ),
    ),
  );
}

Widget buildXYZChart(String title, String mapVal, ChartSeriesController _controller, Map<String, List<dynamic>> _listOfBikeInfo) {

  List<CartesianChartPoint> chartData = [];

  int forLoopSize = _listOfBikeInfo["time"]?.length ?? 0;

  for (int i = 0; i < forLoopSize; i++) {
    chartData.add(CartesianChartPoint(_listOfBikeInfo["time"]?[i], _listOfBikeInfo[mapVal]?[i]));
  }

  return SfCartesianChart(
      title: ChartTitle(
        text: "${title} em função do tempo",
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      enableAxisAnimation: true,
      tooltipBehavior: TooltipBehavior(
        color: Colors.deepOrange,
        enable: true,
        borderColor: Colors.deepOrange,
        borderWidth: 2,
        header: "",
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enableMouseWheelZooming: true,
        enablePinching: true,
      ),
      primaryXAxis: NumericAxis(
          labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          title: AxisTitle(text: "Pontos")
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        title: AxisTitle(
            text: "TITULO"),
      ),
      series: <CartesianSeries>[
        LineSeries<CartesianChartPoint, DateTime>(
            onRendererCreated: (ChartSeriesController controller) {
               _controller = controller;
            },
            color: Colors.lightBlue.shade900,
            width: 3.5,
            dataSource: chartData,
            xValueMapper: (CartesianChartPoint point, _) => point.date,
            yValueMapper: (CartesianChartPoint point, _) => point.value,
            enableTooltip: true,
            dataLabelSettings:DataLabelSettings(isVisible : true, color: Colors.lightBlue.shade700, borderRadius: 20)
        )
      ]
  );
}

/*
jsonDecode para transformar em Map
atualizar a lista dos valores
setState no decode e na lista
*/

void updateBikeInfoList(Map<String, dynamic> _bikeInfo, Map<String, List<dynamic>> _listOfBikeInfo, Map<String, ChartSeriesController?> _controller) async {

  DateTime currentTime = DateTime.now();

  _listOfBikeInfo["acel_x"]?.add(_bikeInfo["acel_x"]);
  _listOfBikeInfo["acel_y"]?.add(_bikeInfo["acel_y"]);
  _listOfBikeInfo["acel_x"]?.add(_bikeInfo["acel_z"]);

  _listOfBikeInfo["vel_x"]?.add(_bikeInfo["vel_x"]);
  _listOfBikeInfo["vel_y"]?.add(_bikeInfo["vel_y"]);
  _listOfBikeInfo["vel_z"]?.add(_bikeInfo["vel_z"]);

  _listOfBikeInfo["time"]?.add(currentTime);

  _listOfBikeInfo.forEach((key, listOfPoints) {
    if (listOfPoints.length > 100) {
      listOfPoints.removeAt(0);
    }
    _controller[key]?.updateDataSource(addedDataIndexes: <int>[listOfPoints.length - 1], removedDataIndexes: <int>[0]);
  });

  if (_controller != null) {
    print("N SOU NULO 1");
  }
  if (_controller["acel_x"] != null ) {
    print("N SOU NULO 2");
  }

  log("_listOfBikeInfo: $_listOfBikeInfo");
  log("controller: $_controller");
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

Map<String, List<dynamic>> initListOfBikeInfo() {
  Map<String, List<dynamic>> newList = {
    "id": [],
    "acel_x": [],
    "acel_y": [],
    "acel_z": [],
    "vel_x": [],
    "vel_y": [],
    "vel_z": [],
    "roll": [],
    "pitch": [],
    "yaw": [],
    "esterc": [],
    "long": [],
    "lat": [],
    "veloc": [],
  };

  return newList;
}

class CartesianChartPoint {
  CartesianChartPoint(this.date, this.value);
  final DateTime date;
  final num value;
}
