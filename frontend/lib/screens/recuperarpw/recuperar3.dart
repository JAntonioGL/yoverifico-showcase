// lib/screens/recuperar/recuperar3.sample.dart

/**
 * Recuperar3 confirma al usuario que su cuenta ha sido restablecida.
 */
class Recuperar3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono de éxito animado con colores institucionales.
          const Icon(
            Icons.verified_rounded,
            size: 88,
            color: Color(0xFF4CAF50),
          ),

          const TituloAnimado(text: '¡Contraseña actualizada!'),

          // Botón Principal: Redirige a Login y limpia todo el historial de navegación.
          BotonPersonalizado(
            texto: 'Ir a Iniciar sesión',
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (_) => false),
          ),
        ],
      ),
    );
  }
}
