import 'package:flutter/material.dart';
import 'package:yoverifico_app/widgets/textos_animado.dart';
import '../services/ad_navigation_service.dart';

class BotonConAnuncio extends StatefulWidget {
  final String texto;
  final VoidCallback onNavegacion; // La función que navega (Navigator.push...)

  const BotonConAnuncio({
    super.key,
    required this.texto,
    required this.onNavegacion,
  });

  @override
  State<BotonConAnuncio> createState() => _BotonConAnuncioState();
}

class _BotonConAnuncioState extends State<BotonConAnuncio> {
  bool _cargando = false;

  void _ejecutar() {
    if (_cargando) return; // Evita doble clic

    setState(() => _cargando = true);

    AdNavigationService.navegarConAnuncio(
      context: context,
      onNext: () async {
        // Ejecutamos la navegación que nos pasaron
        widget.onNavegacion();
        
        // Esperamos un poco para que dé tiempo a la transición de pantalla
        // y luego reseteamos el botón por si el usuario regresa atrás.
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() => _cargando = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aquí usamos TU diseño de botón existente
    return BotonPrincipal(
      texto: _cargando ? 'Cargando...' : widget.texto,
      onPressed: _cargando ? null : _ejecutar, // Si carga, pasamos null (gris)
    );
  }
}