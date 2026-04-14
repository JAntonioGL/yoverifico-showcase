// lib/screens/registro/registro2_correo.sample.dart

/**
 * Registro2Correo gestiona la captura del identificador del usuario.
 * Integra el flujo de cumplimiento legal (Avisos y Políticas).
 */
class Registro2Correo extends StatefulWidget {
  const Registro2Correo({super.key});

  @override
  State<Registro2Correo> createState() => _Registro2CorreoState();
}

class _Registro2CorreoState extends State<Registro2Correo> {
  Future<void> _continuar() async {
    /* 1. Validación sintáctica del correo.
       2. Verificación proactiva de existencia (AuthService.existeCorreo).
       3. Navegación obligatoria a /acuerdos en 'modo verificador'.
       4. Diálogo de confirmación visual mediante slider.
       5. Solicitud de código OTP al servidor y navegación al paso 3. */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TituloAnimado(text: '¡Estamos listos! 🚀'),

          // Captura de datos con bloqueo de UI durante carga.
          TextField(
            controller: _correoCtrl,
            decoration: InputDecoration(labelText: 'Tu correo electrónico'),
          ),

          BotonPersonalizado(
            texto: 'Continuar',
            estaCargando: _cargando,
            onPressed: _continuar,
          ),

          // Banner de Seguridad Informativo.
          _buildSecurityFooter(),
        ],
      ),
    );
  }
}
