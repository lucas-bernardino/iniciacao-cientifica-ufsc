import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:dio/dio.dart';

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

  List<bool> toggleButtonsAccel = [false, false, false];
  List<bool> toggleButtonsVel = [false, false, false];
  List<bool> toggleButtonsAxis = [false, false, false];

  List<bool> toggleButtonOneDimensionalVel = [true, false];
  List<bool> toggleButtonOneDimensionalEsterc = [true, false];
  List<bool> toggleButtonGPS = [true, false];

  bool timerSocketFlag = false;

  bool isShowingDatabase = false;
  List<DropdownMenuEntry> dropdownList = [];

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
    _timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    initSocket();
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        timerSocketFlag = true;
      });
    });
  }

  String API_URL = "http://localhost:3001";
  initSocket() {
    socket = IO.io(API_URL, <String, dynamic>{
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
    socket.on('send', (data) {
      if (timerSocketFlag) {
        bikeInfo = jsonDecode(data);
        updateBikeInfoList(bikeInfo, chartDataAndController);
        setState(() {
          bikeInfo = jsonDecode(data);
          chartDataAndController = chartDataAndController;
          timerSocketFlag = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black87,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                    width: 480,
                    height: 380,
                    child: buildXYZCard(
                        "ACELERAÇÃO",
                        "acel",
                        {
                          "title": "Aceleração X",
                          "value": "${bikeInfo["acel_x"]} m/s²"
                        },
                        {
                          "title": "Aceleração Y",
                          "value": "${bikeInfo["acel_y"]} m/s²"
                        },
                        {
                          "title": "Aceleração Z",
                          "value": "${bikeInfo["acel_z"]} m/s²"
                        },
                        chartDataAndController,
                        setState,
                        toggleButtonsAccel)),
                Container(
                    width: 480,
                    height: 380,
                    child: buildXYZCard(
                        "VELOCIDADE",
                        "vel",
                        {
                          "title": "Velocidade X",
                          "value": "${bikeInfo["vel_x"]} rad/s"
                        },
                        {
                          "title": "Velocidade Y",
                          "value": "${bikeInfo["vel_y"]} rad/s"
                        },
                        {
                          "title": "Velocidade Z",
                          "value": "${bikeInfo["vel_z"]} rad/s"
                        },
                        chartDataAndController,
                        setState,
                        toggleButtonsVel)),
                Container(
                    width: 480,
                    height: 380,
                    child: buildXYZCard(
                        "EIXO",
                        "axis",
                        {"title": "Roll", "value": "${bikeInfo["roll"]} º"},
                        {"title": "Pitch", "value": "${bikeInfo["pitch"]} º"},
                        {"title": "Yaw", "value": "${bikeInfo["yaw"]} º"},
                        chartDataAndController,
                        setState,
                        toggleButtonsAxis)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await downloadCsv(API_URL);
                  },
                  child: Text(
                    "Download CSV",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.lightBlue;
                      }
                      return Colors.lightBlueAccent;
                    }),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 200,
                  child: Stack(
                    children: [
                      Positioned(
                        child: IconButton(
                          onPressed: () async {
                            List<String> tmpString = await getListCollectionsContinuous(API_URL);
                            List<DropdownMenuEntry> tmpDropdown = [];
                            for (var name in tmpString) {
                              tmpDropdown.add(DropdownMenuEntry(value: name, label: name));
                            }
                            setState(() {
                              dropdownList = tmpDropdown;
                              isShowingDatabase = !isShowingDatabase;
                            });
                          },
                          icon: Icon(MdiIcons.database),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.lightBlue;
                              }
                              return Colors.lightBlueAccent;
                            }),
                          ),
                        ),
                      ),
                      if (isShowingDatabase)
                        Positioned(
                          left: 50,
                          child: DropdownMenu(
                            menuHeight: 200,
                            dropdownMenuEntries: dropdownList,
                            textStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                    width: 480,
                    height: 380,
                    child: buildOneDimensionalCard(
                        "VELOCIDADE GPS",
                        "veloc",
                        {"title": "Velocidade GPS", "value": "${bikeInfo["veloc"]} º"},
                        chartDataAndController, toggleButtonOneDimensionalVel, setState)),
                Container(
                    width: 480,
                    height: 380,
                    child: buildOneDimensionalCard(
                        "ESTERÇAMENTO DO GUIDÃO",
                        "esterc",
                        {"title": "ESTERÇAMENTO", "value": "${bikeInfo["esterc"]} º"},
                        chartDataAndController, toggleButtonOneDimensionalEsterc, setState),),
              Container(
                width: 480,
                height: 380,
                child: buildGPSCard(chartDataAndController, toggleButtonGPS, setState),
              )
              ],
            )
          ],
        ));
  }
}

Widget buildXYZCard(
    String cardTitle,
    String mapVal,
    Map<String, String> dataX,
    Map<String, String> dataY,
    Map<String, String> dataZ,
    MapChartController _chartController,
    Function setStateCallback,
    List<bool> _toggleButtonsAccel) {
  return Card(
    color: Colors.black45,
    elevation: 10,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            child: Text(
              cardTitle,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    dataX["title"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    dataX["value"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    dataY["title"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    dataY["value"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    dataZ["title"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    dataZ["value"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          buildXYZChart(cardTitle, mapVal, _chartController,
              _toggleButtonsAccel, setStateCallback),
        ],
      ),
    ),
  );
}

Widget buildOneDimensionalCard(
    String cardTitle,
    String mapVal,
    Map<String, String> data,
    MapChartController _chartController,
    List<bool> _toggleButtons,
    Function setStateCallback) {
  return Card(
    color: Colors.black45,
    elevation: 10,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            child: Text(
              cardTitle,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    data["title"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    data["value"] ?? "",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          buildOneDimensionalChart(mapVal, _chartController, _toggleButtons, setStateCallback),
        ],
      ),
    ),
  );
}

Widget buildXYZChart(
    String title,
    String mapVal,
    MapChartController _chartController,
    List<bool> _toggleButtonsAccel,
    Function setStateCallback) {
  List<LineSeries<CartesianChartPoint, DateTime>> series = [];

  List<Color> chartColors = [
    Colors.yellow[500]!,
    Colors.greenAccent,
    Colors.blue[500]!
  ];

  List<List<String>> nameXyz = [
    ["acel_x", "acel_y", "acel_z"],
    ["vel_x", "vel_y", "vel_z"],
    ["roll", "pitch", "yaw"]
  ];

  List<String> currentNameXyz = [];

  switch (mapVal) {
    case "acel":
      currentNameXyz = nameXyz[0];
      break;
    case "vel":
      currentNameXyz = nameXyz[1];
      break;
    case "axis":
      currentNameXyz = nameXyz[2];
      break;
  }

  for (int i = 0; i < 3; i++) {
    String dataName = currentNameXyz[i];
    Color dataColor = chartColors[i];

    if (_toggleButtonsAccel[i] == true) {
      series.add(
        LineSeries<CartesianChartPoint, DateTime>(
            onRendererCreated: (ChartSeriesController controller) {
              _chartController[dataName]?["controller"] = controller;
            },
            color: dataColor,
            dataSource: _chartController[dataName]?["chartData"],
            xValueMapper: (CartesianChartPoint point, _) => point.date,
            yValueMapper: (CartesianChartPoint point, _) => point.value,
            enableTooltip: true,
            dataLabelSettings: DataLabelSettings(
                isVisible: true,
                color: dataColor,
                borderRadius: 100,
                textStyle: TextStyle(fontSize: 10))),
      );
    } else {
      _chartController[dataName]?["controller"] = null;
    }
  }

  return Container(
    width: double.infinity,
    height: 250,
    child: Column(
      children: [
        Container(
          height: 200,
          child: SfCartesianChart(
              title: ChartTitle(
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 5,
                ),
              ),
              enableAxisAnimation: true,
              tooltipBehavior: TooltipBehavior(
                color: Colors.deepOrange,
                enable: true,
                borderColor: Colors.deepOrange,
                header: "",
              ),
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true,
                enableMouseWheelZooming: true,
                enablePinching: true,
              ),
              primaryXAxis: DateTimeAxis(
                  majorGridLines: MajorGridLines(width: 0),
                  labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 4,
                      fontWeight: FontWeight.w500),
                  title: AxisTitle(
                      text: "Tempo",
                      textStyle: TextStyle(color: Colors.white))),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0),
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 4,
                  fontWeight: FontWeight.w500,
                ),
                title: AxisTitle(
                    text: "$mapVal", textStyle: TextStyle(color: Colors.white)),
              ),
              series: series),
        ),
        ToggleButtons(
          isSelected: _toggleButtonsAccel,
          onPressed: (int index) {
            setStateCallback(() {
              _toggleButtonsAccel[index] = !_toggleButtonsAccel[index];
            });
          },
          children: <Widget>[
            Icon(MdiIcons.alphaX),
            Icon(MdiIcons.alphaY),
            Icon(MdiIcons.alphaZ),
          ],
        ),
      ],
    ),
  );
}

Widget buildOneDimensionalChart(
    String mapVal,
    MapChartController _chartController,
    List<bool> _toggleButton,
    Function setStateCallback) {

  bool isPlayIcon = _toggleButton[1];

  return Container(
    width: double.infinity,
    height: 250,
    child: Column(
      children: [
        isPlayIcon ? Container(
          height: 200,
          child: SfCartesianChart(
            title: ChartTitle(
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 5,
              ),
            ),
            enableAxisAnimation: true,
            tooltipBehavior: TooltipBehavior(
              color: Colors.deepOrange,
              enable: true,
              borderColor: Colors.deepOrange,
              header: "",
            ),
            zoomPanBehavior: ZoomPanBehavior(
              enablePanning: true,
              enableMouseWheelZooming: true,
              enablePinching: true,
            ),
            primaryXAxis: DateTimeAxis(
                majorGridLines: MajorGridLines(width: 0),
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 4,
                    fontWeight: FontWeight.w500),
                title: AxisTitle(
                    text: "Tempo", textStyle: TextStyle(color: Colors.white))),
            primaryYAxis: NumericAxis(
              majorGridLines: MajorGridLines(width: 0),
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 4,
                fontWeight: FontWeight.w500,
              ),
              title: AxisTitle(
                  text: "$mapVal", textStyle: TextStyle(color: Colors.white)),
            ),
            series: [
              LineSeries<CartesianChartPoint, DateTime>(
                  onRendererCreated: (ChartSeriesController controller) {
                    _chartController[mapVal]?["controller"] = controller;
                  },
                  color: Colors.green,
                  dataSource: _chartController[mapVal]?["chartData"],
                  xValueMapper: (CartesianChartPoint point, _) => point.date,
                  yValueMapper: (CartesianChartPoint point, _) => point.value,
                  enableTooltip: true,
                  dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      color: Colors.green,
                      borderRadius: 100,
                      textStyle: TextStyle(fontSize: 10)))
            ],
          ),
        ) : SizedBox(),
        ToggleButtons(
          isSelected: _toggleButton,
          onPressed: (int index) {
            setStateCallback(() {
              for (int i = 0; i < _toggleButton.length; i++) {
                _toggleButton[i] = i == index;
              }
            });
          },
          children: <Widget>[
            Icon(Icons.close),
            Icon(Icons.play_arrow_rounded),
          ],
        ),
      ],
    ),
  );
}

Widget buildGPSCard(MapChartController _chartController, List<bool> _toggleButtons, Function setStateCallback) {
  return Card(
    color: Colors.black45,
    elevation: 10,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            child: Text(
              "LOCALIZAÇÃO POR GPS",
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          buildGPSChart(_chartController, _toggleButtons, setStateCallback),
        ],
      ),
    ),
  );
}

Widget buildGPSChart(MapChartController _chartController, List<bool> _toggleButton, Function setStateCallback) {

  bool isPlayIcon = _toggleButton[1];
  return Container(
    width: double.infinity,
    height: 250,
    child: Column(
      children: [
        isPlayIcon ? Container(
          height: 200,
          child: SfCartesianChart(
            title: ChartTitle(
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 5,
              ),
            ),
            enableAxisAnimation: true,
            tooltipBehavior: TooltipBehavior(
              color: Colors.deepOrange,
              enable: true,
              borderColor: Colors.deepOrange,
              header: "",
            ),
            zoomPanBehavior: ZoomPanBehavior(
              enablePanning: true,
              enableMouseWheelZooming: true,
              enablePinching: true,
            ),
            primaryXAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0),
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 4,
                    fontWeight: FontWeight.w500),
                title: AxisTitle(
                    text: "Latitude", textStyle: TextStyle(color: Colors.white))),
            primaryYAxis: NumericAxis(
              majorGridLines: MajorGridLines(width: 0),
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 4,
                fontWeight: FontWeight.w500,
              ),
              title: AxisTitle(
                  text: "Longitude", textStyle: TextStyle(color: Colors.white)),
            ),
            series: [
              LineSeries<GPSChartPoint, num>(
                  onRendererCreated: (ChartSeriesController controller) {
                    _chartController["gps"]?["controller"] = controller;
                  },
                  color: Colors.green,
                  dataSource: _chartController["gps"]?["chartData"],
                  xValueMapper: (GPSChartPoint point, _) => point.lat,
                  yValueMapper: (GPSChartPoint point, _) => point.long,
                  enableTooltip: true,)
            ],
          ),
        ) : SizedBox(),
        ToggleButtons(
          isSelected: _toggleButton,
          onPressed: (int index) {
            setStateCallback(() {
              for (int i = 0; i < _toggleButton.length; i++) {
                _toggleButton[i] = i == index;
              }
            });
          },
          children: <Widget>[
            Icon(Icons.close),
            Icon(Icons.play_arrow_rounded),
          ],
        ),
      ],
    ),
  );
}

Future<void> downloadCsv(String URL) async{
  final dio = Dio();

  final rs = await dio.get(
    "${URL}/download",
    options: Options(responseType: ResponseType.stream),
  );

  DateTime currentTime = DateTime.now();

  String? outputFileName = await FilePicker.platform.saveFile(
    dialogTitle: 'Please select an output file:',
    fileName: 'dados${currentTime.toString().replaceAll(":", "-").replaceAll(" ", "_")}.csv',
  );

  if (outputFileName != null) {
    final file = File(outputFileName);
    final fileStream = file.openWrite();

    await for (final chunk in rs.data.stream) {
      fileStream.add(chunk);
    }

    await fileStream.close();
  }
}

void updateBikeInfoList(
    Map<String, dynamic> _bikeInfo, MapChartController _chartController) async {
  DateTime currentTime = DateTime.now();

  _chartController.forEach((key, subMap) {

    if (key == "gps" ) {
      num latitude = _bikeInfo["lat"] is num ? _bikeInfo["lat"] : num.parse(_bikeInfo["lat"]);
      num longitude = _bikeInfo["long"] is num ? _bikeInfo["long"] : num.parse(_bikeInfo["long"]);
      subMap["chartData"].add(GPSChartPoint(latitude, longitude));
    } else {
      var value = _bikeInfo[key] is num ? _bikeInfo[key] : num.parse(_bikeInfo[key]);
      subMap["chartData"].add(CartesianChartPoint(currentTime, value));
    }

    if (subMap["chartData"].length == 30) {
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

Future<List<String>> getListCollectionsContinuous(String url) async {
  final response = await http.get(Uri.parse('$url/collections'));
  final response_json = json.decode(response.body);
  List<String> collectionNames = [];
  var collections = response_json["collectionNames"];
  for (var collection in collections) {
    collectionNames.add(collection);
  }
  collectionNames.sort();
  return collectionNames;
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
    "veloc": {
      "controller": null,
      "chartData": List<CartesianChartPoint>.empty(growable: true)
    },
    "gps": {
      "controller": null,
      "chartData": List<GPSChartPoint>.empty(growable: true)
    },
  };
  return newMap;
}

class CartesianChartPoint {
  CartesianChartPoint(this.date, this.value);

  final DateTime date;
  final num value;
}

class GPSChartPoint {
  GPSChartPoint(this.lat, this.long);

  final num lat;
  final num long;
}
