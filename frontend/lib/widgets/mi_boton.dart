import 'package:flutter/material.dart';

class MiBoton extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final bool estaCargando; // <-- AÑADIMOS ESTO

  const MiBoton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.estaCargando = false, // <-- VALOR POR DEFECTO
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // Si está cargando, onPressed es null para deshabilitar el botón
      onPressed: estaCargando ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A6CFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Si está cargando, muestra un indicador, si no, muestra el texto
      child: estaCargando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(texto),
    );
  }
}
