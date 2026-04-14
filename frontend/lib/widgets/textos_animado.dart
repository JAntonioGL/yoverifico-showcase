import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

// ✅ Widget base que aplica una animación de entrada a cualquier widget hijo.
class AnimatedWidgetWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration animationDuration;

  const AnimatedWidgetWrapper({
    Key? key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.animationDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _AnimatedWidgetWrapperState createState() => _AnimatedWidgetWrapperState();
}

class _AnimatedWidgetWrapperState extends State<AnimatedWidgetWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Timer(widget.delay, () {
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
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// ✅ Widget para títulos con animación.
class TituloAnimado extends StatelessWidget {
  final String text;
  final Duration delay; // ✅ Ahora puedes pasarle un delay personalizado.

  const TituloAnimado({
    Key? key,
    required this.text,
    this.delay = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay, // ✅ Se usa el delay pasado en el constructor.
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF00796B),
          shadows: [
            Shadow(
              blurRadius: 2.0,
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(2.0, -2.0),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Widget para cuerpos de texto con animación.
class CuerpoTextoAnimado extends StatelessWidget {
  final String text;
  final Duration initialDelay; // ✅ Delay inicial.
  final Duration stepDelay; // ✅ Delay entre cada línea.

  const CuerpoTextoAnimado({
    Key? key,
    required this.text,
    this.initialDelay = const Duration(milliseconds: 400),
    this.stepDelay = const Duration(milliseconds: 150),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Separa el texto en líneas para animarlas individualmente.
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Alinea el texto a la izquierda.
      children: lines.asMap().entries.map((entry) {
        final int index = entry.key;
        final String line = entry.value;

        // Envuelve cada línea en un widget de animación con un retraso incremental.
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: AnimatedWidgetWrapper(
            delay: initialDelay + (stepDelay * index), // ✅ Retraso incremental.
            child: Text(
              line,
              textAlign: TextAlign.left,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.black.withOpacity(0.75),
                height: 1.4,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget para el botón principal de la aplicación.
class BotonPrincipal extends StatelessWidget {
  final String texto;
  // ✅ Se cambia a VoidCallback? para aceptar valores nulos.
  final VoidCallback? onPressed;
  final Duration delay;

  const BotonPrincipal({
    Key? key,
    required this.texto,
    required this.onPressed,
    this.delay = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay,
      child: ElevatedButton(
        // ✅ Ahora el ElevatedButton interno recibe el onPressed nulable.
        // Flutter se encarga de cambiar el estilo visual si es nulo.
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              Colors.grey.shade300, // Color cuando está deshabilitado
          disabledForegroundColor:
              Colors.grey.shade500, // Color del texto cuando está deshabilitado
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Widget para el botón secundario (ej. omitir, cancelar).
class BotonSecundario extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final Duration delay;

  const BotonSecundario({
    Key? key,
    required this.texto,
    required this.onPressed,
    this.delay = const Duration(milliseconds: 900),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay,
      child: TextButton(
        onPressed: onPressed,
        child: Text(texto, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
