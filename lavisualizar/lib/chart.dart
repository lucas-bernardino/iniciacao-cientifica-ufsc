import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:csv/csv.dart';

enum COLUMNS{
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


class Chart extends StatefulWidget {
  const Chart({super.key});

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {

  bool _shouldDisplayFutureBuilder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Image(image: AssetImage('images/lav-logo.png'), height: 300, width: 300,),
            _shouldDisplayFutureBuilder ? FutureBuilder(
              future: processCsv(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return buildChart(context, snapshot.data!);
                } else {
                  return CircularProgressIndicator();
                }
              }
            ) : const SizedBox(),
            SizedBox(height: 20,),
            MaterialButton(
                padding: EdgeInsets.all(17),
                color: Colors.grey,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))
                ),
                child: Text("Adicionar Arquivos"),
                onPressed: () {
                  setState(() {
                    _shouldDisplayFutureBuilder = !_shouldDisplayFutureBuilder;
                  });
                }
            ),
          ],
        ),
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

Widget buildChart(BuildContext context, List<List<dynamic>> csvData) {

  List<DataPoints> _dataPoints = [];

  var time_column = COLUMNS.HOUR.index;
  var value_column = COLUMNS.VEL_GPS.index;

  double maxYAxis = csvData[value_column][1] as double;
  double minYAxis = csvData[value_column][1] as double;

  for (var item in csvData.skip(1)) {
    try {
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
      DateTime dateTime = DateTime(0, 0, 0, hour, minutes, seconds, miliseconds);
      _dataPoints.add(DataPoints(dateTime, item[value_column]));
    } catch (e) {
      print("DEU ERRO");
    }
  };

  print("max: ${maxYAxis}, min: ${minYAxis}");

  return SfCartesianChart(
    title: const ChartTitle(
      text: "Velocidade GPS em função do tempo",
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    enableAxisAnimation: true,
    tooltipBehavior: TooltipBehavior(
      color: Colors.lightBlue.shade400,
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
    primaryXAxis: const DateTimeCategoryAxis(
        labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500
        ),
      title: AxisTitle(text: "Horário"),
    ),
    primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500
        ),
        minimum: (minYAxis - 3).roundToDouble(),
        maximum: (maxYAxis + 3).roundToDouble(),
        title: const AxisTitle(text: "km/h"),
  ),
    series: <FastLineSeries<DataPoints, DateTime>>[
      // Initialize line series with data points
      FastLineSeries <DataPoints, DateTime>(
        color: Colors.lightBlue,
        dataSource: _dataPoints,
        xValueMapper: (DataPoints value, _) => value.x,
        yValueMapper: (DataPoints value, _) => value.y,
      ),
    ],
  );
}

class DataPoints {
  DataPoints (this.x, this.y);
  final DateTime? x;
  final num? y;
}