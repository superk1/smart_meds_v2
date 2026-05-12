# Arquitectura de Datos - Smart Med V2

Este documento describe las zonas lógicas de datos en la aplicación, garantizando una separación clara entre lo privado, lo global, la identidad y los procesos de moderación (Fase 14).

## 1. Zonas Lógicas de Datos

La aplicación opera bajo cuatro dominios de datos estrictamente separados:

### A. Dominio de Identidad (Auth)
Gestiona la autenticación y la sesión del usuario. Provee la base para las operaciones remotas protegidas.

- **Entidades Clave:** `User`, `AuthSession`.
- **Estado Actual:** Remoto (API Auth para Login/Register). Sesión persistida localmente de forma segura.
- **Uso:** El token de sesión se inyecta en los dominios de Inventario y Moderación para autorizar peticiones.

### B. Dominio Privado (Inventario)
Contiene la información sensible y personal de cada usuario: su botiquín físico.

- **Entidades Clave:** `InventoryItem`.
- **Alcance:** Inventario personal, cantidades y fechas de vencimiento.
- **Estado Actual:** Local persistido (`shared_preferences`) + Sincronización remota manual (protegida con Auth).
- **Estrategia:** Offline-first. El inventario local es la fuente de verdad para el uso diario; el sync remoto es para backup/restauración.

### C. Dominio Global (Catálogo)
Fuente de verdad técnica compartida por todos los usuarios.

- **Entidades Clave:** `CatalogMedication`.
- **Alcance:** Nombres comerciales, sustancias activas y descripciones validadas.
- **Estado Actual:** Remoto (Consumido vía API de solo lectura).

### D. Dominio de Moderación (Admin Review)
Puente entre el Dominio Privado y el Global para la expansión controlada del catálogo.

- **Entidades Clave:** `PendingMedicationSubmission`.
- **Alcance:** Propuestas de nuevos medicamentos detectados durante el Intake.
- **Estado Actual:** Remoto (Envío y revisión protegidos con Auth).
- **Flujo:** Intake -> Propuesta -> Revisión Admin -> Aprobación -> Catálogo Global.

---

## 2. Relaciones y Coherencia

### El Vínculo: `catalogMedicationId`
El punto de unión entre el inventario privado y el catálogo global es el campo `catalogMedicationId`. 
- Si existe un match, el `InventoryItem` referencia al `id` del `CatalogMedication`.
- Si no existe match, se marca como 'desconocido' y se puede iniciar el flujo de moderación.

### Regla de Oro
**Nunca mezclar inventario personal con el catálogo global en la misma entidad.** Un `InventoryItem` *contiene* una referencia al catálogo, pero no *es* un elemento del catálogo.

## 3. Estados de Persistencia

| Dominio | Almacenamiento | Sincronización |
| :--- | :--- | :--- |
| **Identidad** | Local Seguro (Placeholder) | Remoto (API Auth) |
| **Privado** | Local (SharedPreferences) | Syncable (Auth requerida) |
| **Global** | Remoto (Backend Verificable) | Solo lectura (Real) |
| **Moderación** | Remoto (Backend Mínimo) | Escritura / Lectura (Auth requerida) |

## 4. Multi-dispositivo y Conflictos

### Modelo actual
Con el mismo usuario autenticado, el inventario se comparte entre dispositivos a través del backend remoto. La sincronización es **manual y explícita**: el usuario decide cuándo subir o descargar su inventario.

### 4. Estrategia de Sincronización
La aplicación sigue un modelo **"Última escritura gana" (LWW) condicional** basado en el intercambio de la lista completa.

#### Versionado y Conflictos
- **Snapshot:** Cada actualización exitosa en el servidor genera un nuevo snapshot con un número de **versión** incremental.
- **Detección de Conflictos:** Al subir cambios (`PUT`), el cliente debe enviar la `baseVersion` (la versión que descargó por última vez).
- **Bloqueo de Sobrescritura:** Si la `baseVersion` del cliente no coincide con la versión actual en el servidor, el backend rechaza la petición con un error **409 Conflict**. Esto indica que otro dispositivo ha modificado la nube recientemente.
- **Flujo de Resolución Interactiva:** En caso de conflicto, la aplicación entra en un estado de conflicto pendiente y ofrece tres opciones explícitas al usuario:
    1.  **Descargar remoto:** Reemplaza el inventario local con la versión más reciente del servidor (vX).
    2.  **Sobrescribir nube (Forzar):** Ignora el conflicto y obliga al servidor a aceptar el inventario local actual. Se realiza un respaldo local de seguridad antes de esta operación.
    3.  **Cancelar:** Cierra el aviso de conflicto sin realizar cambios, dejando la resolución para después.
- **Consistencia Post-Sync:** Tras cada subida exitosa, el cliente realiza una descarga inmediata de metadata para sincronizar su versión local con la nueva versión generada por el servidor, garantizando que el siguiente `PUT` tenga una `baseVersion` válida.

### Recomendación de uso
- Si el usuario trabaja desde más de un dispositivo, el flujo ideal es: **Descargar** (para obtener cambios remotos) -> **Modificar** -> **Subir** (para consolidar).
- El sistema de detección de conflictos actúa como una red de seguridad para evitar la pérdida silenciosa de datos.

### 4.1 Respaldo local de inventario
Como red de seguridad adicional, la aplicación mantiene un **snapshot local** del inventario.
- **Automatización:** Se genera un respaldo automáticamente antes de cualquier operación destructiva (`syncFromRemote` o `syncToRemote`).
- **Persistencia:** Solo se conserva el último respaldo generado para optimizar el almacenamiento local.
- **Restauración:** Es un proceso manual que permite al usuario revertir el inventario local al estado del último respaldo guardado en caso de una sincronización fallida o indeseada.
