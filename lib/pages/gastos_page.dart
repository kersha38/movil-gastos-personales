import 'package:flutter/material.dart';
import '../models/gasto.dart';
import '../services/api_service.dart';
import 'gasto_form_page.dart';

class GastosPage extends StatefulWidget {
  const GastosPage({super.key});

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final _apiService = ApiService();
  List<Gasto> _gastos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => _cargando = true);
    try {
      final gastos = await _apiService.getGastos();
      setState(() => _gastos = gastos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar gastos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirFormulario() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GastoFormPage()),
    );
    if (creado == true) _cargarGastos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarGastos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _gastos.isEmpty
              ? const Center(child: Text('No hay gastos registrados'))
              : ListView.builder(
                  itemCount: _gastos.length,
                  itemBuilder: (context, index) {
                    final gasto = _gastos[index];
                    return _GastoTile(gasto: gasto);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        tooltip: 'Agregar gasto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GastoTile extends StatelessWidget {
  final Gasto gasto;

  const _GastoTile({required this.gasto});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '\$',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(gasto.descripcion),
      subtitle: Text(
        '${gasto.categoriaNombre} · ${gasto.pagadorNombre}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${gasto.monto.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (gasto.esRecurrente)
                const Icon(Icons.repeat, size: 14, color: Colors.grey),
              if (gasto.perteneceAlSri)
                const Icon(Icons.receipt, size: 14, color: Colors.grey),
              if (!gasto.esCompartido)
                const Icon(Icons.person, size: 14, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
