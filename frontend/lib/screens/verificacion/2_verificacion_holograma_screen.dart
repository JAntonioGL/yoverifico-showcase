// lib/screens/verificacion/2_verificacion_holograma_screen.dart

/**
 * Pantalla: Selección de Holograma (Paso 2)
 * Propósito: Capturar el holograma (00, 0, 1, 2) apoyándose en guías visuales
 * animadas que indican dónde encontrar el dato en el documento físico.
 */
class VerificacionHologramaScreen extends StatefulWidget {
  final VehiculoRegistrado vehiculo;
  final TipoBoleta
  tipoBoleta; // Determina si se muestra el ejemplo de CDMX o EdoMex

  const VerificacionHologramaScreen({
    super.key,
    required this.vehiculo,
    required this.tipoBoleta,
  });

  @override
  State<VerificacionHologramaScreen> createState() =>
      _VerificacionHologramaScreenState();
}

class _VerificacionHologramaScreenState
    extends State<VerificacionHologramaScreen> {
  String? _hologramaSeleccionado;
  final List<String> _hologramasDisponibles = ['00', '0', '1', '2'];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Tipo de Holograma',
      child: Column(
        children: [
          // Header persistente con la identidad del auto actual
          VehiculoHeaderChip(vehiculo: widget.vehiculo, center: true),

          const TituloAnimado(text: 'Selecciona el Holograma'),

          // Guía Visual Dinámica: Resalta el área del holograma en una boleta
          // digital según el origen seleccionado en el Paso 1.
          BoletaAnimada(
            tipo: widget.tipoBoleta == TipoBoleta.cdmx
                ? TipoAnimacionBoleta.hologramaCdmx
                : TipoAnimacionBoleta.hologramaEdomex,
          ),

          // Selector con validación de estado:
          // Solo permite avanzar si el usuario ha realizado una selección.
          _buildHologramaDropdown(),

          BotonPrincipal(
            texto: 'CONTINUAR',
            onPressed: _hologramaSeleccionado != null ? _continuar : null,
          ),
        ],
      ),
    );
  }

  void _continuar() {
    // Propaga el estado al Paso 3: Captura de Fecha de Verificación
    Navigator.pushNamed(
      context,
      '/verificacion/ultima_fecha',
      arguments: {
        'vehiculo': widget.vehiculo,
        'holograma': _hologramaSeleccionado,
        'tipoBoleta': widget.tipoBoleta,
      },
    );
  }
}
