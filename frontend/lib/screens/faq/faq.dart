// lib/screens/faq/faq.sample.dart

/**
 * FaqScreen centraliza las dudas comunes del usuario.
 * Utiliza Markdown para el formateo rico de respuestas y animaciones Lottie.
 */
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  // Lista de items con soporte para Markdown y estado de apertura.
  late final List<_FaqItem> _items;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          // Iconografía animada mediante Lottie para mejorar el engagement
          Lottie.asset('assets/animations/faq.json'),

          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                // _FaqTile: Widget personalizado con AnimatedCrossFade para la respuesta
                // y RotationTransition para el ícono de expansión.
                return _FaqTile(
                  item: _items[index],
                  onToggle: () => _toggle(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
