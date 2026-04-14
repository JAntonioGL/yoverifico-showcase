# 🎨 Capa de Componentes (Widgets)

Esta carpeta constituye el núcleo visual de **YoVerifico**. Se ha seguido una filosofía de diseño atómico y reactivo, desarrollando componentes especializados que responden dinámicamente tanto al estado del usuario como a la información técnica de los vehículos.

## 🌟 Componentes Destacados

### 1. Identidad Vehicular Adaptativa (`vehiculo_id_card.dart` & `_editable.dart`)
Es el componente más sofisticado de la interfaz, encargado de procesar estéticamente la identidad del automóvil:
* **Motor de Luminancia:** El widget analiza el color hexadecimal del vehículo mediante `computeLuminance()` para decidir si el entorno visual (sombras y halos) debe ser oscuro o claro, garantizando contraste y legibilidad sin importar la carrocería.
* **Efecto de Glow Dinámico:** Implementación de capas mediante `ImageFiltered` y `ImageFilter.blur` para generar un halo de luz adaptativo que realza la silueta del vehículo.
* **Arquitectura de Estado Dual:** El componente alterna fluidamente entre un modo de visualización limpia y un modo de edición *in-place* mediante callbacks desacoplados.

### 2. Animaciones Educativas (`boleta_animada.dart`)
Diseñado para mitigar la fricción del usuario al capturar datos de documentos oficiales (CDMX/Edomex):
* **Zoom Programático:** Utiliza un `AnimationController` para realizar acercamientos quirúrgicos hacia zonas específicas de la boleta de verificación (Holograma, fecha límite, folio).
* **Guías Visuales Sincronizadas:** Superpone recuadros y flechas animadas coordinadas con el zoom para instruir al usuario exactamente sobre qué datos ingresar.
* **Adaptabilidad de Ratio:** Implementación de `AspectRatio` para asegurar la integridad visual de las guías en cualquier relación de aspecto de pantalla.

### 3. Engine de Animación de Texto (`textos_animado.dart`)
Se implementó un lenguaje visual de "entrada suave" para toda la plataforma:
* **AnimatedWidgetWrapper:** Un HOC (Higher-Order Component) que envuelve cualquier elemento para aplicarle efectos coordinados de `FadeTransition` y `SlideTransition` con retrasos configurables.
* **Segmentación Secuencial:** Widgets como `CuerpoTextoAnimado` segmentan los párrafos en líneas individuales para animarlas en cascada, mejorando significativamente la retención visual y el flujo de lectura.

## 🏗️ Inventario de Componentes

| Widget | Responsabilidad Técnica | Estado |
| :--- | :--- | :--- |
| `app_drawer.dart` | Menú lateral con lógica de "Track" (Prod/Dev) y permisos de soporte basados en planes. | **Activo** |
| `main_layout.dart` | Scaffold base que centraliza la navegación y el *look & feel* global. | **Activo** |
| `bloqueo_progreso.dart` | Overlay de seguridad para gestionar estados de carga en procesos asíncronos críticos. | **Activo** |
| `banner_permiso_notificaciones.dart` | Detector proactivo de estado de permisos a nivel de sistema operativo. | **Activo** |
| `boton_con_anuncio.dart` | Integración de lógica de "Gating" para la ejecución de acciones tras visualización de Ads. | **Activo** |
| `botones_personalizados.dart` | Librería de botones con estilos y animaciones predefinidas (Verde, Blanco, Omitir). | **Activo** |

## 🛠️ Tecnologías y Patrones Aplicados
* **Custom Rendering:** Uso avanzado de `Stack`, `Transform.scale` y filtros de color para manipulación de activos gráficos en tiempo real.
* **Gestión de Sesión Visual:** Integración con `UsuarioProvider` para mostrar u ocultar opciones de soporte y planes premium según los *entitlements* del usuario.
* **UX Predictiva:** Implementación de diálogos de calificación y compartición basados en el historial de uso del usuario.

---

> **Nota:** Algunos componentes en esta carpeta se conservan como referencia histórica de la evolución de la UI/UX del proyecto, permitiendo observar la transición hacia un diseño más limpio y modular.