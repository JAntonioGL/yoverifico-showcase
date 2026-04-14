// lib/screens/navegador/navegador.sample.dart

/**
 * NavegadorScreen es un visor web avanzado con integración de datos del vehículo.
 * Implementa auto-copiado de placa y banners de asistencia técnica.
 */
class NavegadorScreen extends StatefulWidget {
  final String flowContext; // Determina el mapa de URLs oficiales a usar.
  final String? numeroPlaca; // Placa a inyectar en el portapapeles.

  const NavegadorScreen({
    super.key,
    required this.flowContext,
    this.numeroPlaca,
  });

  @override
  State<NavegadorScreen> createState() => _NavegadorScreenState();
}

class _NavegadorScreenState extends State<NavegadorScreen> {
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    // Automatización: Copia la placa al portapapeles al iniciar para facilitar el llenado de formularios.
    _copiarPlaca(widget.numeroPlaca, auto: true);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          // Banner de soporte para abrir en navegador externo si la carga falla.
          _buildHelpBanner(),

          // Navegador Web integrado con barra de progreso.
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
              onProgressChanged: (ctrl, p) =>
                  setState(() => _progreso = p / 100),
            ),
          ),

          // Footer Banner: Muestra los datos del vehículo seleccionado (Placa/Marca)
          // y permite re-copiar la placa con un toque.
          if (_placa != null) _buildBottomBanner(),
        ],
      ),
    );
  }
}
