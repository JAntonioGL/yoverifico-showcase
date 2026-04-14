// lib/screens/faq/holograma_00.sample.dart

/**
 * Holograma00FaqScreen explica los beneficios y requisitos para autos nuevos.
 * Implementa navegación segura a listas oficiales de cumplimiento ambiental.
 */
class Holograma00FaqScreen extends StatefulWidget {
  const Holograma00FaqScreen({super.key});

  @override
  State<Holograma00FaqScreen> createState() => _Holograma00FaqScreenState();
}

class _Holograma00FaqScreenState extends State<Holograma00FaqScreen> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Stack(
        children: [
          // Contenido Educativo: Usa TituloAnimado y CuerpoTextoAnimado
          _buildScrollingContent(),

          // Footer Fijo: Botones de acción rápida
          Positioned(
            bottom: 0,
            child:
                _buildFooterActions(), // Incluye botón para abrir navegador interno y Locatel
          ),
        ],
      ),
    );
  }

  void _abrirListaOficial() {
    // Implementa el flujo de negocio: Prechequeo -> Anuncio -> Navegador Interno.
    AdNavigationService.navegarConAnuncio(
      context: context,
      onNext: () => Navigator.pushNamed(context, '/navegador/navegador'),
    );
  }
}
