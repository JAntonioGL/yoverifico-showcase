// Archivo: lib/widgets/botones_personalizados.dart

import 'package:flutter/material.dart';
import 'textos_animado.dart';

// ✅ Widget universal de botón principal con animación y estilo verde
class BotonAnimadoVerde extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed; // ✅ Ahora es opcional (puede ser nulo)
  final Duration delay;

  const BotonAnimadoVerde({
    super.key,
    required this.texto,
    this.onPressed, // ✅ Ya no es requerido
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors
              .grey.shade300, // ✅ Color de fondo para cuando está deshabilitado
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        onPressed: onPressed,
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ✅ Nuevo widget de botón secundario con animación y estilo blanco
class BotonAnimadoBlanco extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Duration delay;

  const BotonAnimadoBlanco({
    super.key,
    required this.texto,
    this.onPressed,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
          disabledForegroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(texto),
      ),
    );
  }
}

// ✅ Nuevo widget de botón para la opción de omitir con animación y estilo gris
class BotonAnimadoOmitir extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Duration delay;

  const BotonAnimadoOmitir({
    super.key,
    required this.texto,
    this.onPressed,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          texto,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class BotonAnimadoTransparente extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Duration delay;

  const BotonAnimadoTransparente({
    super.key,
    required this.texto,
    this.onPressed,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.blue, // o el color que uses para enlaces
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class BotonAnimadoLoginRegVerde extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Duration delay;

  const BotonAnimadoLoginRegVerde({
    super.key,
    required this.texto,
    this.onPressed,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return BotonAnimadoVerde(
      texto: texto,
      onPressed: onPressed,
      delay: delay,
    );
  }
}

class BotonAnimadoLoginRegBlanco extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Duration delay;

  const BotonAnimadoLoginRegBlanco({
    super.key,
    required this.texto,
    this.onPressed,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return BotonAnimadoBlanco(
      texto: texto,
      onPressed: onPressed,
      delay: delay,
    );
  }
}

class BotonAnimadoLoginRegTransparente extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Duration delay;

  const BotonAnimadoLoginRegTransparente({
    super.key,
    required this.texto,
    this.onPressed,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return BotonAnimadoTransparente(
      texto: texto,
      onPressed: onPressed,
      delay: delay,
    );
  }
}
