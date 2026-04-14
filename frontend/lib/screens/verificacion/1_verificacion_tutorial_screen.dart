// lib/screens/verificacion/1_verificacion_tutorial_screen.dart

/**
 * Pantalla: Tutorial de Verificación (Paso 1)
 * Objetivo: Identificar el tipo de boleta/documento que el usuario posee.
 */
class VerificacionTutorialScreen extends StatefulWidget {
  final VehiculoRegistrado vehiculo;

  const VerificacionTutorialScreen({super.key, required this.vehiculo});

  @override
  State<VerificacionTutorialScreen> createState() =>
      _VerificacionTutorialScreenState();
}

class _VerificacionTutorialScreenState
    extends State<VerificacionTutorialScreen> {
  late TipoBoleta _tipoBoletaSeleccionado;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          // Contexto: Chip que muestra marca/modelo del auto actual
          VehiculoHeaderChip(vehiculo: widget.vehiculo),

          const TituloAnimado(text: '¿Qué documento tienes?'),

          // Selector de Tipo de Boleta: Cambia dinámicamente según el estado (CDMX/EDOMEX/etc)
          Expanded(
            child: ListView(
              children: [
                _OptionCard(
                  title: 'Verificación Normal',
                  subtitle:
                      'Tengo la boleta de mi última verificación aprobada.',
                  selected: _tipoBoletaSeleccionado == TipoBoleta.normal,
                  onTap: () => setState(
                    () => _tipoBoletaSeleccionado = TipoBoleta.normal,
                  ),
                ),
                _OptionCard(
                  title: 'Pago de Multa',
                  subtitle:
                      'Tengo un recibo de pago por verificación extemporánea.',
                  selected: _tipoBoletaSeleccionado == TipoBoleta.multa,
                  onTap: () => setState(
                    () => _tipoBoletaSeleccionado = TipoBoleta.multa,
                  ),
                ),

                // Banner Informativo: Ayuda al usuario con casos especiales (Exentos/Holograma 00)
                if (_esMegalopolis) _buildExclusionBanner(),
              ],
            ),
          ),

          // Acción: Navega al Paso 2 enviando el vehículo y el tipo de flujo elegido
          BotonPrincipal(
            texto: 'CONTINUAR',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/verificacion/paso2',
                arguments: {
                  'vehiculo': widget.vehiculo,
                  'tipo': _tipoBoletaSeleccionado,
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
