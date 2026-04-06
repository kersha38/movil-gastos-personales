import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/participante.dart';
import '../models/gasto.dart';
import '../services/api_service.dart';

class GastoFormPage extends StatefulWidget {
  const GastoFormPage({super.key});

  @override
  State<GastoFormPage> createState() => _GastoFormPageState();
}

class _GastoFormPageState extends State<GastoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _nuevaCategoriaController = TextEditingController();

  List<Categoria> _categorias = [];
  List<Participante> _participantes = [];
  bool _cargando = true;
  bool _guardando = false;

  Categoria? _categoriaSeleccionada;
  Participante? _pagadorSeleccionado;
  bool _esCompartido = true;
  double _porcentaje1 = 50;
  bool _esRecurrente = false;
  bool _perteneceAlSri = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _apiService.getCategorias(),
        _apiService.getParticipantes(),
      ]);
      setState(() {
        _categorias = resultados[0] as List<Categoria>;
        _participantes = resultados[1] as List<Participante>;
        if (_participantes.isNotEmpty) _pagadorSeleccionado = _participantes.first;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  double get _porcentaje2 => 100 - _porcentaje1;

  String get _nombreParticipante1 =>
      _participantes.isNotEmpty ? _participantes[0].nombre : 'Participante 1';

  String get _nombreParticipante2 =>
      _participantes.length > 1 ? _participantes[1].nombre : 'Participante 2';

  Future<void> _mostrarDialogNuevaCategoria() async {
    _nuevaCategoriaController.clear();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: _nuevaCategoriaController,
          decoration: const InputDecoration(labelText: 'Nombre'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmar == true && _nuevaCategoriaController.text.trim().isNotEmpty) {
      try {
        final nueva = await _apiService.crearCategoria(_nuevaCategoriaController.text.trim());
        setState(() {
          _categorias.add(nueva);
          _categoriaSeleccionada = nueva;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear categoría: $e')),
          );
        }
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    if (_pagadorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona quién pagó')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final participante2Id =
          _participantes.length > 1 ? _participantes[1].id : '';
      final participante2Nombre =
          _participantes.length > 1 ? _participantes[1].nombre : '';

      final gasto = Gasto(
        monto: double.parse(_montoController.text),
        descripcion: _descripcionController.text.trim(),
        categoriaId: _categoriaSeleccionada!.id,
        categoriaNombre: _categoriaSeleccionada!.nombre,
        pagadorId: _pagadorSeleccionado!.id,
        pagadorNombre: _pagadorSeleccionado!.nombre,
        participante1Id: _participantes.isNotEmpty ? _participantes[0].id : '',
        participante1Nombre: _nombreParticipante1,
        participante2Id: participante2Id,
        participante2Nombre: participante2Nombre,
        esCompartido: _esCompartido,
        porcentajeParticipante1: _esCompartido ? _porcentaje1 : 100,
        porcentajeParticipante2: _esCompartido ? _porcentaje2 : 0,
        esRecurrente: _esRecurrente,
        perteneceAlSri: _perteneceAlSri,
        timestamp: DateTime.now(),
      );

      await _apiService.crearGasto(gasto);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _nuevaCategoriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo gasto'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Monto
                  TextFormField(
                    controller: _montoController,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa un monto';
                      if (double.tryParse(v) == null) return 'Monto inválido';
                      if (double.parse(v) <= 0) return 'El monto debe ser mayor a 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa una descripción' : null,
                  ),
                  const SizedBox(height: 16),

                  // Categoría
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Categoria>(
                          value: _categoriaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                          ),
                          items: _categorias
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.nombre),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                          validator: (v) => v == null ? 'Selecciona una categoría' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _mostrarDialogNuevaCategoria,
                        icon: const Icon(Icons.add),
                        tooltip: 'Nueva categoría',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quién pagó
                  DropdownButtonFormField<Participante>(
                    value: _pagadorSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Quién pagó',
                      border: OutlineInputBorder(),
                    ),
                    items: _participantes
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.nombre),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _pagadorSeleccionado = v),
                    validator: (v) => v == null ? 'Selecciona quién pagó' : null,
                  ),
                  const SizedBox(height: 16),

                  // Compartido / Individual
                  Card(
                    child: SwitchListTile(
                      title: const Text('Gasto compartido'),
                      subtitle: Text(_esCompartido ? 'Entre los dos participantes' : 'Solo un participante'),
                      value: _esCompartido,
                      onChanged: (v) => setState(() => _esCompartido = v),
                    ),
                  ),

                  // Porcentajes (solo si es compartido)
                  if (_esCompartido) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'División del gasto',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_nombreParticipante1),
                                Text('${_porcentaje1.toStringAsFixed(0)}%'),
                              ],
                            ),
                            Slider(
                              value: _porcentaje1,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              onChanged: (v) => setState(() => _porcentaje1 = v),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_nombreParticipante2),
                                Text('${_porcentaje2.toStringAsFixed(0)}%'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Recurrente
                  Card(
                    child: SwitchListTile(
                      title: const Text('Repetir cada mes'),
                      subtitle: const Text('El backend lo registrará automáticamente'),
                      value: _esRecurrente,
                      onChanged: (v) => setState(() => _esRecurrente = v),
                    ),
                  ),

                  // SRI
                  Card(
                    child: SwitchListTile(
                      title: const Text('Pertenece al SRI'),
                      subtitle: const Text('Gasto con factura o comprobante fiscal'),
                      value: _perteneceAlSri,
                      onChanged: (v) => setState(() => _perteneceAlSri = v),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
