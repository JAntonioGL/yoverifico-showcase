// lib/screens/registro/registro1_seleccion.sample.dart

/**
 * Registro1Seleccion ofrece las opciones de alta en la plataforma.
 * Prioriza el registro social (Google) por sobre el flujo manual.
 */
class Registro1Seleccion extends StatefulWidget {
  const Registro1Seleccion({super.key});

  @override
  State<Registro1Seleccion> createState() => _Registro1SeleccionState();
}

class _Registro1SeleccionState extends State<Registro1Seleccion> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Refuerzo visual mediante Lottie (welcome.json).
            Lottie.asset('assets/animations/welcome.json'),

            const TituloAnimado(text: '¡Hola! Te damos la bienvenida 👋'),

            // Propuesta de valor: Lista de beneficios con iconos.
            _BenefitRow(
              icon: Icons.check_circle_outline,
              text: 'Control total de verificaciones',
            ),

            // CTA Principal: Registro con Google (Botón sólido).
            BotonPersonalizado(
              texto: 'Registrarme con Google',
              onPressed: _iniciarGoogleRegistro,
            ),

            // CTA Secundario: Registro con correo (Botón outlined).
            BotonPersonalizado(
              texto: 'Crear cuenta con correo',
              esOutlined: true,
              onPressed: () => _navegarPaso2(),
            ),
          ],
        ),
      ),
    );
  }
}
