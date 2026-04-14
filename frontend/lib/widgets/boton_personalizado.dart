import 'package:flutter/material.dart';

class BotonPersonalizado extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final Color? color;
  final bool estaCargando;
  final Widget? icono; // <-- AÑADIDO: Para el ícono
  final bool esOutlined; // <-- AÑADIDO: Para cambiar el estilo

  const BotonPersonalizado({
    super.key,
    required this.texto,
    required this.onPressed,
    this.color,
    this.estaCargando = false,
    this.icono, // <-- AÑADIDO
    this.esOutlined = false, // <-- AÑADIDO
  });

  @override
  Widget build(BuildContext context) {
    final botonColor = color ?? Theme.of(context).colorScheme.primary;

    // Contenido interno del botón
    final contenido = estaCargando
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 3),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icono != null) ...[
                icono!,
                const SizedBox(width: 8),
              ],
              Text(texto),
            ],
          );

    // Devuelve un OutlinedButton si esOutlined es true
    if (esOutlined) {
      return OutlinedButton(
        onPressed: estaCargando ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: botonColor,
          side: BorderSide(color: botonColor), // Borde del color principal
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: contenido,
      );
    }

    // Por defecto, devuelve un ElevatedButton
    return ElevatedButton(
      onPressed: estaCargando ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: botonColor,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: contenido,
    );
  }

  
}
