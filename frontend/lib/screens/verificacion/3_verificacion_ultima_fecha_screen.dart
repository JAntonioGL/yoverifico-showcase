// lib/screens/verificacion/3_verificacion_ultima_fecha_screen.dart

/**
 * Pantalla: Captura de Fecha (Paso 3)
 * Propósito: Registrar la fecha exacta de la última verificación.
 * Utiliza selectores personalizados para minimizar errores de formato.
 */
class VerificacionUltimaFechaScreen extends StatefulWidget {
  final VehiculoRegistrado vehiculo;
  final String holograma;
  final TipoBoleta tipoBoleta;

  const VerificacionUltimaFechaScreen({
    super.key,
    required this.vehiculo,
    required this.holograma,
    required this.tipoBoleta,
  });

  @override
  State<VerificacionUltimaFechaScreen> createState() =>
      _VerificacionUltimaFechaScreenState();
}

class _VerificacionUltimaFechaScreenState
    extends State<VerificacionUltimaFechaScreen> {
  int? anioVerificacion, mesVerificacion, diaVerificacion;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Fecha de Verificación',
      child: Column(
        children: [
          // Contexto visual del auto seleccionado
          VehiculoHeaderChip(vehiculo: widget.vehiculo, center: true),

          const TituloAnimado(text: '¿Cuándo verificaste?'),

          // Guía Visual Dinámica: Resalta el área de la fecha en la boleta
          // digital según el formato estatal (CDMX o EdoMex).
          BoletaAnimada(
            tipo: widget.tipoBoleta == TipoBoleta.cdmx
                ? TipoAnimacionBoleta.fechaCdmx
                : TipoAnimacionBoleta.fechaEdomex,
          ),

          // Controles de Selección de Fecha:
          // Implementa dropdowns para Año, Mes y Día con validación de existencia.
          Row(
            children: [
              _buildDatePicker(
                'Año',
                _aniosDisponibles,
                anioVerificacion,
                (v) => setState(() => anioVerificacion = v),
              ),
              _buildDatePicker(
                'Mes',
                _mesesDisponibles,
                mesVerificacion,
                (v) => setState(() => mesVerificacion = v),
              ),
              _buildDatePicker(
                'Día',
                _diasDisponibles,
                diaVerificacion,
                (v) => setState(() => diaVerificacion = v),
              ),
            ],
          ),

          // Acción Principal: Solo se habilita cuando la fecha es completa y válida.
          BotonPrincipal(
            texto: 'GUARDAR FECHA',
            onPressed: _esFechaValida ? _guardar : null,
          ),

          // Lógica de Negocio: Permite omitir si la boleta es ilegible (Solo CDMX/Edomex).
          if (_puedeOmitir) _buildBotonOmitir(),
        ],
      ),
    );
  }

  void _guardar() {
    // Orquesta la persistencia final de la verificación en el backend.
    /* ... lógica de envío al API ... */
  }
}
