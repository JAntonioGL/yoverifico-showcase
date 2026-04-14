// lib/screens/recuperar/recuperar1.sample.dart

/**
 * Recuperar1 gestiona el inicio del flujo de restablecimiento.
 * Captura el correo y dispara la solicitud del código OTP al backend.
 */
class Recuperar1 extends StatefulWidget {
  const Recuperar1({super.key});

  @override
  State<Recuperar1> createState() => _Recuperar1State();
}

class _Recuperar1State extends State<Recuperar1> {
  final _correoCtrl = TextEditingController();

  Future<void> _continuar() async {
    /* 1. Validación sintáctica del correo.
       2. Persistencia temporal del correo en SharedPreferences.
       3. Disparo del OTP (requestPasswordOtp) al servicio de recuperación.
       4. Gestión de cooldown de 60 segundos para el reenvío.
       5. Navegación al paso 2. */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Animación Lottie temática de envío de correo.
          Lottie.asset('assets/animations/email.json'),

          const TituloAnimado(text: '¿Olvidaste tu contraseña? 😟'),

          // Input de correo con teclado especializado.
          TextField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
          ),

          BotonPersonalizado(texto: 'Continuar', onPressed: _continuar),

          // Banner de Seguridad: Informa sobre la protección activa de la sesión.
          _buildSecurityFooter(),
        ],
      ),
    );
  }
}
