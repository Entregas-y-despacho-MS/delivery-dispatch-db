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

## Con Docker

Alternativa a instalar Postgres localmente. El `Dockerfile` genera `db-output.sql` fresco desde
`schema/` y arma una imagen de `postgres:18-alpine` con ese schema listo para cargarse solo la
primera vez que el contenedor arranca con un volumen vacío (vía
`docker-entrypoint-initdb.d/`) — no hace falta correr `psql -f init.sql` a mano.

`.env` necesita las **dos** variantes de credenciales, con el mismo valor real cada una:
`DB_HOST/PORT/NAME/USER/PASSWORD` (para `npm run migrate`/`rollback`, corriendo en el host, no en
Docker) y `POSTGRES_DB/USER/PASSWORD` (los nombres que espera la imagen oficial de postgres).

Si ya tenés un Postgres corriendo en el `5432` del host (nativo, fuera de Docker), hay que bajarlo
primero o publicar la imagen en otro puerto.

**Opción A — como parte del compose de `delivery-dispatch-ms/`** (el directorio padre, junto con
`delivery-dispatch-svc` y `osrm-svc`):
```bash
cd ..   # a delivery-dispatch-ms/
cp delivery-dispatch-db/.env.example delivery-dispatch-db/.env   # completar también POSTGRES_*
docker compose up -d db
```

**Opción B — este repo solo, sin el compose de la raíz** (por ejemplo si lo estás clonando/subiendo
como repo independiente, sin el resto de `delivery-dispatch-ms/`):
```bash
cp .env.example .env   # completar POSTGRES_DB/USER/PASSWORD, las únicas que usa el contenedor
docker build -t delivery-dispatch-db .
docker run -d --name delivery-dispatch-db \
  --env-file .env \
  -p 5432:5432 \
  -v delivery-dispatch-db-data:/var/lib/postgresql \
  delivery-dispatch-db
```
El volumen (`-v`) es opcional pero recomendado — sin él, los datos se pierden si el contenedor se
borra. El mount va en `/var/lib/postgresql` (no `/var/lib/postgresql/data`) por cómo `postgres:18+`
organiza sus datos — ver comentario en el `docker-compose.yml` de la raíz para el detalle.
