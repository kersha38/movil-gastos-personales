import 'package:flutter/material.dart';

class ResumenPage extends StatelessWidget {
  const ResumenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Resumen de gastos e ingresos',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
