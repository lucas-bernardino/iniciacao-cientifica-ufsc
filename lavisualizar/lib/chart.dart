import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:csv/csv.dart';

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

  print("dados: aaa${csvData.length}");

  return Text("Supostamente o SfCartesianChart");

  /*
  return SfCartesianChart(
    title: const ChartTitle(
      text: "Decibéis ao longo do tempo",
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
        )
    ),
    primaryYAxis: const NumericAxis(
        labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500
        )
    ),
    series: <FastLineSeries<DataPoints, DateTime>>[
      // Initialize line series with data points
      FastLineSeries <DataPoints, DateTime>(
        color: Colors.lightBlue,
        dataSource: _dataSource,
        xValueMapper: (DataPoints value, _) => value.x,
        yValueMapper: (DataPoints value, _) => value.y,
      ),
    ],
  ); */
}

class DataPoints {
  DataPoints (this.x, this.y);
  final DateTime? x;
  final num? y;
}