// lib/screens/login/login2_correo.sample.dart

/**
 * Login2Correo gestiona la autenticación tradicional por correo/password.
 * Implementa un sistema de 'LockUi' para prevenir interacciones durante procesos asíncronos.
 */
class Login2Correo extends StatefulWidget {
  const Login2Correo({super.key});

  @override
  State<Login2Correo> createState() => _Login2CorreoState();
}

class _Login2CorreoState extends State<Login2Correo> {
  final _formKey = GlobalKey<FormState>();

  /// Orquestador del proceso de Login.
  Future<void> _loginCorreo() async {
    /* 1. Validación de formulario y bloqueo de UI global (LockUi.show).
       2. Preparación de estado (limpieza de providers previos).
       3. Obtención de FCM Token para notificaciones push.
       4. Petición al AuthService.loginEmail().
       5. establecerSesionCompleta(): Hidrata proveedores, descarga flota y 
          genera notificaciones preventivas locales.
       6. Navegación inteligente: Si la flota está vacía, redirige al asistente 
          de registro; si no, al Home. */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar con correo')),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Animación de seguridad (login.json)
                  Lottie.asset('assets/animations/login.json'),

                  // Inputs con validación y límites de caracteres (max: 64)
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),

                  // Botón con estado de carga integrado
                  BotonPersonalizado(
                    texto: 'Iniciar sesión',
                    estaCargando: _cargando,
                    onPressed: _loginCorreo,
                  ),
                ],
              ),
            ),
          ),

          // Footer de Transparencia: Informa sobre la protección de sesión activa.
          _buildSecurityFooter(),
        ],
      ),
    );
  }
}
