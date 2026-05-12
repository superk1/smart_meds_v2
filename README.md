# Smart Med V2

## Propósito
Aplicación móvil (y potencialmente web/desktop) desarrollada en Flutter para la administración práctica del botiquín del hogar. Permite gestionar medicamentos, mantener un inventario privado y buscar medicamentos por nombre o malestar.

## Estado Actual
**Phase 23** - Navegación reactiva desde notificaciones y base para reprogramación masiva.

## Arquitectura de Datos
El proyecto se divide en cuatro dominios lógicos:
- **Dominio de Identidad:** Gestión de sesión y usuarios (Email/Token).
- **Dominio Privado:** Inventario personal y recordatorios (Sync con Auth + Backup Local).
- **Dominio Global:** Catálogo maestro (Remoto).
- **Dominio de Moderación:** Propuestas al catálogo (Auth requerida).

## Conectividad
- **Auth:** Conectado a backend remoto (Login/Register).
- **Catálogo Global:** Conectado a backend remoto.
- **Inventario Privado:** Syncable con backend (Authorization Bearer). Ahora incluye una red de seguridad local mediante respaldos automáticos previos a la sincronización.
- **Moderación:** Conectado a backend remoto (Authorization Bearer).

Para más detalle, ver [data-architecture.md](docs/data-architecture.md).

## Stack Base
- **Framework:** Flutter
- **Estado:** Riverpod
- **Navegación:** go_router
- **Almacenamiento:** shared_preferences
- **Networking:** http
