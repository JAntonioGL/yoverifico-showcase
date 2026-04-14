// lib/screens/verificacion/5_verificacion_confirmacion_screen.sample.dart

/**
 * Pantalla: Confirmación y Persistencia de Verificación (Paso 5)
 * Propósito: Resumen final de datos y ejecución de la actualización en el servidor.
 * Integra anuncios recompensados para desbloquear la acción y analítica de conversión.
 */
class VerificacionConfirmacionScreen extends StatefulWidget {
  final VehiculoRegistrado vehiculo;
  final String holograma;
  final DateTime? fechaVerificacion;
  final DateTime fechaLimite;

  const VerificacionConfirmacionScreen({
    super.key,
    required this.vehiculo,
    required this.holograma,
    required this.fechaLimite,
    this.fechaVerificacion,
  });

  @override
  State<VerificacionConfirmacionScreen> createState() =>
      _VerificacionConfirmacionScreenState();
}

class _VerificacionConfirmacionScreenState
    extends State<VerificacionConfirmacionScreen> {
  bool _procesando = false;

  /// Orquestador de la persistencia final.
  Future<void> _onConfirmarPressed() async {
    /* 1. Preparación del Payload: Holograma, fecha de verificación y límite.
       2. Flujo de Ejecución (FlujoAnuncioHelper):
          - Prechequeo en el servidor para generar folio.
          - Visualización de Rewarded Ad (Anuncio Recompensado).
          - Ejecución de la acción validando el SSV (Server-Side Verification).
       3. Post-procesamiento:
          - Envío de evento 'yoverifico_update_verif' a Facebook App Events.
          - Refresco de la flota y notificaciones locales.
          - Navegación atómica al Home. */
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          const TituloAnimado(text: 'Confirma los datos'),

          // Visualización del Resumen: Muestra de forma clara los datos capturados.
          _buildResumenCard(),

          // Tarjetas de Fecha: Comparativa visual entre la verificación realizada
          // y la nueva vigencia legal establecida.
          _buildFechasPreview(),

          // Acción Final: Botón con gestión de estado de carga y bloqueo.
          BotonPrincipal(
            texto: _procesando ? 'PROCESANDO...' : 'GUARDAR CAMBIOS',
            onPressed: _procesando ? null : _onConfirmarPressed,
          ),
        ],
      ),
    );
  }
}
