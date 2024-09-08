import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lavisualizar/chart.dart';

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
                label: Text("Gráficos"),
              ),
              NavigationRailDestination(
                  icon: Icon(Icons.settings_applications_outlined),
                  selectedIcon: Icon(Icons.settings_applications, ),
                  label: Text("Configurações")
              )
            ],
          selectedIndex: _selectedIndex,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  Chart(),
                  Text("CONFIGURACOES")
                ],
              )
          )
        ],
      ),
    );
  }
}
