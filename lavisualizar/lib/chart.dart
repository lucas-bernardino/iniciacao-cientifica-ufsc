import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:csv/csv.dart';

enum COLUMNS {
  ACEL_X,
  ACEL_Y,
  ACEL_Z,
  TEMP,
  VEL_X,
  VEL_Y,
  VEL_Z,
  ROLL,
  PITCH,
  YAW,
  MAG_X,
  MAG_Y,
  MAG_Z,
  PRESS_AR,
  ALT,
  LONG,
  LAT,
  VEL_GPS,
  ANG,
  HOUR,
  RPM,
  VEL_HALL
}

List<List<String>> CARD_INFO_GROUP = [
  ["ACELERAÇÃO MÁXIMA", "ACELERAÇÃO MÉDIA", "ACELERACAO MÍNIMA", "m/s²"],
  ["VELOCIDADE MÁXIMA", "VELOCIDADE MÉDIA", "VELOCIDADE MÍNIMO", "km/h"],
  ["ROLL MÁXIMO", "ROLL MÉDIO", "ROLL MÍNIMO", "rad"],
  ["PITCH MÁXIMO", "PITCH MÉDIO", "PITCH MÍNIMO", "rad"],
  ["YALL MÁXIMO", "YALL MÉDIO", "YALL MÍNIMO", "rad"],
  ["ESTERÇAMENTO MÁXIMO", "ESTERÇAMENTO MÉDIO", "ESTERÇAMENTO MÍNIMO", "deg"],
  ["LATITUDE", "LONGITUDE", "", ""]
];

List<List<String>> CARD_INFO_INDIVIDUAL = [
  ["ACELERAÇÃO X MÁXIMA", "ACELERAÇÃO X MÉDIA", "ACELERACAO X MÍNIMA", "m/s²"],
  ["ACELERAÇÃO Y MÁXIMA", "ACELERAÇÃO Y MÉDIA", "ACELERACAO Y MÍNIMA", "m/s²"],
  ["ACELERAÇÃO Z MÁXIMA", "ACELERAÇÃO Z MÉDIA", "ACELERACAO Z MÍNIMA", "m/s²"],
  ["ROLL MÁXIMO", "ROLL MÉDIO", "ROLL MÍNIMO", "rad"],
  ["PITCH MÁXIMO", "PITCH MÉDIO", "PITCH MÍNIMO", "rad"],
  ["YALL MÁXIMO", "YALL MÉDIO", "YALL MÍNIMO", "rad"],
  ["VELOCIDADE X MÁXIMA", "VELOCIDADE X MÉDIA", "VELOCIDADE X MÍNIMO", "km/h"],
  ["VELOCIDADE Y MÁXIMA", "VELOCIDADE Y MÉDIA", "VELOCIDADE Y MÍNIMO", "km/h"],
  ["VELOCIDADE Z MÁXIMA", "VELOCIDADE Z MÉDIA", "VELOCIDADE Z MÍNIMO", "km/h"],
];

class Chart extends StatefulWidget {
  const Chart({super.key});

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  bool _shouldDisplayFutureBuilder = false;
  bool _shouldDisplayOptions = false;
  double maxValue = 0;
  double avgValue = 0;
  int chartColumnOption = 17;
  Set<String> _chartQualitySelection = {"Performance"};
  Set<String> _chartGroupChoice = {"Individual"};

  List<bool> isButtonPressedGroup = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  List<bool> isButtonPressedIndividual = [
    false,
    false,
    false,
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 15.0),
                child: Image(
                  image: AssetImage('images/lav-logo.png'),
                  height: 200,
                  width: 200,
                ),
              ),
            ],
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _shouldDisplayFutureBuilder
                    ? FutureBuilder(
                        future: processCsv(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (_chartGroupChoice.contains("Individual")) {
                              return buildChartIndividual(
                                  context, snapshot.data!, chartColumnOption, _chartQualitySelection);
                            }
                            else {
                              return buildChartGroup(
                                  context, snapshot.data!, chartColumnOption, _chartQualitySelection);
                            }

                          } else {
                            return CircularProgressIndicator();
                          }
                        })
                    : const SizedBox(),
                SizedBox(
                  height: 20,
                ),
                MaterialButton(
                    elevation: 20,
                    padding: EdgeInsets.all(17),
                    color: Colors.grey,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    child: Text("Escolher Dado"),
                    onPressed: () {
                      setState(() {
                        _shouldDisplayFutureBuilder = false;
                        _shouldDisplayOptions = true;
                      });
                    }),
                SizedBox(height: 10,), //_chartGroupChoice
                SegmentedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.grey),
                  ),
                    segments: [
                      ButtonSegment(
                          value: "Performance",
                          label: Text("Performance"),
                      ),
                      ButtonSegment(
                          value: "Qualidade",
                          label: Text("Qualidade"),
                      ),
                    ],
                    selected: _chartQualitySelection,
                    onSelectionChanged: (newSelection) => {
                      setState(() {
                        _chartQualitySelection = newSelection;
                      })
                    },
                ),
                SizedBox(height: 10,),
                SegmentedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.grey),
                  ),
                  segments: [
                    ButtonSegment(
                      value: "Individual",
                      label: Text("Individual"),
                    ),
                    ButtonSegment(
                      value: "Grupo",
                      label: Text("Grupo"),
                    ),
                  ],
                  selected: _chartGroupChoice,
                  onSelectionChanged: (newSelection) => {
                    setState(() {
                      _chartGroupChoice = newSelection;
                    })
                  },
                )
              ],
            ),
          ),
          _shouldDisplayOptions
              ? (_chartGroupChoice.contains("Individual") ?
          Card(
            elevation: 20,
            child: Column(
              children: [
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isButtonPressedIndividual = isButtonPressedIndividual
                            .map(
                              (e) => false,
                        )
                            .toList();
                        isButtonPressedIndividual[0] = true;
                      });
                    },
                    style: isButtonPressedIndividual[0]
                        ? ButtonStyle(
                        backgroundColor:
                        MaterialStateProperty.all(Colors.grey))
                        : null,
                    child: Text("Aceleracao X | Aceleração Y | Aceleração Z")
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isButtonPressedIndividual = isButtonPressedIndividual
                            .map(
                              (e) => false,
                        )
                            .toList();
                        isButtonPressedIndividual[1] = true;
                      });
                    },
                    style: isButtonPressedIndividual[1]
                        ? ButtonStyle(
                        backgroundColor:
                        MaterialStateProperty.all(Colors.grey))
                        : null,
                    child: Text("Roll | Pitch | Yall")
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isButtonPressedIndividual = isButtonPressedIndividual
                            .map(
                              (e) => false,
                        )
                            .toList();
                        isButtonPressedIndividual[2] = true;
                      });
                    },
                    style: isButtonPressedIndividual[2]
                        ? ButtonStyle(
                        backgroundColor:
                        MaterialStateProperty.all(Colors.grey))
                        : null,
                    child: Text("Velocidade X | Velocidade Y | Velocidade Z")
                )
              ],
            ),
          ) :
          Card(
                  elevation: 20,
                  child: Column(
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 0;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[0] = true;
                            });
                          },
                          style: isButtonPressedGroup[0]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Aceleracao X")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 1;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[1] = true;
                            });
                          },
                          style: isButtonPressedGroup[1]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Aceleracao Y")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 2;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[2] = true;
                            });
                          },
                          style: isButtonPressedGroup[2]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Aceleracao Z")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 7;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[3] = true;
                            });
                          },
                          style: isButtonPressedGroup[3]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Roll")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 8;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[4] = true;
                            });
                          },
                          style: isButtonPressedGroup[4]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Pitch")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 9;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[5] = true;
                            });
                          },
                          style: isButtonPressedGroup[5]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Yall")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 17;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[6] = true;
                            });
                          },
                          style: isButtonPressedGroup[6]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Velocidade")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 16;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[7] = true;
                            });
                          },
                          style: isButtonPressedGroup[7]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Latitude/Longitude")),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartColumnOption = 18;
                              isButtonPressedGroup = isButtonPressedGroup
                                  .map(
                                    (e) => false,
                                  )
                                  .toList();
                              isButtonPressedGroup[8] = true;
                            });
                          },
                          style: isButtonPressedGroup[8]
                              ? ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.grey))
                              : null,
                          child: Text("Esterçamento")),
                      IconButton(
                        onPressed: () => setState(() {
                          _shouldDisplayFutureBuilder = true;
                          _shouldDisplayOptions = false;
                        }),
                        icon: Icon(Icons.check),
                      )
                    ],
                  ),
                ))
              : SizedBox()
        ],
      ),
    );
  }
}

Future<String?> getFilePath() async {
  final result = await FilePicker.platform.pickFiles(allowMultiple: false);
  if (result == null) return null;
  return result.files.first.path;
}

Future<List<List<dynamic>>> processCsv() async {
  String? path = await getFilePath();

  var result = await File(path!).readAsString();
  var csvList = const CsvToListConverter().convert(result, eol: "\n");

  return csvList;
}

Widget buildChartIndividual(
    BuildContext context, List<List<dynamic>> csvData, int value_column, Set<String> chartQuality) {
  List<DataPoints> _dataPoints = [];
  List<DataPointsGPS> _dataPointsGps = [];

  var time_column = COLUMNS.HOUR.index;

  double maxYAxis = csvData[1][value_column] as double;
  double minYAxis = csvData[1][value_column] as double;
  int csvLength = 0;
  double totalSum = 0;

  List<String> chartInfo = getInfoCard(value_column);

  bool isPerformance = chartQuality.contains("Performance");

  for (var item in csvData.skip(1)) {
    try {
      if (value_column == 16) {
        double long = item[15] as double;
        double lat = item[16] as double;
        _dataPointsGps.add(DataPointsGPS(lat, long));
        continue;
      }
      if (item[value_column] as double > maxYAxis) {
        maxYAxis = item[value_column] as double;
      }
      if (item[value_column] as double < minYAxis) {
        minYAxis = item[value_column] as double;
      }
      String rawDateTime = item[time_column].toString();
      int hour = int.parse(rawDateTime.substring(0, 2));
      int minutes = int.parse(rawDateTime.substring(3, 5));
      int seconds = int.parse(rawDateTime.substring(6, 8));
      int miliseconds = int.parse(rawDateTime.substring(9, 11));
      DateTime dateTime =
          DateTime(0, 0, 0, hour, minutes, seconds, miliseconds);
      _dataPoints.add(DataPoints(dateTime, item[value_column]));
      totalSum += item[value_column] as double;
      csvLength += 1;
    } catch (e) {
      print("DEU ERRO: ${e}");
    }
  }
  ;

  double avgValue = totalSum / csvLength;

  return Column(
    children: [
      value_column == 16
          ? SizedBox()
          : Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Card(
                elevation: 20,
                color: Colors.orange[500],
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Text(chartInfo[0]),
                          Text(
                              "${maxYAxis.toStringAsFixed(2)} ${chartInfo[3]}"),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Column(
                        children: [
                          Text(chartInfo[1]),
                          Text("${avgValue.toStringAsFixed(2)} ${chartInfo[3]}")
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Column(
                        children: [
                          Text(chartInfo[2]),
                          Text("${minYAxis.toStringAsFixed(2)} ${chartInfo[3]}")
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      SfCartesianChart(
        title: ChartTitle(
          text: value_column == 16
              ? "longitude em função da latitude"
              : "${chartInfo[0].split(" ")[0].toLowerCase()} em função do tempo",
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
        primaryXAxis: value_column != 16
            ? (isPerformance ? DateTimeAxis(
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                title: AxisTitle(text: "Horário"),
              ) : DateTimeCategoryAxis(
          labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          title: AxisTitle(text: "Horário"),
        ))
            : NumericAxis(
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                title: AxisTitle(text: "Latitude"),
              ),
        primaryYAxis: NumericAxis(
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          title: AxisTitle(
              text:
                  "${chartInfo[0].split(" ")[0].toLowerCase()} [${chartInfo[3]}]"),
          minimum: value_column != 16 ? (minYAxis - 1) : null,
          maximum: value_column != 16 ? (maxYAxis + 1) : null,
        ),
        series: value_column != 16
            ? <FastLineSeries<DataPoints, DateTime>>[
                // Initialize line series with data points
                FastLineSeries<DataPoints, DateTime>(
                  color: Colors.orange[500],
                  dataSource: _dataPoints,
                  xValueMapper: (DataPoints value, _) => value.x,
                  yValueMapper: (DataPoints value, _) => value.y,
                ),
              ]
            : <ChartSeries<DataPointsGPS, double>>[
                // Initialize line series with data points
                LineSeries<DataPointsGPS, double>(
                  color: Colors.orange[500],
                  dataSource: _dataPointsGps,
                  xValueMapper: (DataPointsGPS value, _) => value.x,
                  yValueMapper: (DataPointsGPS value, _) => value.y,
                ),
              ].cast<CartesianSeries>(),
      ),
    ],
  );
}

Widget buildChartGroup(
    BuildContext context, List<List<dynamic>> csvData, int value_column, Set<String> chartQuality) {
  List<DataPoints> _dataPoints = [];
  List<DataPointsGPS> _dataPointsGps = [];

  var time_column = COLUMNS.HOUR.index;

  double maxYAxis = csvData[1][value_column] as double;
  double minYAxis = csvData[1][value_column] as double;
  int csvLength = 0;
  double totalSum = 0;

  List<String> chartInfo = getInfoCard(value_column);

  bool isPerformance = chartQuality.contains("Performance");

  for (var item in csvData.skip(1)) {
    try {
      if (value_column == 16) {
        double long = item[15] as double;
        double lat = item[16] as double;
        _dataPointsGps.add(DataPointsGPS(lat, long));
        continue;
      }
      if (item[value_column] as double > maxYAxis) {
        maxYAxis = item[value_column] as double;
      }
      if (item[value_column] as double < minYAxis) {
        minYAxis = item[value_column] as double;
      }
      String rawDateTime = item[time_column].toString();
      int hour = int.parse(rawDateTime.substring(0, 2));
      int minutes = int.parse(rawDateTime.substring(3, 5));
      int seconds = int.parse(rawDateTime.substring(6, 8));
      int miliseconds = int.parse(rawDateTime.substring(9, 11));
      DateTime dateTime =
      DateTime(0, 0, 0, hour, minutes, seconds, miliseconds);
      _dataPoints.add(DataPoints(dateTime, item[value_column]));
      totalSum += item[value_column] as double;
      csvLength += 1;
    } catch (e) {
      print("DEU ERRO: ${e}");
    }
  }
  ;

  double avgValue = totalSum / csvLength;

  return Column(
    children: [
      value_column == 16
          ? SizedBox()
          : Padding(
        padding: const EdgeInsets.only(left: 40.0),
        child: Card(
          elevation: 20,
          color: Colors.orange[500],
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Column(
                  children: [
                    Text(chartInfo[0]),
                    Text(
                        "${maxYAxis.toStringAsFixed(2)} ${chartInfo[3]}"),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Column(
                  children: [
                    Text(chartInfo[1]),
                    Text("${avgValue.toStringAsFixed(2)} ${chartInfo[3]}")
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Column(
                  children: [
                    Text(chartInfo[2]),
                    Text("${minYAxis.toStringAsFixed(2)} ${chartInfo[3]}")
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      SfCartesianChart(
        title: ChartTitle(
          text: value_column == 16
              ? "longitude em função da latitude"
              : "${chartInfo[0].split(" ")[0].toLowerCase()} em função do tempo",
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
        primaryXAxis: value_column != 16
            ? (isPerformance ? DateTimeAxis(
          labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          title: AxisTitle(text: "Horário"),
        ) : DateTimeCategoryAxis(
          labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          title: AxisTitle(text: "Horário"),
        ))
            : NumericAxis(
          labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          title: AxisTitle(text: "Latitude"),
        ),
        primaryYAxis: NumericAxis(
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          title: AxisTitle(
              text:
              "${chartInfo[0].split(" ")[0].toLowerCase()} [${chartInfo[3]}]"),
          minimum: value_column != 16 ? (minYAxis - 1) : null,
          maximum: value_column != 16 ? (maxYAxis + 1) : null,
        ),
        series: value_column != 16
            ? <FastLineSeries<DataPoints, DateTime>>[
          // Initialize line series with data points
          FastLineSeries<DataPoints, DateTime>(
            color: Colors.orange[500],
            dataSource: _dataPoints,
            xValueMapper: (DataPoints value, _) => value.x,
            yValueMapper: (DataPoints value, _) => value.y,
          ),
        ]
            : <ChartSeries<DataPointsGPS, double>>[
          // Initialize line series with data points
          LineSeries<DataPointsGPS, double>(
            color: Colors.orange[500],
            dataSource: _dataPointsGps,
            xValueMapper: (DataPointsGPS value, _) => value.x,
            yValueMapper: (DataPointsGPS value, _) => value.y,
          ),
        ].cast<CartesianSeries>(),
      ),
    ],
  );
}

List<String> getInfoCard(int value_column) {
  switch (value_column) {
    case 0:
    case 1:
    case 2:
      return CARD_INFO_GROUP[0];
    case 7:
      return CARD_INFO_GROUP[2];
    case 8:
      return CARD_INFO_GROUP[3];
    case 9:
      return CARD_INFO_GROUP[4];
    case 17:
      return CARD_INFO_GROUP[1];
    case 18:
      return CARD_INFO_GROUP[5];
    case 16:
      return CARD_INFO_GROUP[6];
  }

  return [""];
}

class DataPoints {
  DataPoints(this.x, this.y);

  final DateTime? x;
  final num? y;
}

class DataPointsGPS {
  DataPointsGPS(this.x, this.y);

  final double? x;
  final double? y;
}
