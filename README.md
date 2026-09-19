# delivery-dispatch-db

Proyecto de base de datos PostgreSQL generado con [create-db](https://www.npmjs.com/package/@darkj/create-db).

## Estructura

- `schema/` — diseño actual: definición de tablas organizadas por dominio
- `migrations/` — historia: cambios incrementales aplicados a bases de datos existentes

## Comandos

| Comando | Hace | Necesita DB |
|---|---|---|
| `npm run build` | Fusiona `schema/` en `db-output.sql` | No |
| `npm run migrate` | Aplica las migraciones pendientes | Sí |
| `npm run rollback [N]` | Revierte las últimas N migraciones (default 1) | Sí |

## Dos flujos

**Base de datos vacía (dev, CI, entorno nuevo)**
```bash
psql -U user -d dbname -f init.sql
```

**Base de datos existente con datos**
```bash
npm run migrate
```

## Cómo empezar

```bash
cp .env.example .env      # completar DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
npm run build              # probar sin necesidad de DB
psql -U user -d dbname -f init.sql   # inicializar una DB nueva
```
