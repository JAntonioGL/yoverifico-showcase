// lib/screens/notificaciones/notificaciones_screen.sample.dart

/**
 * NotificacionesScreen gestiona el centro de alertas de la aplicación.
 * Implementa un motor de ordenamiento inteligente por criticidad y 
 * control proactivo de permisos del sistema operativo.
 */
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Ciclo de vida: Sincroniza historial local y refresca estado de permisos nativos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacionesProvider>().cargarNotificaciones();
      context.read<PermisoNotificacionesProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacionesProvider>(
      builder: (context, prov, _) {
        // Motor de Ordenamiento:
        // 1. Contingencias (Críticas)
        // 2. Recomendaciones
        // 3. Estatus Vehicular (Vencidos/Periodo)
        final notifs = _ordenarInteligente(prov.notificaciones);

        return Column(
          children: [
            // Gestión de Engagement: Banner proactivo para habilitar notificaciones si están desactivadas.
            BannerPermisoNotifiaciones(
              visible: context
                  .watch<PermisoNotificacionesProvider>()
                  .bannerVisible,
              onActivate: () => _abrirAjustesOS(),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: notifs.length,
                itemBuilder: (context, i) {
                  final n = notifs[i];
                  return Dismissible(
                    // Funcionalidad UX: Eliminación gestual (swipe-to-delete) con persistencia en SQLite.
                    onDismissed: (_) => prov.eliminarNotificacion(n.id!),
                    child: Card(
                      // UI Semántica: El color de fondo y el ícono reaccionan al tipo de alerta.
                      color: _obtenerColorPorGravedad(n),
                      child: ListTile(
                        leading: Icon(_obtenerIcono(n)),
                        title: Text(n.titulo),
                        subtitle: Text('${n.cuerpo}\n${_formatFecha(n.fecha)}'),
                        onTap: () => _procesarNavegacion(n),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _procesarNavegacion(Notificacion n) {
    /* Lógica de ruteo inteligente:
       - Si es contingencia ambiental -> Redirige al Home (Dashboard general).
       - Si es alerta vehicular -> Navega al detalle específico del vehículo afectado. */
  }
}
