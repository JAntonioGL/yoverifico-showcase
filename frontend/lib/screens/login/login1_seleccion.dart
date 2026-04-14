// lib/screens/login/login1_seleccion.sample.dart

/**
 * Login1Seleccion ofrece al usuario las vías de acceso a la plataforma.
 * Prioriza la UX mediante animaciones escalonadas y login social.
 */
class Login1Seleccion extends StatefulWidget {
  const Login1Seleccion({super.key});

  @override
  State<Login1Seleccion> createState() => _Login1SeleccionState();
}

class _Login1SeleccionState extends State<Login1Seleccion> {
  bool _cargando = false;

  /// Inicia el flujo de Google Sign-In.
  Future<void> _iniciarGoogle() async {
    /* 1. Registra la intención de autenticación en SharedPreferences.
       2. Dispara el flujo nativo de Google authenticate().
       3. El manejo de la respuesta se delega al listener global en main.dart. */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Título de bienvenida con TituloAnimado (Delay: 120ms)
            const TituloAnimado(text: 'Que gusto verte de nuevo! 🎉'),

            // Refuerzo visual mediante Lottie (welcome_login.json)
            Lottie.asset('assets/animations/welcome_login.json'),

            // Botón Sólido (Prioridad): Acceso por correo.
            BotonPersonalizado(
              texto: 'Iniciar con correo',
              esOutlined: false,
              onPressed: () => Navigator.pushNamed(context, '/login/correo'),
            ),

            // Botón Outlined (Secundario): Acceso con Google.
            BotonPersonalizado(
              texto: 'Google',
              esOutlined: true,
              icono: const Icon(Icons.g_mobiledata),
              onPressed: _iniciarGoogle,
            ),
          ],
        ),
      ),
    );
  }
}
