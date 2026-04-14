# 📦 Capa de Modelos de Datos (Models)

Esta carpeta contiene las definiciones de estructuras de datos inmutables de la aplicación. Los modelos están diseñados para desacoplar la respuesta del backend de la lógica de negocio en Flutter, implementando patrones de **Serialización (JSON)** y **Fábricas de Datos** robustas.

## 🏗️ Modelos Principales

### 1. Gestión de Identidad y Sesión
* **Usuario (`usuario.dart`):** Modelo base de identidad que encapsula los datos esenciales del perfil (ID, Nombre, Correo).
* **AuthResponse (`auth_response.dart`):** Orquestador del flujo de entrada que integra el token JWT, el perfil de usuario y sus derechos de acceso.
* **Entitlements (`entitlements.dart`):** Motor de reglas de negocio que define los límites de la suscripción, cuotas de vehículos y visualización de anuncios.

### 2. Gestión Vehicular y Alertas
* **VehiculoRegistrado (`vehiculo_registrado.dart`):** El modelo más complejo de la capa; almacena la identidad técnica del auto y las fechas críticas calculadas por el motor de verificación.
* **Notificacion (`notificacion.dart`):** Estructura híbrida para alertas locales y remotas (FCM), con soporte para desduplicación de mensajes y niveles de severidad.

### 3. Monetización y Pagos
* **PlanV2 (`planes_v2.dart`):** Define el catálogo de suscripciones, mapeando beneficios comerciales con los SKUs técnicos de las tiendas de aplicaciones.
* **PlayOption (`play_option.dart`):** Traductor de ofertas de Google Play Billing, manejando la conversión de periodos ISO8601 y precios regionales dinámicos.

### 4. Infraestructura
* **VersionPolicy (`version.dart`):** Encapsula la política de cumplimiento de versiones, permitiendo a la app decidir entre actualizaciones obligatorias (Hard) o sugeridas (Soft).

---

## 🛠️ Estándares Aplicados

* **Inmutabilidad:** Uso de campos `final` y constructores `const` para garantizar que los datos no muten inesperadamente durante el ciclo de vida de los widgets.
* **Parseo Defensivo:** Implementación de métodos `fromJson` con lógica de seguridad contra valores nulos o tipos de datos inconsistentes provenientes del API.
* **Separación de Preocupaciones:** Cada modelo es responsable únicamente de la representación de sus datos, delegando la lógica de negocio pesada a los **Providers** y **Services**.
* **Persistencia Local:** Todos los modelos incluyen métodos `toJson` compatibles con `SharedPreferences` y `SQLite` para el soporte de modo offline.