// lib/screens/auth/acuerdos.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/textos_animado.dart';
import '../../widgets/botones.dart';

/**
 * Pantalla de Avisos y Políticas.
 * Implementa un flujo transitivo de lectura legal mediante estados.
 */
class AvisosScreen extends StatefulWidget {
  // Puede operar en modo 'verificador' (registro) o 'consulta' (ajustes).
  final AvisosMode mode;

  const AvisosScreen({super.key, this.mode = AvisosMode.verificador});

  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  // Control de pasos: 'terms' -> 'privacy'
  String _step = 'terms';
  bool _aceptaTerms = false;
  bool _aceptaPrivacy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con TituloAnimado para una entrada visual fluida.
            const TituloAnimado(text: 'Avisos y Políticas'),

            // Área de contenido con AnimatedSwitcher para transiciones suaves.
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _renderDocumentStep(), // Renderiza MarkdownBody según el estado
              ),
            ),

            // Sección de acciones reactiva al modo de operación.
            _buildActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _renderDocumentStep() {
    // Retorna un contenedor responsivo con scroll que muestra el
    // texto legal procesado desde Markdown.
  }

  Widget _buildActionArea() {
    // Si es modo verificador, muestra Checkboxes de validación.
    // Si es consulta, solo permite avanzar con el BotonPrincipal.
  }
}
