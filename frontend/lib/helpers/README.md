# 🛠️ Capa de Asistentes (Helpers)

Esta carpeta contiene la lógica de soporte y utilidades transversales que facilitan la interacción entre la interfaz de usuario (UI), el almacenamiento local y los servicios externos. Los componentes aquí alojados están diseñados para ser modulares y reutilizables en toda la plataforma.

## 🚀 Componentes Principales

### 1. Orquestador de Anuncios y Acciones (`flujo_anuncio_helper.dart`)
Gestiona la lógica compleja de monetización y validación de recompensas para el modelo *Freemium*:
* **Gating de Acciones:** Intercepta acciones críticas (ej. agregar vehículo) para verificar si requieren la visualización de un anuncio recompensado.
* **Server-Side Verification (SSV):** Sincroniza el `folio` de la transacción con los servidores de Google AdMob para garantizar que la recompensa sea legítima antes de proceder.
* **Lógica de Reintentos:** Implementa un sistema de reintentos exponenciales para validar la confirmación del backend tras la visualización del anuncio, mejorando la experiencia del usuario en redes inestables.

### 2. Gestión de Persistencia de Notificaciones (`notificaciones_db_helper.dart`)
Interfaz de bajo nivel para la base de datos local **SQLite**:
* **Deduplicación de Mensajes:** Implementa lógica para evitar registros duplicados mediante `dedup_key` y filtros por fecha.
* **Estructura Evolutiva:** Maneja migraciones de base de datos (versioning) para añadir campos de metadatos (severidad, fuente, JSON extra) sin comprometer la integridad de los datos existentes.
* **Consultas Optimizadas:** Provee métodos específicos para conteo de no leídos y limpieza selectiva por vehículo.

### 3. Asistente de Calificación y Engagement (`calificacion_helper.dart`)
Controla el flujo de retroalimentación de los usuarios para mejorar el posicionamiento en tiendas:
* **Filtro de Relevancia:** Decide el momento óptimo para solicitar una calificación basado en acciones exitosas del usuario.
* **Control de Frecuencia:** Implementa una lógica de "enfriamiento" (cooldown) para no saturar al usuario, respetando un intervalo mínimo de días entre prompts.

### 4. Gestor de Actualizaciones UI (`version_ui_helper.dart`)
Maneja la lógica visual del ciclo de vida de la aplicación:
* **Decisiones de Cumplimiento:** Traduce las políticas del backend (`soft`, `hard`, `mismatch`) en diálogos interactivos.
* **Bloqueo Crítico:** Implementa diálogos no-cerrables para actualizaciones obligatorias, asegurando que el usuario opere siempre en versiones compatibles y seguras.

---

## 🏗️ Patrones y Tecnologías
* **SQLite (sqflite):** Para almacenamiento robusto de notificaciones y logs locales.
* **Google Mobile Ads:** Integración profunda con anuncios recompensados y SSV.
* **SharedPreferences:** Gestión de flags de estado ligero y marcas de tiempo para engagement.
* **Manejo de Overlays:** Uso de `OverlayEntry` y `Dialogs` para control de flujo persistente durante procesos asíncronos.