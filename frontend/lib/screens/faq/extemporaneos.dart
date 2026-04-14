// lib/screens/faq/extemporaneos.sample.dart

/**
 * ExtemporaneosFaqScreen guía al usuario sobre la verificación vencida.
 * Incluye un simulador visual de boletas y calcomanías para facilitar el cotejo.
 */
class ExtemporaneosFaqScreen extends StatefulWidget {
  // Recibe contexto del vehículo y estado para personalizar la ayuda.
  final VehiculoRegistrado? vehiculo;
  final int? estadoId;

  const ExtemporaneosFaqScreen({super.key, this.estadoId, this.vehiculo});

  @override
  State<ExtemporaneosFaqScreen> createState() => _ExtemporaneosFaqScreenState();
}

class _ExtemporaneosFaqScreenState extends State<ExtemporaneosFaqScreen> {
  bool _ejemploAbierto = false; // Controla la expansión del simulador visual.
  bool _procesandoPago = false; // Bloqueo de UI durante la carga de anuncios.

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Extemporáneos',
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const TituloAnimado(text: '¿Verificación extemporánea? 😬'),

                  // Componente Interactivo: Muestra boletas animadas según el estado (CDMX/MEX)
                  _btnToggleEjemplo(),
                  if (_ejemploAbierto) ...[
                    _BoletaEjemplo(
                      calcoEstado: _abrevEjemplo,
                    ), // Widget con animaciones de fechas
                    _CalcomaniaPanel(
                      abrev: _abrevEjemplo,
                    ), // Imagen con InteractiveViewer (Zoom)
                  ],

                  // Sección informativa con Bullets y CuerpoTextoAnimado
                  _seccionConsecuenciasLegales(),
                ],
              ),
            ),
          ),

          // Barra inferior: Acceso directo al pago de multas oficial
          _buildActionFooter(), // Orquesta navegación mediante AdNavigationService
        ],
      ),
    );
  }
}
