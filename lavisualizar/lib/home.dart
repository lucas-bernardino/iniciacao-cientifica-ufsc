import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lavisualizar/chart.dart';
import 'package:lavisualizar/comparar.dart';
import 'package:lavisualizar/realTime.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xEE000000),
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.poll_outlined),
                selectedIcon: Icon(Icons.poll),
                label: Text(
                  "Gráficos",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              NavigationRailDestination(
                  icon: Icon(Icons.settings_applications_outlined),
                  selectedIcon: Icon(
                    Icons.settings_applications,
                  ),
                  label: Text(
                    "Comparar",
                    style: TextStyle(color: Colors.white),
                  )),
              NavigationRailDestination(
                icon: Icon(Icons.live_tv_outlined),
                selectedIcon: Icon(Icons.live_tv),
                label: Text(
                  "Tempo Real",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            selectedIndex: _selectedIndex,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
              child: IndexedStack(
            index: _selectedIndex,
            children: const [Chart(), Comparison(), RealTime()],
          ))
        ],
      ),
    );
  }
}
