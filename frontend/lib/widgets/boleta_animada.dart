import 'package:flutter/material.dart';
import 'dart:async';

enum TipoAnimacionBoleta {
  fechaCapturaCdmx,
  fechaLimiteCdmx,
  hologramaCdmx,
  fechaCapturaEdomex,
  fechaLimiteEdomex,
  hologramaEdomex,
}

class BoletaAnimada extends StatefulWidget {
  final TipoAnimacionBoleta tipo;

  const BoletaAnimada({Key? key, required this.tipo}) : super(key: key);

  @override
  _BoletaAnimadaState createState() => _BoletaAnimadaState();
}

class _BoletaAnimadaState extends State<BoletaAnimada>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Alignment> _alignmentAnimation;
  late Animation<double> _highlightOpacityAnimation;

  Alignment _textAlignment = Alignment.center;
  Alignment _boxAlignment = Alignment.center;
  double _textRotation = 0.0;
  String _imagePath = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    Alignment endAlignment;
    double endScale;

    switch (widget.tipo) {
      case TipoAnimacionBoleta.fechaCapturaCdmx:
        _imagePath = 'assets/images/boleta_ejemplo_cdmx.jpg';
        endAlignment = const Alignment(-0.3, 0.60);
        endScale = 2.2;
        _textAlignment = const Alignment(0.0, -0.7);
        _boxAlignment = Alignment.center;
        _textRotation = -0.4;
        break;
      case TipoAnimacionBoleta.fechaLimiteCdmx:
        _imagePath = 'assets/images/boleta_ejemplo_cdmx.jpg';
        endAlignment = const Alignment(0.1, 1);
        endScale = 2.8;
        _textAlignment = const Alignment(0.0, -0.7);
        _boxAlignment = Alignment.center;
        _textRotation = 0.0;
        break;
      case TipoAnimacionBoleta.hologramaCdmx:
        _imagePath = 'assets/images/boleta_ejemplo_cdmx.jpg';
        endAlignment = const Alignment(1, -1);
        endScale = 3.5;
        _textAlignment = const Alignment(0.0, -0.9);
        _boxAlignment = Alignment.center;
        _textRotation = 0.0;
        break;
      case TipoAnimacionBoleta.fechaCapturaEdomex:
        _imagePath = 'assets/images/boleta_ejemplo_edomex.jpg';
        endAlignment = const Alignment(0.2, 0.70);
        endScale = 2.5;
        _textAlignment = const Alignment(0.0, -0.7);
        _boxAlignment = Alignment.center;
        _textRotation = 0.3;
        break;
      case TipoAnimacionBoleta.fechaLimiteEdomex:
        _imagePath = 'assets/images/boleta_ejemplo_edomex.jpg';
        endAlignment = const Alignment(-0.15, 1);
        endScale = 3.3;
        _textAlignment = const Alignment(0.0, -0.7);
        _boxAlignment = const Alignment(0.0, 0);
        _textRotation = -0.3;
        break;
      case TipoAnimacionBoleta.hologramaEdomex:
        _imagePath = 'assets/images/boleta_ejemplo_edomex.jpg';
        endAlignment = const Alignment(1, -1);
        endScale = 3.6;
        _textAlignment = const Alignment(0.0, -0.9);
        _boxAlignment = Alignment.center;
        _textRotation = 0.0;
        break;
    }

    _scaleAnimation = Tween<double>(begin: 1.0, end: endScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _alignmentAnimation =
        AlignmentTween(begin: Alignment.center, end: endAlignment).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _highlightOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Se crea una variable para decidir si se muestra el resaltado.
    final bool mostrarHighlight =
        widget.tipo != TipoAnimacionBoleta.hologramaCdmx &&
            widget.tipo != TipoAnimacionBoleta.hologramaEdomex;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: _alignmentAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                _imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text(
                        'Imagen no encontrada',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
            // ✅ El resaltado (flecha, texto y recuadro) ahora solo se muestra si no es un holograma.
            if (mostrarHighlight)
              FadeTransition(
                opacity: _highlightOpacityAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: _boxAlignment,
                      child: Container(
                        width: 300,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Align(
                      alignment: _textAlignment,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '¡Aquí!',
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 0, 0),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black),
                              ],
                            ),
                          ),
                          Transform.rotate(
                            angle: _textRotation,
                            child: const Icon(
                              Icons.arrow_downward,
                              color: Color.fromARGB(255, 255, 0, 0),
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
