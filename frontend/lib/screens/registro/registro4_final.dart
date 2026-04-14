// lib/screens/registro/registro4_final.sample.dart

/**
 * Registro4Final confirma el éxito del proceso y ofrece el siguiente paso lógico.
 * Implementa sanitización de nombres para una bienvenida personalizada.
 */
class Registro4Final extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<UsuarioProvider>().usuario;
    final nombre = _primerNombre(_sanitizeNombre(usuario?.nombre));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Lottie.asset('assets/animations/welcome_login.json'),

            TituloAnimado(text: '¡Hola! Es un gusto, $nombre! 🎉'),

            // Call to Action Principal: Integración con el flujo de flota.
            BotonPersonalizado(
              texto: 'Agregar mi primer vehículo',
              onPressed: () =>
                  Navigator.pushNamed(context, '/vehiculo/agregar/intro'),
            ),

            BotonPersonalizado(
              texto: 'Ir al inicio',
              esOutlined: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
