# roles

Catálogo de los roles internos que puede tener un usuario del sistema.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| role_id | SERIAL | NO | auto | Identificador del rol |
| name | VARCHAR(30) | NO | — | Nombre del rol: `root`, `admin`, `coordinator`, `supervisor` o `driver` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de alta |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Business rules

- El Cliente Final no tiene un rol acá — no es un usuario del sistema, no tiene cuenta. Se identifica por el token de seguimiento de su despacho (RF-U14).
- Es un catálogo estructural: el código de la aplicación depende de que estos cinco roles existan tal cual, no es un catálogo administrable por el coordinador vía interfaz (por eso no tiene `deleted_at`).
- **`coordinator`, `supervisor` y `driver`** vienen directo del documento de requerimientos (RF-A01-A11/A39, RF-A12-A20, RF-U01-U13/U23 respectivamente) — son **paralelos entre sí**: ninguno incluye los permisos de otro, cada uno tiene su propio conjunto de endpoints sin superposición.
- **`admin` y `root` no vienen de ningún RF explícito** — son roles de sistema que cualquier backend real necesita, agregados por lógica de buen diseño, no por pedido del documento:
  - **`admin`**: gestión de usuarios (RF-A26-A28), catálogos (RF-A29-A34), configuración/settings (RF-A10, RF-A20, RF-A25), auth/seguridad (RF-A21-A24) y auditoría/logs (RF-A35-A38) — el documento agrupa estas secciones como "Portal web" sin asignarlas explícitamente a coordinador o supervisor (a diferencia de "Autenticación y Seguridad — Ambos", que sí nombra a los dos), lo que sugiere que son funciones de sistema, no de operación diaria. `admin` es **paralelo** a `coordinator`/`supervisor`/`driver` — administra cuentas y configuración, pero no opera como ellos (no asigna despachos, no marca entregas).
  - **`root`**: cuenta semilla del sistema, creada una sola vez, nunca se usa para operar el día a día, nunca se borra. Es el único rol realmente **jerárquico**: tiene acceso a todo, sin excepción — a diferencia del resto, que se autorizan por pertenencia a una lista de roles permitidos por endpoint, `root` se salta ese chequeo por completo.

## Technical notes

- El mecanismo de autorización (`RolesGuard`) no es jerárquico por número (`roleId <= requiredRole`, como trae el scaffold de `create-nestkit` por default) — se compara por **nombre de rol** contra una lista de roles permitidos por endpoint, con un único caso especial: si `role === 'root'`, se permite sin mirar la lista. Ver `delivery-dispatch-svc/.claude/context/decisions.md` para el detalle de esta desviación del patrón original del scaffold.
