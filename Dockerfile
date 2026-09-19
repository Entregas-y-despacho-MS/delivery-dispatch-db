# Genera db-output.sql desde schema/ (no confía en una copia commiteada, que podría estar
# desactualizada) y lo deja en docker-entrypoint-initdb.d — Postgres lo ejecuta solo, una
# vez, la primera vez que el contenedor arranca con un volumen de datos vacío. db-output.sql
# ya viene "aplanado" (sin \i relativos) por scripts/build.ts, así que no importa el cwd del
# entrypoint al ejecutarlo.

FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM postgres:18-alpine
COPY --from=build /app/db-output.sql /docker-entrypoint-initdb.d/01-schema.sql
