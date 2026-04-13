# 🚀 Backend - Node.js API Service (YoVerifico)

Esta carpeta contiene la documentación y especificación técnica del núcleo de servicios de **YoVerifico**. El backend está diseñado bajo una arquitectura de microservicios y contenedores, priorizando la seguridad, la observabilidad y la integridad de los datos en un entorno distribuido de alta disponibilidad.

## 🗺️ Diagrama de Flujo de Petición
El sistema implementa una arquitectura de **Defensa en Profundidad**, donde cada petición atraviesa múltiples capas de validación y seguridad antes de interactuar con la lógica de negocio.

![Flujo de Petición del Backend de YoVerifico](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/arquitectura-backend.png)

---

## 🏗️ Arquitectura y Estructura Modular
El servidor está desarrollado con **Node.js** y **Express**, siguiendo un patrón de diseño desacoplado que separa las responsabilidades en capas claras:

* **`/routes`**: Definición de contratos de la API segmentados por recursos (Auth, Vehículos, Planes, Ads).
* **`/controllers`**: Orquestación de la lógica de negocio y gestión de flujos asíncronos complejos.
* **`/middlewares`**: Capas de interceptación para seguridad (Helmet, CORS), validación de esquemas (express-validator) y gestión de privilegios.
* **`/services`**: Abstracción de integraciones externas como Azure Communication Services para OTP y Firebase Admin SDK para notificaciones push.
* **`/config`**: Centralización de variables de entorno y lógica de arranque bajo el estándar *Twelve-Factor App*.

---

## 🔑 Gestión de Identidad y Sesiones
Se implementó un sistema de autenticación híbrido (Local con Bcrypt + Google OAuth2) con una gestión de sesiones de nivel empresarial:

* **Refresh Token Rotation**: Uso de tokens de acceso de corta duración y tokens de refresco con rotación obligatoria para mitigar el secuestro de sesiones.
* **Absolute Lifetime Control**: Implementación de tiempos de vida absolutos para sesiones persistentes, gestionados mediante lógica procedimental en PostgreSQL para forzar re-autenticación en periodos prolongados.
* **Tickets Stateless (OTP)**: Emisión de JWTs de un solo propósito (audiencia `signup`) para garantizar la integridad del flujo de registro post-verificación sin sobrecargar la persistencia temporal.

---

## 🛡️ Seguridad y Resiliencia
* **Rate Limiting Quirúrgico**: Diferenciación de límites entre endpoints públicos (protección agresiva contra fuerza bruta en OTP/Login) y endpoints privados (cuotas dinámicas por identidad de usuario) mediante **Redis**.
* **Entitlements Injection**: Inyección dinámica de privilegios (Plan, límites de flota, estado de anuncios) desde el middleware de identidad para optimizar el rendimiento y evitar consultas redundantes a la base de datos.
* **Server Side Verification (SSV)**: Validación de recompensas por publicidad mediante webhooks seguros coordinados con Google AdMob, evitando el fraude por manipulación del cliente.
* **Hardening**: Protección de cabeceras vía Helmet, validación estricta de `Host Headers` y manejo de desincronización de relojes (`clockTolerance`) para firmas criptográficas.

---

## 🐳 Containerización y DevOps
El sistema está optimizado para despliegues modernos mediante una infraestructura de contenedores:

* **Docker Multi-stage Builds**: Separación de dependencias de construcción y runtime (basado en **node:20-alpine**) para reducir la superficie de ataque y optimizar el peso de las imágenes.
* **PM2 Cluster Mode**: Gestión de procesos en modo clúster para aprovechar la arquitectura multi-core del servidor y garantizar el *auto-healing* y reinicio automático.
* **Orquestación de Entornos**: Configuración de redes privadas internas para la comunicación con Redis y persistencia de logs con rotación automática (max 30MB) para prevenir el agotamiento de recursos en el host.

---

## 🗄️ Persistencia e Integridad
* **Transacciones ACID**: Uso de transacciones SQL (`BEGIN/COMMIT/ROLLBACK`) en operaciones críticas para asegurar la consistencia atómica de los datos.
* **Lógica en Capa de Datos**: Delegación de reglas de negocio complejas a procedimientos almacenados y vistas indexadas en **PostgreSQL 17**, reduciendo la latencia de red y centralizando la seguridad en la capa de persistencia.

---

> **Tecnologías Clave:** Node.js (v20), Docker, Redis, PM2, PostgreSQL 17, Google OAuth, Azure Communications Service, Firebase Admin SDK.