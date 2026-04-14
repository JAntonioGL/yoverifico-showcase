import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:yoverifico_app/main.dart';
import 'package:yoverifico_app/models/vehiculo_modelos.dart';
import 'package:yoverifico_app/providers/usuario_provider.dart';
import 'package:yoverifico_app/services/auth_service.dart';
import 'package:yoverifico_app/widgets/main_layout.dart';
import 'package:yoverifico_app/helpers/calificacion_helper.dart';
import 'package:yoverifico_app/widgets/dialogo_calificacion.dart';

import '../../../widgets/vehiculo_id_card_editable.dart';
import '../../../models/vehiculo_registrado.dart';
import '../../../providers/catalogo_provider.dart';
import '../../../providers/vehiculos_registrados_provider.dart';
import '../../../services/vehiculo_service.dart';
import '../../../services/acciones_backend_service.dart';
import '../../../helpers/flujo_anuncio_helper.dart';
import '../../../services/rutas_acciones.dart';

class EditarVehiculoScreen extends StatefulWidget {
  final VehiculoRegistrado vehiculo;
  const EditarVehiculoScreen({super.key, required this.vehiculo});

  @override
  State<EditarVehiculoScreen> createState() => _EditarVehiculoScreenState();
}

class _EditarVehiculoScreenState extends State<EditarVehiculoScreen>
    with SingleTickerProviderStateMixin {
  // Estado UI
  bool _modoEdicion = false;
  bool _procesando = false;

  // Animación de salida (para eliminación exitosa)
  late final AnimationController _exitCtrl;
  late final Animation<double> _fadeOut;
  late final Animation<Offset> _slideDown;
  bool _isExiting = false;

  // Estado original (para comparar)
  late final String? _origNombre;
  late final int _origLineaId;
  late final int _origColorId;
  late final String _origModelo; // en tu modelo es String

  // Estado actual editable
  String? _nombreActual;
  int? _lineaIdActual;
  int? _marcaIdActual; // derivada de línea
  int? _colorIdActual;
  String? _modeloActual; // string (4 dígitos)

  // Validaciones
  final _nombreRegex =
      RegExp(r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 ]{1,10}$'); // 10 máx, con espacios

  @override
  void initState() {
    super.initState();

    // Anim
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curve = CurvedAnimation(parent: _exitCtrl, curve: Curves.easeOut);
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(curve);
    _slideDown = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.04))
        .animate(curve);

    // Estado original
    _origNombre = widget.vehiculo.nombre;
    _origLineaId = widget.vehiculo.lineaId;
    _origColorId = widget.vehiculo.colorId;
    _origModelo = widget.vehiculo.modelo;

    // Editable
    _nombreActual = _origNombre;
    _lineaIdActual = _origLineaId;
    _colorIdActual = _origColorId;
    _modeloActual = _origModelo;

    // Marca derivada
    final catalogo = context.read<CatalogoProvider>();
    final linea = catalogo.lineas.firstWhere(
      (l) => l.id == _lineaIdActual,
      orElse: () => catalogo.lineas.first,
    );
    _marcaIdActual = linea.marcaId;
  }

  @override
  void dispose() {
    _exitCtrl.dispose();
    super.dispose();
  }

  bool get _hayCambios {
    final nombreTrim = (_nombreActual ?? '').trim();
    final origNombreTrim = (_origNombre ?? '').trim();
    final diffNombre = nombreTrim != origNombreTrim;

    final diffLinea = (_lineaIdActual ?? _origLineaId) != _origLineaId;
    final diffColor = (_colorIdActual ?? _origColorId) != _origColorId;
    final diffModelo = (_modeloActual ?? _origModelo) != _origModelo;

    // Si el usuario deja nombre vacío, lo tratamos como "sin cambio"
    final nombreCuentaComoCambio =
        diffNombre && nombreTrim.isNotEmpty; // evitar borrar a vacío

    return nombreCuentaComoCambio || diffLinea || diffColor || diffModelo;
  }

  // Helpers de datos actuales (para mostrar)
  String _marcaActualNombre(CatalogoProvider cat) {
    final marca = cat.marcas.firstWhere(
      (m) => m.id == (_marcaIdActual ?? 0),
      orElse: () => cat.marcas.isNotEmpty
          ? cat.marcas.first
          : const MarcaVehiculo(id: 0, nombre: 'N/A'),
    );
    return marca.nombre;
  }

  String _lineaActualNombre(CatalogoProvider cat) {
    final linea = cat.lineas.firstWhere(
      (l) => l.id == (_lineaIdActual ?? 0),
      orElse: () => cat.lineas.isNotEmpty
          ? cat.lineas.first
          : const LineaVehiculo(id: 0, nombre: 'N/A', marcaId: 0),
    );
    return linea.nombre;
  }

  ColorVehiculo _colorActual(CatalogoProvider cat) {
    final c = cat.colores.firstWhere(
      (c) => c.id == (_colorIdActual ?? 0),
      orElse: () => cat.colores.isNotEmpty
          ? cat.colores.first
          : const ColorVehiculo(id: 0, nombre: 'N/A', hex: '000000'),
    );
    return c;
  }

  EstadoMexico _estadoActual(CatalogoProvider cat) {
    return cat.estados.firstWhere(
      (e) => e.id == widget.vehiculo.estadoId,
      orElse: () =>
          const EstadoMexico(id: 0, nombre: 'No encontrado', abrev: 'N/A'),
    );
  }

  Future<void> _verificarYMostrarPopupCalificacionDespuesAccion() async {
    final debeMostrar =
        await CalificacionHelper.evaluarMostrarDespuesDeAccion();

    if (!mounted) return;

    if (debeMostrar) {
      await mostrarDialogoCalificacion(context);
    }
  }

  Future<void> _editarNombre() async {
    final ctrl = TextEditingController(text: _nombreActual ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ej. Mi carro',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Guardar')),
        ],
      ),
    );

    if (res == null) return; // cancelado
    final value = res.trim();

    if (value.isEmpty) {
      // Tratar como "sin cambio": dejar null o vacío no debe mandarse
      setState(() => _nombreActual = '');
      return;
    }

    if (!_nombreRegex.hasMatch(value)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Nombre inválido: máx 10, sin caracteres especiales.')),
      );
      return;
    }

    setState(() => _nombreActual = value);
  }

  Future<void> _editarLinea() async {
    final catalogo = context.read<CatalogoProvider>();
    final lineaSel = await showModalBottomSheet<LineaVehiculo>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final fc = FocusNode();
        final ac = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Buscar línea (puedes buscar por marca o línea)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    RawAutocomplete<LineaVehiculo>(
                      textEditingController: ac,
                      focusNode: fc,
                      optionsBuilder: (TextEditingValue tev) {
                        final q = tev.text.trim().toLowerCase();
                        if (q.isEmpty) return catalogo.lineas;
                        return catalogo.lineas.where((linea) {
                          final marca = catalogo.marcas.firstWhere(
                            (m) => m.id == linea.marcaId,
                            orElse: () =>
                                const MarcaVehiculo(id: 0, nombre: ''),
                          );
                          return linea.nombre.toLowerCase().contains(q) ||
                              marca.nombre.toLowerCase().contains(q);
                        }).toList();
                      },
                      displayStringForOption: (linea) {
                        final marca = catalogo.marcas.firstWhere(
                          (m) => m.id == linea.marcaId,
                          orElse: () =>
                              const MarcaVehiculo(id: 0, nombre: 'Otro'),
                        );
                        return '${marca.nombre} - ${linea.nombre}';
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Busca por marca o línea',
                            hintText: 'Ej. Aveo, Tsuru, Gol...',
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 260),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (_, i) {
                                  final opt = options.elementAt(i);
                                  final marca = catalogo.marcas.firstWhere(
                                    (m) => m.id == opt.marcaId,
                                    orElse: () => const MarcaVehiculo(
                                        id: 0, nombre: 'Otro'),
                                  );
                                  return ListTile(
                                    title:
                                        Text('${opt.nombre} - ${marca.nombre}'),
                                    onTap: () => onSelected(opt),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (linea) => Navigator.pop(ctx, linea),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cerrar'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (lineaSel == null) return;
    setState(() {
      _lineaIdActual = lineaSel.id;
      _marcaIdActual = lineaSel.marcaId;
    });
  }

  Future<void> _editarColor() async {
    final catalogo = context.read<CatalogoProvider>();
    final nuevoColorId = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: catalogo.colores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = catalogo.colores[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _hexToColorSafe(c.hex),
                ),
                title: Text(c.nombre),
                onTap: () => Navigator.pop(ctx, c.id),
              );
            },
          ),
        );
      },
    );

    if (nuevoColorId == null) return;
    setState(() => _colorIdActual = nuevoColorId);
  }

  Color _hexToColorSafe(String hex) {
    var hc = hex.toUpperCase().replaceAll('#', '');
    if (hc.length == 6) hc = 'FF$hc';
    return Color(int.tryParse(hc, radix: 16) ?? 0xFF000000);
  }

  Future<void> _editarModelo() async {
    final ctrl = TextEditingController(text: (_modeloActual ?? '').trim());
    final res = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar modelo (año)'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ej. 2020',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Guardar')),
        ],
      ),
    );

    if (res == null) return;
    final nowYear = DateTime.now().year;
    final s = res.trim();
    final n = int.tryParse(s);
    if (n == null || n < 1900 || n > (nowYear + 1)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Modelo inválido. Debe estar entre 1900 y año_actual+1.')),
      );
      return;
    }
    setState(() => _modeloActual = n.toString());
  }

  Future<void> _confirmarYActualizar() async {
    if (!_hayCambios) return;

    final catalogo = context.read<CatalogoProvider>();
    final cambios = <String>[];

    // Nombre
    final nombreTrim = (_nombreActual ?? '').trim();
    final origNombreTrim = (_origNombre ?? '').trim();
    if (nombreTrim.isNotEmpty && nombreTrim != origNombreTrim) {
      cambios.add('Nombre: "$origNombreTrim" → "$nombreTrim"');
    }

    // Linea / Marca
    if ((_lineaIdActual ?? _origLineaId) != _origLineaId) {
      final beforeLinea = catalogo.lineas.firstWhere(
        (l) => l.id == _origLineaId,
        orElse: () => const LineaVehiculo(id: 0, nombre: 'N/A', marcaId: 0),
      );
      final beforeMarca = catalogo.marcas.firstWhere(
        (m) => m.id == beforeLinea.marcaId,
        orElse: () => const MarcaVehiculo(id: 0, nombre: 'N/A'),
      );
      final afterLinea = catalogo.lineas.firstWhere(
        (l) => l.id == (_lineaIdActual ?? 0),
        orElse: () => const LineaVehiculo(id: 0, nombre: 'N/A', marcaId: 0),
      );
      final afterMarca = catalogo.marcas.firstWhere(
        (m) => m.id == afterLinea.marcaId,
        orElse: () => const MarcaVehiculo(id: 0, nombre: 'N/A'),
      );
      cambios.add(
          'Marca/Línea: ${beforeMarca.nombre} ${beforeLinea.nombre} → ${afterMarca.nombre} ${afterLinea.nombre}');
    }

    // Color
    if ((_colorIdActual ?? _origColorId) != _origColorId) {
      final before = catalogo.colores.firstWhere(
        (c) => c.id == _origColorId,
        orElse: () => const ColorVehiculo(id: 0, nombre: 'N/A', hex: '000000'),
      );
      final after = catalogo.colores.firstWhere(
        (c) => c.id == (_colorIdActual ?? 0),
        orElse: () => const ColorVehiculo(id: 0, nombre: 'N/A', hex: '000000'),
      );
      cambios.add('Color: ${before.nombre} → ${after.nombre}');
    }

    // Modelo
    if ((_modeloActual ?? _origModelo) != _origModelo) {
      cambios.add('Modelo: ${_origModelo} → ${_modeloActual ?? _origModelo}');
    }

    final confirmCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          final listo = confirmCtrl.text.trim().toUpperCase() == 'CONFIRMO';
          return AlertDialog(
            title: const Text('Confirmar cambios'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cambios.isEmpty) const Text('No hay cambios.'),
                if (cambios.isNotEmpty) ...[
                  const Text('Se aplicarán los siguientes cambios:'),
                  const SizedBox(height: 8),
                  ...cambios.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text('• $c'),
                      )),
                  const SizedBox(height: 12),
                  const Text('Escribe CONFIRMO para continuar:'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmCtrl,
                    autofocus: true,
                    onChanged: (_) => setSt(() {}),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'CONFIRMO',
                    ),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: cambios.isNotEmpty && listo
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text('Confirmar')),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    await _ejecutarActualizacion();
  }

  Future<void> _ejecutarActualizacion() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      final body = <String, dynamic>{
        'id_vehiculo': widget.vehiculo.idVehiculo,
        'placa': widget.vehiculo.placa,
      };

      // Solo enviar campos que cambiaron
      final nombreTrim = (_nombreActual ?? '').trim();
      final origNombreTrim = (_origNombre ?? '').trim();
      if (nombreTrim.isNotEmpty && nombreTrim != origNombreTrim) {
        body['nombre'] = nombreTrim;
      }

      if ((_lineaIdActual ?? _origLineaId) != _origLineaId) {
        body['linea_id'] = _lineaIdActual;
      }

      if ((_colorIdActual ?? _origColorId) != _origColorId) {
        body['color_id'] = _colorIdActual;
      }

      if ((_modeloActual ?? _origModelo) != _origModelo) {
        final n = int.tryParse(_modeloActual ?? '');
        if (n != null) body['modelo'] = n;
      }

      if (body.keys.length <= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay campos para actualizar')),
          );
        }
        return;
      }

      final r = await FlujoAnuncioHelper.ejecutarAccionConAnuncio(
        context: context,
        pathAccionPrechequeo: RutasAcciones.editarVehiculoPrechequeo,
        pathAccionEjecutar: RutasAcciones.editarVehiculoEjecutar,
        body: body,
      );

      final statusOk = r.status >= 200 && r.status < 300;
      final bodyOk =
          r.data['ok'] == true || (r.data['resultado']?['ok'] == true);
      final ok = statusOk && bodyOk;

      if (!mounted) return;
      if (ok) {
        // Refrescar lista de vehículos
        try {
          final prov = context.read<VehiculosRegistradosProvider>();
          final nueva = await VehiculoService.getVehiculosDelUsuario();
          prov.setVehiculos(nueva);
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo actualizado')),
        );

        // 👇 Lógica de calificación/compartir después de una acción exitosa
        await _verificarYMostrarPopupCalificacionDespuesAccion();

        if (!mounted) return;
        Navigator.pop(context); // vuelve al detalle
        return;
      }

      final msg = r.data['msg'] ??
          (r.data['error'] == 'pase_usado'
              ? 'El pase ya fue utilizado'
              : r.data['error'] == 'pase_invalido'
                  ? 'Pase inválido'
                  : r.data['error'] == 'pase_pendiente'
                      ? 'Debes completar la recompensa para continuar'
                      : 'Error al actualizar');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error general: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _confirmarYEliminarVehiculo(BuildContext context) async {
    final v = widget.vehiculo;
    final catalogo = context.read<CatalogoProvider>();

    // Si tiene nombre usa ese, si no, usa "LÍNEA MARCA"
    final linea = catalogo.lineas.firstWhere(
      (l) => l.id == v.lineaId,
      orElse: () =>
          const LineaVehiculo(id: 0, nombre: 'Desconocida', marcaId: 0),
    );
    final marca = catalogo.marcas.firstWhere(
      (m) => m.id == linea.marcaId,
      orElse: () => const MarcaVehiculo(id: 0, nombre: 'Desconocida'),
    );

    final textoReferencia = (v.nombre != null && v.nombre!.trim().isNotEmpty)
        ? v.nombre!.trim()
        : '${linea.nombre} ${marca.nombre}';

    final confirmTextoEsperado =
        'CONFIRMO ELIMINAR ${textoReferencia.toUpperCase()}';

    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final ingreso = ctrl.text.trim().toUpperCase();
          final valido = ingreso == confirmTextoEsperado;

          return AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta acción es irreversible y no se puede deshacer.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor confirma la eliminación escribiendo exactamente:\n\n'
                  '"$confirmTextoEsperado"',
                  style: const TextStyle(height: 1.3),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Escribe aquí para confirmar',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: valido ? () => Navigator.pop(context, true) : null,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade800,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    setState(() => _procesando = true);
    try {
      final body = {'id_vehiculo': v.idVehiculo};

      final r = await FlujoAnuncioHelper.ejecutarAccionConAnuncio(
        context: context,
        pathAccionPrechequeo: RutasAcciones.eliminarVehiculoPrechequeo,
        pathAccionEjecutar: RutasAcciones.eliminarVehiculoEjecutar,
        body: body,
      );

      await _resolverResultadoEliminar(
        context,
        r,
        vehiculoEliminadoId: v.idVehiculo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error general: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _resolverResultadoEliminar(
    BuildContext context,
    ResultadoEjecucion r, {
    required int vehiculoEliminadoId,
  }) async {
    if (!mounted) return;

    final statusOk = r.status >= 200 && r.status < 300;
    final bodyOk = r.data['ok'] == true ||
        (r.data['resultado']?['ok'] == true) ||
        r.data['success'] == true ||
        r.data['deleted'] == true ||
        r.data.isEmpty;
    final ok = statusOk && bodyOk;

    if (!ok) {
      final msg = r.data['msg'] ??
          (r.data['error'] == 'pase_usado'
              ? 'El pase ya fue utilizado'
              : r.data['error'] == 'pase_invalido'
                  ? 'Pase inválido'
                  : r.data['error'] == 'pase_pendiente'
                      ? 'Debes completar la recompensa para continuar'
                      : 'Error al eliminar vehículo');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    // 1) Trae lista FRESCA del backend y persiste en provider/local
    final prov = context.read<VehiculosRegistradosProvider>();
    final nuevaLista =
        await VehiculoService.getVehiculosDelUsuario(); // <- hace persist local
    prov.setVehiculos(nuevaLista);

    // 2) Recalcula cupos inmediatamente desde la lista (por si el whoami tarda)
    await _recalcularCuposDesdeLista(context, nuevaLista);

    // 3) WhoAmI para alinear entitlements con backend (await, como en “agregar”)
    await AuthService.instance.reloginSilenciosoFull(context);

    if (!mounted) return;

    // 4) Mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehículo eliminado')),
    );

    // 👇 Lógica de calificación/compartir después de una acción exitosa
    await _verificarYMostrarPopupCalificacionDespuesAccion();

    if (!mounted) return;

    // 5) Navegación autoritaria directamente a “Mis Vehículos”
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/vehiculos/mios', (_) => false);
  }

  Future<void> _recalcularCuposDesdeLista(
    BuildContext context,
    List<VehiculoRegistrado> lista,
  ) async {
    final u = context.read<UsuarioProvider>();
    final max = u.maximoVehiculos; // viene en tu provider (default 1)
    final guardados = lista.length;
    final restantes = (max - guardados).clamp(-9999, 9999);
    // setSesion con los mismos campos que ya aceptas
    context.read<UsuarioProvider>().setSesion(
          usuario: u.usuario!,
          token: u.token!,
          codigoPlan: u.codigoPlan,
          conAnuncios: u.conAnuncios,
          maximoVehiculos: max,
          esPersonalizado: u.esPersonalizado,
          nombrePlan: u.nombrePlan,
          vehiGuardados: guardados,
          vehiRestantes: restantes,
          puedeAgregar: restantes > 0,
        );
  }

  Future<void> _goInicioYMisVehiculos() async {
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/home', (route) => false);
    await Future.delayed(const Duration(milliseconds: 50));
    navigatorKey.currentState?.pushNamed('/vehiculos/mios');
  }

  Future<void> _refreshCuposYLista(BuildContext context) async {
    // 1) Trae la lista actualizada del backend
    final nueva = await VehiculoService.getVehiculosDelUsuario();

    // 2) Inyecta en el provider (lista de vehículos)
    context.read<VehiculosRegistradosProvider>().setVehiculos(nueva);

    // 3) Relogin silencioso para actualizar UsuarioProvider
    //    (vehiGuardados, vehiRestantes, puedeAgregar, etc.)
    await AuthService.instance.reloginSilenciosoFull(context);
  }

  @override
  Widget build(BuildContext context) {
    final catalogoProvider = context.watch<CatalogoProvider>();

    // Derivados vivos para dibujar
    final marcaNombre = _marcaActualNombre(catalogoProvider);
    final lineaNombre = _lineaActualNombre(catalogoProvider);
    final colorActual = _colorActual(catalogoProvider);
    final estado = _estadoActual(catalogoProvider);

    final tituloPantalla = _modoEdicion ? 'Editar Vehículo' : 'Vehículo';
    int _restantesByList(
        UsuarioProvider u, VehiculosRegistradosProvider vProv) {
      final max = u.maximoVehiculos; // default 1
      final usados = vProv.vehiculos.length;
      return (max - usados).clamp(-9999, 9999);
    }

    int _restantesSmart(UsuarioProvider u, VehiculosRegistradosProvider vProv) {
      // Si el provider trae vehiRestantes y parece coherente, úsalo.
      final r = u.vehiRestantes;
      if (r != null && r >= 0 && r <= u.maximoVehiculos) return r;
      // Si no, derive desde la lista actual (consistente con la pantalla)
      return _restantesByList(u, vProv);
    }

    bool _canAddSmart(UsuarioProvider u, VehiculosRegistradosProvider vProv) {
      final rest = _restantesSmart(u, vProv);
      if (u.puedeAgregar == false) return false;
      return rest > 0;
    }

    // --- Contenido (lo que antes iba en Scaffold.body) ---
    final contenido = AbsorbPointer(
      absorbing: _procesando,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                VehiculoIdCardEditable(
                  marca: marcaNombre,
                  linea: lineaNombre,
                  modelo: _modeloActual,
                  placa: widget.vehiculo.placa,
                  colorNombre: colorActual.nombre,
                  colorHex: colorActual.hex,
                  estadoNombre: estado.nombre,
                  nombre: _nombreActual,
                  modoEdicion: _modoEdicion,
                  onEditarNombre: _modoEdicion ? _editarNombre : null,
                  onEditarLinea: _modoEdicion ? _editarLinea : null,
                  onEditarColor: _modoEdicion ? _editarColor : null,
                  onEditarModelo: _modoEdicion ? _editarModelo : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Placa y Estado no son modificables.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botones modo edición / lectura
                if (!_modoEdicion)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar información'),
                      onPressed: () => setState(() => _modoEdicion = true),
                    ),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            setState(() {
                              _modoEdicion = false;
                              _nombreActual = _origNombre;
                              _lineaIdActual = _origLineaId;
                              _colorIdActual = _origColorId;
                              _modeloActual = _origModelo;

                              final linea = catalogoProvider.lineas.firstWhere(
                                (l) => l.id == _origLineaId,
                                orElse: () => catalogoProvider.lineas.first,
                              );
                              _marcaIdActual = linea.marcaId;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Actualizar información'),
                          onPressed: _hayCambios ? _confirmarYActualizar : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('Acciones peligrosas',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Eliminar vehículo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade800,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        onPressed: _procesando
                            ? null
                            : () => _confirmarYEliminarVehiculo(context),
                      ),
                    ],
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_procesando)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );

    // --- AQUÍ USAS TU MainLayout ---
    return MainLayout(
      title: tituloPantalla,
      currentRouteName: '/vehiculos/editar', // pon la ruta que uses en tu app
      // Animación aplicada al hijo del MainLayout
      child: SlideTransition(
        position: _slideDown,
        child: FadeTransition(
          opacity: _fadeOut,
          child: contenido,
        ),
      ),
    );
  }
}
