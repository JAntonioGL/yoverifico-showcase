// lib/screens/navegador/precheck_citas.sample.dart

/**
 * PrecheckCitasScreen lista los documentos mínimos para la verificación.
 * Funciona como un asistente previo para evitar trámites infructuosos.
 */
class PrecheckCitasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          const TituloAnimado(text: 'Antes de continuar'),

          // Refuerzo visual mediante Lottie (check.json)
          Lottie.asset('assets/animations/check.json'),

          // Lista de requisitos con animaciones escalonadas para facilitar la lectura.
          _ReqItem(text: 'Constancia del período anterior.'),
          _ReqItem(text: 'Tarjeta de circulación vigente.'),

          // Enlaces directos a FAQs relacionadas (Holograma 00, Extemporáneos).
          _buildFaqLinks(),

          // Acción final que lanza el navegador oficial.
          BotonPrincipal(texto: 'CONTINUAR', onPressed: _continuar),
        ],
      ),
    );
  }
}
