// lib/screens/vehiculos/mis_vehiculos_home.sample.dart

/**
 * Pantalla Principal de Gestión Vehicular.
 * Orquesta la visualización de la flota, el motor de reglas de circulación 
 * y la comunicación proactiva de estatus legales.
 */
class MisVehiculosScreen extends StatefulWidget {
  const MisVehiculosScreen({super.key});

  @override
  State<MisVehiculosScreen> createState() => _MisVehiculosScreenState();
}

class _MisVehiculosScreenState extends State<MisVehiculosScreen> {
  @override
  void initState() {
    super.initState();
    // Ciclo de vida: Refresco de permisos de notificación y sincronización de flota.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermisoNotificacionesProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer2<VehiculosRegistradosProvider, ContingenciaProvider>(
        builder: (context, flotaProv, contingenciaProv, _) {
          return Column(
            children: [
              // Gestión de Engagement: Banner dinámico para permisos críticos.
              const BannerPermisoNotifiaciones(),

              // Estado Vacío: Guía al usuario a su primer registro mediante Lottie.
              if (flotaProv.vehiculos.isEmpty)
                _buildEmptyState()
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: flotaProv.vehiculos.length,
                    itemBuilder: (context, i) {
                      final v = flotaProv.vehiculos[i];

                      // Inferencia de Estatus: Se calculan reglas de verificación y
                      // restricciones de "Hoy No Circula" en tiempo real para cada ítem.
                      return _VehiculoListTile(
                        vehiculo: v,
                        contingencia: contingenciaProv.estadoActual,
                        onTap: () => _verDetalle(v),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _verDetalle(VehiculoRegistrado v) {
    // Navegación contextual: Envía el objeto completo como estafeta al detalle.
    Navigator.pushNamed(context, '/vehiculo/detalle', arguments: v);
  }
}
