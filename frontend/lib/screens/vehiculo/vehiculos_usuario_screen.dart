// lib/screens/vehiculos/vehiculos_usuario_screen.dart

/**
 * Pantalla: Mis Vehículos (Listado General)
 * Propósito: Proporcionar una visión global de la flota, permitiendo búsquedas
 * rápidas y acceso a la gestión individual de cada unidad.
 */
class VehiculosUsuarioScreen extends StatefulWidget {
  final bool isSelectionMode; // Soporta flujos de selección (ej. para citas)

  const VehiculosUsuarioScreen({super.key, this.isSelectionMode = false});

  @override
  State<VehiculosUsuarioScreen> createState() => _VehiculosUsuarioScreenState();
}

class _VehiculosUsuarioScreenState extends State<VehiculosUsuarioScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // Escucha activa de la flota y catálogos para renderizado reactivo
    final flota = context.watch<VehiculosRegistradosProvider>().vehiculos;
    final cat = context.watch<CatalogoProvider>();

    // Filtrado en tiempo real basado en placa o nombre amigable
    final vehiculosFiltrados = flota.where((v) {
      final matchPlaca = v.placa.toLowerCase().contains(_query.toLowerCase());
      final matchNombre = (v.nombre ?? '').toLowerCase().contains(
        _query.toLowerCase(),
      );
      return matchPlaca || matchNombre;
    }).toList();

    return MainLayout(
      title: 'Mis Vehículos',
      child: Column(
        children: [
          // Barra de búsqueda con debounce visual
          _buildSearchBar(),

          Expanded(
            child: vehiculosFiltrados.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vehiculosFiltrados.length,
                    itemBuilder: (context, i) {
                      final v = vehiculosFiltrados[i];

                      // Card con lógica visual de verificación (colores por estatus)
                      return _VehiculoListCard(
                        vehiculo: v,
                        marcaLinea: cutils.getMarcaLineaFull(v.lineaId, cat),
                        onTap: () => _handleAction(v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleAction(VehiculoRegistrado v) {
    if (widget.isSelectionMode) {
      // Retorna el vehículo seleccionado al flujo que lo invocó
      Navigator.pop(context, v);
    } else {
      // Navegación profunda al detalle operativo
      Navigator.pushNamed(context, '/vehiculo/detalle', arguments: v);
    }
  }
}
