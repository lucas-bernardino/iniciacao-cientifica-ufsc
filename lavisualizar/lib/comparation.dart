import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Compare extends StatefulWidget {
  const Compare({super.key});

  @override
  State<Compare> createState() => _CompareState();
}

class _CompareState extends State<Compare> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black87,
        body: Column(
          children: [
            ElevatedButton(
                onPressed: getFilePath,
                child: Text("Buscar Arquivos")
            )
          ],
        ),
    );
  }
}

Future<List<String>?> getFilePath() async {
  final result = await FilePicker.platform.pickFiles(allowMultiple: true);
  if (result == null) return null;
  List<String> listOfPaths = [];
  result.files.forEach((element) => listOfPaths.add(element.path.toString()),);
  print(listOfPaths.toString());
  return listOfPaths;
}