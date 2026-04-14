// lib/screens/navegador/seleccion_estado_navegador.sample.dart

/**
 * SeleccionEstadoNavegadorScreen permite configurar el contexto del trámite.
 * Gestiona la selección de la entidad federativa y el vehículo a consultar.
 */
class SeleccionEstadoNavegadorScreen extends StatefulWidget {
  // Define si el flujo es para 'citas', 'adeudos', 'multas' u 'otro'.
  final String flowContext;

  const SeleccionEstadoNavegadorScreen({super.key, this.flowContext = 'citas'});

  @override
  State<SeleccionEstadoNavegadorScreen> createState() =>
      _SeleccionEstadoNavegadorScreenState();
}

class _SeleccionEstadoNavegadorScreenState
    extends State<SeleccionEstadoNavegadorScreen> {
  int? _estadoSeleccionadoId; // IDs 1..7 de la Megalópolis
  VehiculoRegistrado? _vehiculoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          // Banner informativo sobre la procedencia de los datos oficiales.
          BannerTransparenciaEstado(flowContext: widget.flowContext),

          // Grid de estados con íconos personalizados y estados de selección.
          _EstadosView(onTapEstado: _toggleEstado),

          // Lista reactiva de vehículos filtrados por el estado seleccionado.
          if (_estadoSeleccionadoId != null)
            _VehiculosView(onSelectVehiculo: _selectVehiculo),

          // Botón de confirmación que orquesta el salto al siguiente paso (Precheck o Navegador).
          BotonPrincipal(onPressed: _confirmar),
        ],
      ),
    );
  }

  void _confirmar() {
    // Si es flujo de Citas, redirige a la pantalla de requisitos (Precheck).
    // Si es Adeudos/Otros, lanza navegación protegida con anuncio.
    AdNavigationService.navegarConAnuncio(
      context: context,
      onNext: () => Navigator.pushNamed(context, '/navegador/navegador'),
    );
  }
}
