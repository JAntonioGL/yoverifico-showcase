# YoVerifico - System Architecture & Showcase 

Este repositorio tiene como objetivo documentar la arquitectura técnica, el diseño de infraestructura y la composición modular de **YoVerifico**, una plataforma móvil orientada a la verificación y seguridad. 

> **Nota:** Este repositorio es de carácter público para fines de portafolio y exhibición de arquitectura. El código fuente de la aplicación y el backend se encuentran en repositorios privados.

---

## Arquitectura del Sistema Distribuido

YoVerifico utiliza una arquitectura distribuida para garantizar la separación de responsabilidades, seguridad y escalabilidad.

### Diagrama de Infraestructura
![Arquitectura de YoVerifico](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/arquitectura.png)
*(Sube tu imagen a la carpeta raíz del repo y asegúrate de que el nombre coincida aquí)*

---

## Stack Tecnológico

### Frontend (Mobile)
* **Framework:** Flutter (Android & iOS).
* **Gestión de Estado:** Provider.
* **Arquitectura:** Modular basada en la separación de UI, Lógica y Datos.
    * **Models:** Serialización de datos y tipado fuerte.
    * **Services:** Capa de comunicación con la API REST.
    * **Providers:** Lógica de negocio y reactividad de la interfaz.
    * **Widgets:** Componentización para la reutilización de elementos de UI.

### Backend (API REST)
* **Runtime:** Node.js.
* **Estructura:** Modularizada mediante **Routes** y **Controllers** para un mantenimiento escalable.
* **Caché & Seguridad:** **Redis** implementado para la gestión de estados temporales y **Rate Limiting** (prevención de saturación del sistema).
* **Notificaciones:** Servicio de correos para códigos OTP integrado con **Azure Mail**.

### Infraestructura y DevOps
* **Contenedores:** Docker (Backend contenido para portabilidad).
* **Servidor:** VPS en Neubox (Debian/Ubuntu).
* **Proxy Inverso:** **Nginx** con terminación TLS/SSL (HTTPS) para asegurar la comunicación con la App.
* **Base de Datos:** **PostgreSQL** distribuido y administrado en Railway.
* **Hosting Web:** GitHub Pages (Landing Page promocional).

---

## Decisiones de Ingeniería y Retos

1.  **Seguridad de Datos:** La implementación de Nginx como proxy inverso permite que el backend de Node.js no esté expuesto directamente a Internet, manejando los certificados SSL de forma centralizada.
2.  **Protección contra Abuso:** Se integró Redis como una capa intermedia para limitar el número de peticiones por usuario (Rate Limiting), protegiendo la disponibilidad del servicio.
3.  **Hibridación de Nube:** El uso de una base de datos gestionada (Railway) combinada con un VPS propio (Neubox) permite optimizar costos sin sacrificar la integridad de los datos (ACID compliance).

---

## Sobre el Proyecto
YoVerifico es una solución integral que nació como un proyecto de ingeniería para resolver problemas de verificación de datos. Actualmente cuenta con un sistema de autenticación seguro mediante OTP y una interfaz intuitiva diseñada en Flutter.

---
**Desarrollado por José Antonio Godoy López** *Ingeniero en Computación | Especialista en Desarrollo de Software*