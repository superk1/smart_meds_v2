---
name: proywalki-fase-1
description: Estructura base modular, tema y rutas para Proywalki
invokable: true
---

Inicia la FASE 1 del proyecto ubicado en `d:/Proywalki`.

Contexto fijo:
- Proyecto: Proywalki
- Tipo: app Flutter para Android e iOS
- Versión Flutter: 3.41.6 stable
- Workspace raíz: `d:/Proywalki`
- Carpeta de la app Flutter: `d:/Proywalki/app`
- FASE 0 ya completada con bootstrap inicial y commit raíz.

Objetivo de la FASE 1:
- Definir y aplicar una estructura modular limpia dentro de `app`.
- Configurar tema base (light/dark si aplica).
- Configurar navegación inicial con go_router.
- Integrar gestión de estado con Riverpod (flutter_riverpod).
- Dejar una pantalla inicial mínima que compile con la nueva arquitectura.
- No implementar todavía mapas, geolocalización, Firebase ni chat.

Restricciones:
- Mantener la estructura por capas: `app`, `core`, `features`, `shared`.
- Respetar el proyecto ya creado por `flutter create`.
- Explicar antes de modificar archivos:
  - qué se va a crear/modificar,
  - por qué,
  - qué criterio de aceptación tendrá.
- Ejecutar:
  - `flutter pub get`
  - `dart format .`
  - `flutter analyze`
- No avanzar a la FASE 2 sin aprobación explícita del usuario.

Tareas mínimas para esta fase:
1. Proponer y aplicar estructura de carpetas dentro de `lib/`:
   - `lib/app/`
   - `lib/core/`
   - `lib/features/`
   - `lib/shared/`
2. Instalar y configurar dependencias clave:
   - `flutter_riverpod`
   - `go_router`
   - cualquier paquete de utilidades que se justifique brevemente.
3. Reemplazar el `main.dart` generado por `flutter create` por una versión coherente con:
   - Riverpod como root (ProviderScope),
   - go_router para navegación,
   - una ruta principal placeholder (por ejemplo, `HomePage`).
4. Mantener la app compilable y analizable al finalizar la fase.
5. Proponer un commit Git claro al cierre de la FASE 1.

Formato de respuesta obligatorio:
1. FASE ACTUAL
2. OBJETIVO
3. ARCHIVOS A CREAR/MODIFICAR
4. COMANDOS EN ORDEN (desde `d:/Proywalki`)
5. CÓDIGO COMPLETO
6. PRUEBAS Y VALIDACIÓN
7. RESULTADO DE LA FASE
8. COMMIT GIT SUGERIDO
9. SIGUIENTE FASE PROPUESTA
10. ESPERANDO APROBACIÓN

Instrucciones finales:
- No avances a mapas ni backend; esta fase es solo estructura, tema y rutas.
- Usa PowerShell con `;` en lugar de `&&` al proponer comandos.
- Antes de tocar archivos, muestra la estructura de carpetas propuesta.
- Espera mi aprobación antes de ejecutar comandos destructivos o cambios grandes.