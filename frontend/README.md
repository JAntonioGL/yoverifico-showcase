# 🚗 YoVerifico - Flutter Frontend

**YoVerifico** es una solución móvil integral diseñada para automatizar el control vehicular, la gestión de verificaciones y el cumplimiento legal automotriz. Este repositorio contiene el frontend desarrollado en **Flutter**, enfocado en ofrecer una experiencia de usuario (UX) fluida, segura y altamente reactiva.

## 📸 Galería del Proyecto
A continuación, se presentan capturas que ilustran el flujo integral de la aplicación, desde el acceso seguro hasta la gestión operativa detallada.

| | | | |
| :---: | :---: | :---: | :---: |
| ![Captura 1](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/1.jpeg) | ![Captura 2](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/2.jpeg)  | ![Captura 3](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/3.jpeg)  | ![Captura 4](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/4.jpeg)  |
| ![Captura 5](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/5.jpeg)  | ![Captura 6](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/6.jpeg)  | ![Captura 7](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/7.jpeg)  | ![Captura 8](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/screenshots/8.jpeg) |

---
## 🏗️ Arquitectura del Software

La aplicación utiliza un patrón de arquitectura desacoplada para garantizar escalabilidad y mantenibilidad. Aunque actualmente está optimizada para **Android**, la base de código está preparada para un despliegue inmediato en **iOS**.

### 🛠️ Capas del Proyecto

#### 🎨 1. Widgets & Screens (Capa de UI)
Basada en un enfoque de **UI Componible**.
* **Screens:** Flujos complejos como el **Wizard de Registro** (5 pasos) y el **Tutorial de Actualización de Verificación**.
* **Widgets:** Componentes reutilizables personalizados como `VehiculoIdCard`, `BotonPersonalizado` y las **Boletas Animadas** que guían al usuario visualmente.

#### 🔄 2. Providers (Gestión de Estado)
Utilizamos **Provider** para una gestión de estado reactiva y eficiente:
* **UsuarioProvider:** Hidratación global del perfil y nivel de plan.
* **VehiculoProvider:** Actúa como un **buffer temporal** para recolectar datos durante el flujo de registro antes de la persistencia.
* **ContingenciaProvider:** Escucha cambios en tiempo real del API para actualizar banners de alerta en el Dashboard.

#### 📡 3. Services (Capa de Datos)
Encapsulan la lógica de comunicación externa:
* **AuthService:** Orquestador de identidad (Google Sign-In, Login nativo y gestión de JWT).
* **VehiculoService:** Consumo de microservicios para la gestión CRUD de la flota.
* **AdNavigationService:** Implementación estratégica de monetización con anuncios recompensados.

#### 📦 4. Models (Capa de Dominio)
Modelos de datos fuertemente tipados para garantizar la integridad de la información, transformando respuestas JSON en objetos de negocio como `VehiculoRegistrado` o `LineaVehiculo`.

---

## 🔐 Seguridad e Identidad

El sistema de acceso implementa múltiples capas de protección:
* **Social Auth:** Registro e inicio de sesión con **Google** mediante OAuth 2.0.
* **Email Auth:** Flujo tradicional con hashing de contraseñas.
* **Verificación OTP:** Sistema de contraseñas de un solo uso para validación de correos electrónicos, asegurando cuentas reales.
* **Server-Side Verification (SSV):** Las acciones críticas están protegidas por anuncios que requieren validación desde el backend antes de ser procesadas.

---

## ⚙️ Configuración y Entorno

La aplicación utiliza un archivo de configuración centralizado (`lib/config.dart`) para gestionar variables de entorno, facilitando la transición entre ambientes de Desarrollo, Staging y Producción:

```dart
// Ejemplo de gestión de variables de entorno
const String backendBaseUrl = '[https://api.yoverifico.mx](https://api.yoverifico.mx)';
const String APP_TRACK = 'prod';