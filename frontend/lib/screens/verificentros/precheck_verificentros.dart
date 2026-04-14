// lib/screens/verificentros/precheck_verificentros.sample.dart

/**
 * PrecheckVerificentrosScreen funciona como una pasarela de acceso.
 * Implementa el 'Peaje de Anuncio' antes de permitir el uso de mapas.
 */
class PrecheckVerificentrosScreen extends StatefulWidget {
  const PrecheckVerificentrosScreen({super.key});

  @override
  State<PrecheckVerificentrosScreen> createState() =>
      _PrecheckVerificentrosScreenState();
}

class _PrecheckVerificentrosScreenState
    extends State<PrecheckVerificentrosScreen> {
  bool _procesandoNavegacion = false;

  /// Orquestador del acceso al mapa protegido por anuncio.
  void _irAlMapa() {
    setState(() => _procesandoNavegacion = true);

    // Llama al servicio de navegación con anuncio (Intersticial).
    AdNavigationService.navegarConAnuncio(
      context: context,
      onNext: () {
        // Redirige al mapa de Google una vez cerrado el anuncio.
        Navigator.pushNamed(context, '/verificentros/mapa').then((_) {
          if (mounted) setState(() => _procesandoNavegacion = false);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          const TituloAnimado(text: 'Mapa de Verificentros'),

          // Animación Lottie temática de geolocalización.
          Lottie.asset('assets/animations/waving_hand_animation.json'),

          // Texto informativo: Segmentación por disponibilidad (CDMX).
          const CuerpoTextoAnimado(
            text:
                'El mapa interactivo se encuentra disponible únicamente para la CDMX por ahora.',
          ),

          // Acción: Botón con bloqueo visual y gestión de carga.
          BotonPrincipal(
            texto: _procesandoNavegacion ? 'Cargando...' : 'Ver mapa CDMX',
            onPressed: _procesandoNavegacion ? null : _irAlMapa,
          ),
        ],
      ),
    );
  }
}
