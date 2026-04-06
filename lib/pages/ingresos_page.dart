import 'package:flutter/material.dart';

class IngresosPage extends StatelessWidget {
  const IngresosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Lista de ingresos',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
