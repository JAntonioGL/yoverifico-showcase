# 📱 Capa de Presentación (Screens)

Esta carpeta contiene la arquitectura de vistas de la aplicación **YoVerifico**. Las pantallas están diseñadas siguiendo un enfoque de **UI Reactiva**, delegando la lógica pesada a los Providers y Services, y enfocándose en la experiencia de usuario (UX) mediante animaciones escalonadas y componentes adaptativos.

## 🏗️ Estructura del Módulo

### 🚪 Autenticación y Acceso
* **Welcome (`welcome_screen.dart`):** Punto de entrada principal con diseño minimalista y navegación atómica hacia los flujos de login y registro.
* **Login Flow (`login1_seleccion.dart`, `login2_correo.dart`):** Sistema de acceso dual (Social/Google y Tradicional). Implementa **Lock UI** para prevenir interacciones durante la hidratación de la sesión.
* **Registro Flow (`registro1...4`):** Wizard de 4 pasos que integra validación de correo (OTP), cumplimiento legal obligatorio y una fase de onboarding personalizada.
* **Recuperación (`recuperar1...3`):** Flujo de seguridad para restablecimiento de credenciales con validación de complejidad de contraseñas y gestión de tickets de un solo uso.

### 🚗 Gestión de Flota (Wizard de Registro)
Implementa un patrón de **Buffer Temporal** mediante `VehiculoProvider` para recolectar datos antes de la persistencia final.
* **Paso 1 (Marca):** Buscador predictivo (Autocomplete) sobre catálogos locales.
* **Paso 2 (Placa):** Validación de duplicados y segmentación por entidad federativa.
* **Paso 3 (Color):** Selector cromático con conversión dinámica de Hex a UI.
* **Paso 4 (Identidad):** Personalización con previsualización en tiempo real.
* **Paso 5 (Confirmación):** Punto de persistencia que integra **Rewarded Ads (SSV)** y analítica de eventos (Facebook SDK).

### 🛠️ Gestión Operativa (Detalle y Verificación)
* **Home / Mis Vehículos (`vehiculos_usuario_screen.dart`):** Dashboard reactivo con motor de búsqueda local y filtrado inteligente.
* **Detalle del Vehículo (`vehiculo_detalle_screen.dart`):** Centro de control individual que calcula en tiempo real restricciones de circulación y estatus de verificación.
* **Tutorial de Actualización (`verificacion1...6`):** Asistente educativo con **Boletas Animadas** que guían al usuario según el formato de su estado (CDMX/Edomex) para actualizar sus periodos legales.

### 🌐 Utilidades y Soporte
* **Navegador Interno (`navegador.dart`):** Visor web inteligente con inyección de datos (auto-copiado de placas) para agilizar trámites en portales oficiales.
* **Mapa de Verificentros (`verificentros_map_page.dart`):** Integración con Google Maps SDK, utilizando algoritmos de proximidad (Haversine) para localizar centros cercanos.
* **Tickets de Soporte (`levantar_tocket.dart`):** Sistema de reportes con compresión de imágenes en el cliente (Edge Compression) y priorización por plan de usuario.
* **Centro de Notificaciones (`notificaciones_screen.dart`):** Bandeja de entrada con gestión de prioridades (Contingencias > Vencimientos) y control de permisos nativos.

## 🛠️ Tecnologías y Patrones Aplicados

* **Navegación Atómica:** Uso de `pushNamedAndRemoveUntil` para limpiar el stack en procesos críticos, garantizando que el usuario no pueda regresar a flujos ya completados (como el registro exitoso).
* **UI Educativa:** Integración de la librería **Lottie** para animaciones vectoriales que guían al usuario en procesos complejos (como identificar datos en una boleta física).
* **Monetización Integrada:** Implementación de `FlujoAnuncioHelper` para proteger acciones de escritura mediante anuncios recompensados, validando la recompensa mediante **Server-Side Verification (SSV)**.
* **Diseño Transitivo:** Uso de `AnimatedSwitcher` y transiciones suaves para el cambio de estados internos dentro de una misma pantalla, reduciendo el parpadeo visual.
* **Arquitectura de Resiliencia:** Sistemas de reintentos escalonados (polling) en pantallas de confirmación para manejar la latencia entre el cliente, el backend y los servicios de anuncios.