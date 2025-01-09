import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:syncfusion_flutter_charts/charts.dart';

typedef MapChartController = Map<String, Map<String, dynamic>>;

class RealTime extends StatefulWidget {
  const RealTime({super.key});

  @override
  State<RealTime> createState() => _RealTimeState();
}


class _RealTimeState extends State<RealTime> {

  late IO.Socket socket;
  late Timer? _timer;
  Map<String, dynamic> bikeInfo = initMap();


  /*
  The variable chartDataAndController shoud look like this:
  {
  "acel_x": {
      "chartData": List<CartesianChartPoint>,
      "controller": ChartSeriesController
    }
  }
  */
  MapChartController chartDataAndController = initMapChartController();

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
    String api_url_socket = "wss://js1ehn5fl00j.share.zrok.io"; // IF IT'S IN LOCALHOST, PLEASE CHANGE IT TO 'http' INSTEAD OF 'https'
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
      updateBikeInfoList(bikeInfo, chartDataAndController);
      setState(() {
        bikeInfo = jsonDecode(data);
        chartDataAndController = chartDataAndController;
      });
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
                width: 700,
                height: 700,
                child: buildXYZCard("ACELERAÇÃO",
                    {"title": "Aceleração X", "value": "${bikeInfo["acel_x"]} m/s²"},
                    {"title": "Aceleração Y", "value": "${bikeInfo["acel_y"]} m/s²"},
                    {"title": "Aceleração Z", "value": "${bikeInfo["acel_z"]} m/s²"},
                    chartDataAndController)
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

Widget buildXYZCard(String cardTitle, Map<String, String> dataX, Map<String, String> dataY, Map<String, String> dataZ, MapChartController _chartController) {
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
          buildXYZChart(cardTitle, "acel_x", _chartController)
        ],
      ),
    ),
  );
}

Widget buildXYZChart(String title, String mapVal, MapChartController _chartController) {

  return Container(
    width: 400,
    height: 400,
    child: SfCartesianChart(
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
        primaryXAxis: DateTimeAxis(
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
                _chartController[mapVal]?["controller"] = controller;
              },
              color: Colors.lightBlue.shade900,
              width: 3.5,
              dataSource: _chartController[mapVal]?["chartData"],
              xValueMapper: (CartesianChartPoint point, _) => point.date,
              yValueMapper: (CartesianChartPoint point, _) => point.value,
              enableTooltip: true,
              dataLabelSettings:DataLabelSettings(isVisible : true, color: Colors.lightBlue.shade700, borderRadius: 20)
          )
        ]
    ),
  );
}

/*
jsonDecode para transformar em Map
atualizar a lista dos valores
setState no decode e na lista
*/

void updateBikeInfoList(Map<String, dynamic> _bikeInfo, MapChartController _chartController) async {

  DateTime currentTime = DateTime.now();

  _chartController.forEach((key, subMap) {

    subMap["chartData"].add(CartesianChartPoint(currentTime, _bikeInfo[key] as num));

    if (subMap["chartData"].length == 10) {
      subMap["chartData"].removeAt(0);
      subMap["controller"]?.updateDataSource(
        addedDataIndexes: <int>[subMap["chartData"].length - 1],
        removedDataIndexes: <int>[0],
      );
    } else {
      subMap["controller"]?.updateDataSource(
        addedDataIndexes: <int>[subMap["chartData"].length - 1],
      );
    }
  });

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

MapChartController initMapChartController() {
  MapChartController newMap = {
    "acel_x": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "acel_y": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "acel_z": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "vel_x": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "vel_y": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "vel_z": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "roll": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "pitch": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "yaw": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "esterc": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "long": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "lat": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "veloc": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
  };
  return newMap;
}


class CartesianChartPoint {
  CartesianChartPoint(this.date, this.value);
  final DateTime date;
  final num value;
}
