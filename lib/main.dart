import 'package:flutter/material.dart';
import 'pages/resumen_page.dart';
import 'pages/gastos_page.dart';
import 'pages/ingresos_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos Personales',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    ResumenPage(),
    GastosPage(),
    IngresosPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_downward),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_upward),
            label: 'Ingresos',
          ),
        ],
      ),
    );
  }
}
