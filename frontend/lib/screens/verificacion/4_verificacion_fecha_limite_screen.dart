// lib/screens/verificacion/4_verificacion_fecha_limite_screen.dart

/**
 * Pantalla: Fecha Límite de Verificación (Paso 4)
 * Propósito: Establecer la fecha de vencimiento legal del periodo actual.
 * Integra un motor de cálculo automático y un diálogo de ajuste manual.
 */
class VerificacionFechaLimiteScreen extends StatefulWidget {
  final DateTime? fechaVerificacion; // Fecha capturada en el Paso 3
  final VehiculoRegistrado vehiculo;
  final TipoBoleta tipoBoleta;
  final String holograma;

  const VerificacionFechaLimiteScreen({
    super.key,
    required this.vehiculo,
    required this.tipoBoleta,
    required this.holograma,
    this.fechaVerificacion,
  });

  @override
  State<VerificacionFechaLimiteScreen> createState() =>
      _VerificacionFechaLimiteScreenState();
}

class _VerificacionFechaLimiteScreenState
    extends State<VerificacionFechaLimiteScreen> {
  int? anioLimite, mesLimite, diaLimite;

  @override
  void initState() {
    super.initState();
    // Lógica Inicial: Si hay una fecha de verificación previa, se calcula
    // automáticamente la fecha límite tentativa usando VerificacionUtils.
    _calcularFechaInicial();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Fecha Límite',
      child: Column(
        children: [
          // Header con la identidad del vehículo
          VehiculoHeaderChip(vehiculo: widget.vehiculo, center: true),

          const TituloAnimado(text: 'Confirma tu fecha límite'),

          // Guía Visual Dinámica: Resalta el área de vigencia en la boleta
          // o certificado según el estado (CDMX/EdoMex).
          BoletaAnimada(
            tipo: widget.tipoBoleta == TipoBoleta.cdmx
                ? TipoAnimacionBoleta.vigenciaCdmx
                : TipoAnimacionBoleta.vigenciaEdomex,
          ),

          // Visualización y Edición de Fecha Límite
          _buildFechaSelector(),

          // Acción Principal: Persistencia final de los datos en el servidor.
          BotonPrincipal(
            texto: 'FINALIZAR Y GUARDAR',
            onPressed: _esFechaValida ? _finalizarRegistro : null,
          ),

          // Herramienta de Soporte: Diálogo para ajustar la fecha basado
          // específicamente en la calcomanía (Periodo 1 o 2).
          TextButton.icon(
            icon: const Icon(Icons.help_outline),
            label: const Text('Ajustar según mi calcomanía'),
            onPressed: _mostrarDialogoCalcomania,
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarRegistro() async {
    // 1. Construye el objeto final con Holograma y Fecha Límite.
    // 2. Ejecuta la actualización en el backend.
    // 3. Notifica al usuario y redirige al Home.
  }
}
